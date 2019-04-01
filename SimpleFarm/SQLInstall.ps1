Configuration SQLInstall
{    
    Import-DscResource -ModuleName PSDesiredStateConfiguration    
    Import-DscResource -ModuleName SqlServerDsc

    node $AllNodes.NodeName
    {
        WindowsFeature 'NetFramework45' {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'ProdInstance' {
            InstanceName          = $Node.SQLInstanceName
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
        
        SqlServerLogin AddSqlLogin
        {
            Ensure                         = 'Present'
            Name                           = $Node.SQLUserName
            LoginType                      = 'SqlLogin'
            ServerName                     = $Node.NodeName
            InstanceName                   = $Node.SQLInstanceName
            LoginCredential                = $Node.SQLUserCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $false
            LoginPasswordPolicyEnforced    = $false
            PsDscRunAsCredential           = $SqlServiceCredential

            DependsOn                      = '[SqlSetup]ProdInstance'
        }

        SqlServerLogin AddNTServiceClusSvc
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SQLInstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerLogin]AddSqlLogin'
        }

        # Add the required permissions to the cluster service login
        SqlServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SQLInstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Create a DatabaseMirroring endpoint
        SqlServerEndpoint HADREndpoint
        {
            EndPointName         = 'HADR'
            Ensure               = 'Present'
            Port                 = 5022
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SQLInstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc', '[SqlAlwaysOnService]EnableAlwaysOn'
        }

        SqlAlwaysOnService EnableAlwaysOn
        {
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SQLInstanceName
            RestartTimeout       = 120

            PsDscRunAsCredential = $SqlAdministratorCredential
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
        
        if ( $Node.Role -eq 'PrimaryReplica' ) {
            # Create the availability group on the instance tagged as the primary replica
            SqlAG AddOnlineAG {
                Ensure               = 'Present'
                Name                 = $Node.OnlineAvailabilityGroupName
                InstanceName         = $Node.SQLInstanceName
                ServerName           = $Node.NodeName
                DependsOn            = '[SqlAlwaysOnService]EnableAlwaysOn', '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SqlAdministratorCredential
            }

            SqlAG AddOdsAG {
                Ensure               = 'Present'
                Name                 = $Node.OdsAvailabilityGroupName
                InstanceName         = $Node.SQLInstanceName
                ServerName           = $Node.NodeName
                DependsOn            = '[SqlAlwaysOnService]EnableAlwaysOn', '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SqlAdministratorCredential
            }

            SqlAG AddDwhAG {
                Ensure               = 'Present'
                Name                 = $Node.DwhAvailabilityGroupName
                InstanceName         = $Node.SQLInstanceName
                ServerName           = $Node.NodeName
                DependsOn            = '[SqlAlwaysOnService]EnableAlwaysOn', '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SqlAdministratorCredential
            }
        }

        if ( $Node.Role -eq 'SecondaryReplica' ) {
            # Add the availability group replica to the availability group
            SqlAGReplica AddOnlineReplica {
                Ensure                     = 'Present'
                Name                       = $Node.OnlineAvailabilityGroupName
                AvailabilityGroupName      = $Node.OnlineAvailabilityGroupName
                ServerName                 = $Node.NodeName
                InstanceName               = $Node.SQLInstanceName
                PrimaryReplicaServerName   = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).NodeName
                PrimaryReplicaInstanceName = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).SQLInstanceName
                DependsOn                  = '[SqlAlwaysOnService]EnableAlwaysOn'
                ProcessOnlyOnActiveNode    = $Node.ProcessOnlyOnActiveNode
                PsDscRunAsCredential       = $SqlAdministratorCredential
            }

            SqlAGReplica AddOdsReplica {
                Ensure                     = 'Present'
                Name                       = $Node.OdsAvailabilityGroupName
                AvailabilityGroupName      = $Node.OdsAvailabilityGroupName
                ServerName                 = $Node.NodeName
                InstanceName               = $Node.SQLInstanceName
                PrimaryReplicaServerName   = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).NodeName
                PrimaryReplicaInstanceName = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).SQLInstanceName
                DependsOn                  = '[SqlAlwaysOnService]EnableAlwaysOn'
                ProcessOnlyOnActiveNode    = $Node.ProcessOnlyOnActiveNode
                PsDscRunAsCredential       = $SqlAdministratorCredential
            }

            SqlAGReplica AddDwbReplica {
                Ensure                     = 'Present'
                Name                       = $Node.DwhAvailabilityGroupName
                AvailabilityGroupName      = $Node.DwhAvailabilityGroupName
                ServerName                 = $Node.NodeName
                InstanceName               = $Node.SQLInstanceName
                PrimaryReplicaServerName   = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).NodeName
                PrimaryReplicaInstanceName = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).SQLInstanceName
                DependsOn                  = '[SqlAlwaysOnService]EnableAlwaysOn'
                ProcessOnlyOnActiveNode    = $Node.ProcessOnlyOnActiveNode
                PsDscRunAsCredential       = $SqlAdministratorCredential
            }
        }
    }
}