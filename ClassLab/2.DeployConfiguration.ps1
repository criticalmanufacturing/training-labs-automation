# IMPORTANT: You need to dot source this script for it to run properly

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
            Features              = 'SQLENGINE'
            SourcePath            = 'C:\SQL2017'
            SQLSysAdminAccounts   = @('Administrators')

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

            DependsOn             = '[WindowsFeature]NetFramework45'
        }

        SqlSetup 'OdsInstance' {
            InstanceName          = 'ODS'
            Features              = 'SQLENGINE,AS'
            SourcePath            = 'C:\SQL2017'
            SQLSysAdminAccounts   = @('Administrators')
            ASSysAdminAccounts    = @('Administrators')

            InstallSQLDataDir     = 'C:\STORAGE\ODS\MSSQL2017\Data'
            SQLUserDBDir          = 'C:\STORAGE\ODS\MSSQL2017\Data'
            SQLUserDBLogDir       = 'C:\STORAGE\ODS\MSSQL2017\Data'
            SQLTempDBDir          = 'C:\STORAGE\ODS\MSSQL2017\Data'
            SQLTempDBLogDir       = 'C:\STORAGE\ODS\MSSQL2017\Data'
            SQLBackupDir          = 'C:\STORAGE\ODS\MSSQL2017\Backup'
            ASConfigDir           = 'C:\STORAGE\ODS\AS2017\Config'
            ASDataDir             = 'C:\STORAGE\ODS\AS2017\Data'
            ASLogDir              = 'C:\STORAGE\ODS\AS2017\Log'
            ASBackupDir           = 'C:\STORAGE\ODS\AS2017\Backup'
            ASTempDir             = 'C:\STORAGE\ODS\AS2017\Temp'

            SQLSvcAccount         = $Node.adminCredential
            AgtSvcAccount         = $Node.adminCredential
            ASSvcAccount          = $Node.adminCredential

            SecurityMode          = 'SQL'
            SAPwd                 = $Node.SAPassword

            SqlSvcStartupType     = 'Automatic'
            AgtSvcStartupType     = 'Automatic'
            AsSvcStartupType      = 'Automatic'
            BrowserSvcStartupType = 'Automatic'
               
            UpdateEnabled         = $false
            ASServerMode          = 'MULTIDIMENSIONAL'

            SQLCollation          = 'Latin1_General_CI_AS'

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

        SqlServerLogin AddOdsSqlLogin {
            Ensure                         = 'Present'
            Name                           = $Node.SQLUserName
            LoginType                      = 'SqlLogin'
            ServerName                     = $Node.NodeName
            InstanceName                   = "ODS"
            LoginCredential                = $Node.SQLUserCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $false
            LoginPasswordPolicyEnforced    = $false
            PsDscRunAsCredential           = $Node.SqlServiceCredential

            DependsOn                      = '[SqlSetup]OdsInstance'
        }

        Package SSMS {
            Ensure    = 'Present'
            Name      = 'SSMS-Setup-ENU'
            Path      = "c:\temp\$($node.SSMSInstallerFile)"
            Arguments = '/install /passive /norestart'
            ProductId = '00BE2F31-85B3-414F-8BAD-01E24FB17541'
        }

        Package RS {
            Ensure    = 'Present'
            Name      = 'SQLServerReportingServices'
            Path      = "c:\temp\$($node.RSInstallerFile)"
            Arguments = '/quiet /norestart /IAcceptLicenseTerms /Edition=Eval'
            ProductId = 'FC32DB66-DA3A-4521-A6F3-B75491663793'
        }
    }
}

$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$password = $settings.password | ConvertTo-SecureString  -AsPlainText -Force
$sqlPassword = $settings.sqlPassword | ConvertTo-SecureString  -AsPlainText -Force
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($settings.shortDomain)\$($settings.username)", $password 
$saCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'sa', $password 
$sqlUserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $settings.sqlUser, $sqlPassword


$ConfigurationData = @{
    AllNodes                    = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true  
            SqlServiceCredential        = $adminCredential
            SAPassword                  = $saCredential
            SSMSInstallerFile           = $settings.ssmsInstallerFile
            RSInstallerFile             = $settings.reportingServicesInstallerFile
            SQLUserName                 = $settings.sqlUser
            SQLUserCredential           = $sqlUserCredential           
        }
    )
    PSDscAllowPlainTextPassword = $True
    PSDscAllowDomainUser        = $true      
}

$labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.user.json'
if (-Not (Test-Path -Path $labSettingsPath)) {
    $labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.default.json'
}

$labSettings = (Get-Content $labSettingsPath ) | ConvertFrom-Json

$ComputerNames = @("$($labSettings.labPrefix)SQLSRV01")

Invoke-LabDscConfiguration -Configuration (Get-Command -Name SQLInstall) -ConfigurationData $ConfigurationData -ComputerName $ComputerNames

Restart-Computer -ComputerName $ComputerNames