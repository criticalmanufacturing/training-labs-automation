# IMPORTANT: You need to dot source this script for it to run properly
$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

Configuration SQLInstall
{    
    Import-DscResource -ModuleName PSDesiredStateConfiguration    
    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        WindowsFeature 'NetFramework45' {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'OnlineInstance' {
            InstanceName          = 'ONLINE'
            Features              = 'SQLENGINE,AS'
            SourcePath            = 'C:\SQL2017'
            SQLSysAdminAccounts   = @('Administrators')
            ASSysAdminAccounts    = @('Administrators')	

            InstallSQLDataDir     = 'C:\STORAGE\ONLINE\MSSQL2017\Data'
            SQLUserDBDir          = 'C:\STORAGE\ONLINE\MSSQL2017\Data'
            SQLUserDBLogDir       = 'C:\STORAGE\ONLINE\MSSQL2017\Data'
            SQLTempDBDir          = 'C:\STORAGE\ONLINE\MSSQL2017\Data'
            SQLTempDBLogDir       = 'C:\STORAGE\ONLINE\MSSQL2017\Data'
            SQLBackupDir          = 'C:\STORAGE\ONLINE\MSSQL2017\Backup'               

            SQLSvcAccount         = $Node.adminCredential
            AgtSvcAccount         = $Node.adminCredential
            ASSvcAccount          = $Node.adminCredential

            SecurityMode          = 'SQL'
            SAPwd                 = $Node.SAPassword

            SqlSvcStartupType     = 'Automatic'
            AgtSvcStartupType     = 'Automatic'
            AsSvcStartupType      = 'Automatic'
            BrowserSvcStartupType = 'Automatic'

            SQLCollation          = 'Latin1_General_CI_AS'

            UpdateEnabled         = $false
            ASServerMode          = 'MULTIDIMENSIONAL'

            DependsOn             = '[WindowsFeature]NetFramework45'
        }

        SqlServerLogin AddOnlineSqlLogin {
            Ensure                         = 'Present'
            Name                           = $Node.SQLUserName
            LoginType                      = 'SqlLogin'
            ServerName                     = $Node.NodeName
            InstanceName                   = "Online"
            LoginCredential                = $Node.SQLUserCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $false
            LoginPasswordPolicyEnforced    = $false
            PsDscRunAsCredential           = $Node.SqlServiceCredential

            DependsOn                      = '[SqlSetup]OnlineInstance'
        }

        SqlServerRole Add_sysadmin_to_online_sql_user
        {
            Ensure               = 'Present'
            ServerRoleName       = 'sysadmin'
            MembersToInclude     = $Node.SQLUserName
            ServerName           = $Node.NodeName
            InstanceName         = 'Online'
            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerLogin]AddOnlineSqlLogin'
        }
    }
}

$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$password = $settings.password | ConvertTo-SecureString  -AsPlainText -Force
$sqlPassword = $settings.sqlPassword | ConvertTo-SecureString  -AsPlainText -Force
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($settings.shortDomain)\$($settings.username)", $password 
$saCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'sa', $password 
$sqlUserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $settings.sqlUser, $sqlPassword
$startingMachineNumber = $labSettings.startingMachineNumber
$numberOfLabMachines = $labSettings.numberOfLabMachines

$ConfigurationData = @{
    AllNodes                    = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true  
            SqlServiceCredential        = $adminCredential
            SAPassword                  = $saCredential            
            SQLUserName                 = $settings.sqlUser
            SQLUserCredential           = $sqlUserCredential                 
        }
    )
    PSDscAllowPlainTextPassword = $True
    PSDscAllowDomainUser        = $true      
}

$ComputerNames = @()
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot
if ($startingMachineNumber -eq 1) {

    $ComputerNames = @("$($labSettings.labPrefix)SQL")

    Invoke-LabDscConfiguration -Configuration (Get-Command -Name SQLInstall) -ConfigurationData $ConfigurationData -ComputerName $ComputerNames -Wait
    Install-LabSoftwarePackage -ComputerName $ComputerNames -Path "$labSources\ISOs\$($settings.reportingServicesInstallerFile)" -CommandLine "/quiet /norestart /IAcceptLicenseTerms /Edition=Eval"
}

# Add app servers to include management studio

For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $ComputerNames += $machineName
}

Install-LabSoftwarePackage -ComputerName $ComputerNames -Path "$labSources\ISOs\$($settings.ssmsInstallerFile)" -CommandLine "/install /passive /norestart"

Restart-LabVM -ComputerName $ComputerNames -Wait
