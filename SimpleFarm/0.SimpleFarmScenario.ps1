# #################################################################################################
# Critical Manufacturing Training Labs
#
# Author: Pedro Salgueiro
# Purpose: Create a simple application server farm and sql server farm for training purposes
#
# #################################################################################################

$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$labConfigRoot = $PSScriptRoot

$settings = (Get-Content (Join-Path -Path $labConfigRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $labConfigRoot

$labName = $labSettings.labName
$labPrefix = $labSettings.labPrefix
$addressSpace = $labSettings.addressSpace

$vmFolder = $settings.virtualMachinesFolder
$guiServerImage = $settings.serverWindowsOperatingSystem
$user = $settings.username
$password = $settings.password
$domain = $settings.domain

# derive the network addresses based on the subnet
$range = $addressSpace.Split('/')[0]
$base = Convert-NetworkAddressToLong $range
$dcIpNumber = $base + 3
$dcIpAddress = Convert-LongToNetworkAddress $dcIpNumber

# setup lab and domain
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -VmPath $vmFolder
Set-LabInstallationCredential -Username $user -Password $password
Add-LabDomainDefinition -Name $domain -AdminUser $user -AdminPassword $password

# setup networking
Add-LabVirtualNetworkDefinition -Name "$labPrefix$labName" -AddressSpace $addressSpace
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = "$labPrefix$labName"
    'Add-LabMachineDefinition:DomainName' = $domain
    'Add-LabMachineDefinition:MinMemory' = 512MB
    'Add-LabMachineDefinition:Memory' = 512MB
    'Add-LabMachineDefinition:MaxMemory' = 8192MB
    'Add-LabMachineDefinition:OperatingSystem' = $guiServerImage
}

# domain controller
Add-LabMachineDefinition -Name "$($labPrefix)DC1" -Roles RootDC -IpAddress $dcIpAddress

# add a router so that the machines can connect to the internet
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch "$labPrefix$labName"
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name "$($labPrefix)ROUTER" -Roles Routing  -NetworkAdapter $netAdapter

# start by the sql server machines

$ipNumber = $base + 10
$ipAddress = Convert-LongToNetworkAddress $ipNumber

$sqlCluster = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'SQLCLT'; ClusterIp = '192.168.90.120' }
Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV01" -Roles $sqlCluster -IpAddress $ipAddress

$ipNumber = $ipNumber + 1
$ipAddress = Convert-LongToNetworkAddress $ipNumber
Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV02" -Roles $sqlCluster -IpAddress $ipAddress

# then add the app servers

$appSrvCluster = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'APPSRVCLT'; ClusterIp = '192.168.90.160' }

For ($i=1; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)APPSRV$($i.ToString('00'))"
    $ipNumber = $ipNumber + 1
    $ipAddress = Convert-LongToNetworkAddress $ipNumber

    Write-Host "Adding machine $machineName with ip $ipAddress"

    Add-LabMachineDefinition -Name $machineName  -MinMemory 1GB -MaxMemory 4GB -IpAddress $ipAddress -Roles $appSrvCluster, WebServer
}

Install-Lab

Checkpoint-LabVM -All -SnapshotName 'Initial State'