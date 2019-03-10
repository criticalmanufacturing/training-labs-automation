$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

$ComputerNames = @('SNAPPSRV01','SNAPPSRV02','SNAPPSRV03','SNAPPSRV04','SNAPPSRV05','SNAPPSRV06','SNAPPSRV07','SNAPPSRV08','SNAPPSRV09','SNAPPSRV10','SNAPPSRV11','SNAPPSRV12')

Invoke-LabCommand -ComputerName $computerNames -ActivityName 'Configure Report Server' -ScriptBlock {
    # Retrieve the current configuration
    $configset = Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" `
        -class MSReportServer_ConfigurationSetting -ComputerName localhost

    $configset

    If (! $configset.IsInitialized) {
        # Get the ReportServer and ReportServerTempDB creation script
        [string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script

        # Import the SQL Server PowerShell module
        Import-Module sqlps -DisableNameChecking | Out-Null

        # Establish a connection to the database server (localhost)
        $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList "$env:ComputerName\\ODS"
        $conn.ApplicationName = "SSRS Configuration Script"
        $conn.StatementTimeout = 0
        $conn.Connect()
        $smo = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $conn

        # Create the ReportServer and ReportServerTempDB databases
        $db = $smo.Databases["master"]
        $db.ExecuteNonQuery($dbscript)

        # Set permissions for the databases
        $dbscript = $configset.GenerateDatabaseRightsScript($configset.WindowsServiceIdentityConfigured, "ReportServer", $false, $true).Script
        $db.ExecuteNonQuery($dbscript)

        # Set the database connection info
        $configset.SetDatabaseConnection("(local)", "ReportServer", 2, "", "")

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

        # Update the current configuration
        $configset = Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" `
            -class MSReportServer_ConfigurationSetting -ComputerName localhost

        # Output to screen
        $configset.IsReportManagerEnabled
        $configset.IsInitialized
        $configset.IsWebServiceEnabled
        $configset.IsWindowsServiceEnabled
        $configset.ListReportServersInDatabase()
        $configset.ListReservedUrls();

        $inst = Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14" `
            -class MSReportServer_Instance -ComputerName localhost

        $inst.GetReportServerUrls()
    }
}
