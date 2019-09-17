# IMPORTANT: You need to dot source this script for it to run properly
$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

# TODO: IIS features
Configuration SQLInstall
{    
    Import-DscResource -ModuleName PSDesiredStateConfiguration    
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -Module xWebAdministration

    node localhost
    {
		WindowsFeature Server {
			Name = "Web-Server"
			Ensure = "Present"
		}	

		WindowsFeature Compression {
			Name = "Web-Dyn-Compression"
			Ensure = "Present"
		}

		WindowsFeature BasicAuth {
			Name = "Web-Basic-Auth"
			Ensure = "Present"
		}		

		WindowsFeature WindowsAuth {
			Name = "Web-Windows-Auth"
			Ensure = "Present"
		}

		WindowsFeature NetExt45 {
			Name = "Web-Net-Ext45"
			Ensure = "Present"
		}

		WindowsFeature AspNet45 {
			Name = "Web-Asp-Net45"
			Ensure = "Present"
		}

		WindowsFeature WebSockets {
			Name = "Web-WebSockets"
			Ensure = "Present"
		}

		WindowsFeature ManagementTools {
			Name = "Web-Mgmt-Tools"
			Ensure = "Present"
		}

		WindowsFeature NetFramework {
			Name = "NET-Framework-45-Core"
			Ensure = "Present"
		}

		WindowsFeature NetFrameworkAspNet {
			Name = "NET-Framework-45-ASPNET"
			Ensure = "Present"
		}

		WindowsFeature WebScriptingTools {
			Name = "Web-Scripting-Tools"
			Ensure = "Present"
		}		

		WindowsFeature WebMgmtService {
			Name = "Web-Mgmt-Service"
			Ensure = "Present"
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

        SqlServerRole Add_sysadmin_to_ods_sql_user
        {
            Ensure               = 'Present'
            ServerRoleName       = 'sysadmin'
            MembersToInclude     = $Node.SQLUserName
            ServerName           = $Node.NodeName
            InstanceName         = 'ODS'
            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerLogin]AddOdsSqlLogin'
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
            DefaultWebSitePath          = "C:\inetpub\wwwroot"
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

$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot
$labPrefix = $labSettings.labPrefix
$labVersion = $labSettings.labVersion

$ComputerNames = @("$($labPrefix)SRV$($labVersion)")

Invoke-LabDscConfiguration -Configuration (Get-Command -Name SQLInstall) -ConfigurationData $ConfigurationData -ComputerName $ComputerNames -Wait

Install-LabSoftwarePackage -ComputerName $ComputerNames -Path "$labSources\ISOs\$($settings.ssmsInstallerFile)" -CommandLine "/install /passive /norestart"
Install-LabSoftwarePackage -ComputerName $ComputerNames -Path "$labSources\ISOs\$($settings.reportingServicesInstallerFile)" -CommandLine "/quiet /norestart /IAcceptLicenseTerms /Edition=Eval"

Restart-LabVM -ComputerName $ComputerNames -Wait
