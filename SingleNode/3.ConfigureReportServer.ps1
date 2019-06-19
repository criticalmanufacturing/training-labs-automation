$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot

$ComputerNames = @("$($labSettings.labPrefix)APPSRV01")

Invoke-LabCommand -ComputerName $computerNames -ActivityName 'Configure Report Server' -ArgumentList $settings.sqlUser, $settings.sqlPassword -ScriptBlock {
    param([string]$sqlUser, [string]$sqlPassword)    
    
    # Retrieve the current configuration
    $configset = Get-WmiObject -namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" -class MSReportServer_ConfigurationSetting -ComputerName localhost
    
    # while the computer is starting up it may take a while before this object is available
    # adding some resiliency by doing busy waiting
    # could be improved by using exponential wait times and limit the number of retries
    # but for the moment these scripts are not run fully unattended, so someone will be looking at the 
    # output and notice there is problem
    While(!$configset) {
        Write-Verbose "Could not obtain the WMI object for SSRS, retrying in 5 seconds" -Verbose
        Start-Sleep -Seconds 5
        $configset = Get-WmiObject -namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" -class MSReportServer_ConfigurationSetting -ComputerName localhost -ErrorAction SilentlyContinue
    }

    If (! $configset.IsInitialized) {
        # Get the ReportServer and ReportServerTempDB creation script
        [string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script

        # Import the SQL Server PowerShell module
        Import-Module sqlps -DisableNameChecking | Out-Null

        # Establish a connection to the database server (localhost)
        $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList "$env:ComputerName\ODS"
        $conn.ApplicationName = "SSRS Configuration Script"
        $conn.StatementTimeout = 0
        $conn.LoginSecure = $false
        $conn.Login = $sqlUser
        $conn.Password = $sqlPassword
        $conn.Connect()
        $smo = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $conn

        # Create the ReportServer and ReportServerTempDB databases
        $db = $smo.Databases["master"]
        $db.ExecuteNonQuery($dbscript)

        # Set permissions for the databases
        $dbscript = $configset.GenerateDatabaseRightsScript($configset.WindowsServiceIdentityConfigured, "ReportServer", $false, $true).Script
        $db.ExecuteNonQuery($dbscript)

        # Set the database connection info

        # 1 - Means SQL Server Credentials
        $configset.SetDatabaseConnection("$env:ComputerName\ODS", "ReportServer", 1, $sqlUser, $sqlPassword)

        $configset.SetVirtualDirectory("ReportServerWebService", "ReportServer", 1033)
        $configset.ReserveURL("ReportServerWebService", "http://+:80", 1033)

        # For SSRS 2016-2017 only, older versions have a different name
        $configset.SetVirtualDirectory("ReportServerWebApp", "Reports", 1033)
        $configset.ReserveURL("ReportServerWebApp", "http://+:80", 1033)

        $configset.InitializeReportServer($configset.InstallationID)

        # Re-start services?
        $configset.SetServiceState($false, $false, $false)
        Restart-Service $configset.ServiceName
        $configset.SetServiceState($true, $true, $true)        
    }
}
