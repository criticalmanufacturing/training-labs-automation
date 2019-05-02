# IMPORTANT: You need to dot source this script for it to run properly

. .\SQLInstall.ps1

$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$password = $settings.password | ConvertTo-SecureString  -AsPlainText -Force
$sqlPassword = $settings.sqlPassword | ConvertTo-SecureString  -AsPlainText -Force
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($settings.shortDomain)\$($settings.username)", $password 
$saCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'sa', $password 
$sqlUserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $settings.sqlUser, $sqlPassword

$ConfigurationData = @{
    AllNodes                    = @(
        @{
            NodeName                    = '*'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true  
            SqlServiceCredential        = $adminCredential
            SAPassword                  = $saCredential
            SSMSInstallerFile           = $settings.ssmsInstallerFile
            RSInstallerFile             = $settings.reportingServicesInstallerFile
            SQLInstanceName             = 'PROD'
            SQLUserName                 = $settings.sqlUser
            SQLUserCredential           = $sqlUserCredential
            OnlineAvailabilityGroupName = "AGONLINE"
            OdsAvailabilityGroupName    = "AGODS"
            DwhAvailabilityGroupName    = "AGDWH"
        },
        @{
            NodeName = 'SFSQLSRV01'
            Role     = 'PrimaryReplica'
        },
        @{
            NodeName = 'SFSQLSRV02'
            Role     = 'SecondaryReplica'
        }
    )
    PSDscAllowPlainTextPassword = $True
    PSDscAllowDomainUser        = $true      
}

# for simplicity we deploy the same config to all servers even thought they might be headless
$sqlServers = @("SFSQLSRV01", "SFSQLSRV02")
Invoke-LabDscConfiguration -Configuration (Get-Command -Name SQLInstall) `
    -ConfigurationData $ConfigurationData -ComputerName $sqlServers


# Checkpoint-LabVM -All -SnapshotName 'After SQL Deploy'