# Saving for future reference because:
# - Adding the secondary replicas requires adding the secondary node login 
# - When creating the replica it fails due to a bug on the powershell module included with SQL Server 2017
# - Updating the module requires access to the internet or more scripting to update it manually


Configuration AvailabilityGroups
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration    
    Import-DscResource -ModuleName SqlServerDsc

    node $AllNodes.NodeName
    {
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
