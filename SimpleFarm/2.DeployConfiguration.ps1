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

        SqlSetup 'ProdInstance' {
            InstanceName          = 'PROD'
            Features              = 'SQLENGINE,AS'
            SourcePath            = 'C:\SQL2017'
            SQLSysAdminAccounts   = @('Administrators')
            ASSysAdminAccounts    = @('Administrators')

            InstallSQLDataDir     = 'C:\STORAGE\PROD\MSSQL2017\Data'
            SQLUserDBDir          = 'C:\STORAGE\PROD\MSSQL2017\Data'
            SQLUserDBLogDir       = 'C:\STORAGE\PROD\MSSQL2017\Data'
            SQLTempDBDir          = 'C:\STORAGE\PROD\MSSQL2017\Data'
            SQLTempDBLogDir       = 'C:\STORAGE\PROD\MSSQL2017\Data'
            SQLBackupDir          = 'C:\STORAGE\PROD\MSSQL2017\Backup'
            ASConfigDir           = 'C:\STORAGE\ODS\AS2017\Config'
            ASDataDir             = 'C:\STORAGE\ODS\AS2017\Data'
            ASLogDir              = 'C:\STORAGE\ODS\AS2017\Log'
            ASBackupDir           = 'C:\STORAGE\ODS\AS2017\Backup'
            ASTempDir             = 'C:\STORAGE\ODS\AS2017\Temp'

            SQLSvcAccount         = $Node.SqlServiceCredential
            AgtSvcAccount         = $Node.SqlServiceCredential
            ASSvcAccount          = $Node.SqlServiceCredential

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
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'cmflab\administrator', $password 
$saCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'sa', $password 

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
        }
    )
    PSDscAllowPlainTextPassword = $True
    PSDscAllowDomainUser        = $true      
}

# for simplicity we deploy the same config to all servers even thought they might be headless
$sqlServers = @("SFSQLSRV01", "SFSQLSRV02")
foreach ($sqlServer in $sqlServers) {
    Invoke-LabDscConfiguration -Configuration (Get-Command -Name SQLInstall) `
        -ConfigurationData $ConfigurationData -ComputerName $sqlServer
}