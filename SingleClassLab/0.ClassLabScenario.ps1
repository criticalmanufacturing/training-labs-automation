# #################################################################################################
# Critical Manufacturing Training Labs
#
# Author: Pedro Salgueiro
# Purpose: Create a server node and a separate domain controller for training purpose
#
# #################################################################################################

$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$labConfigRoot = $PSScriptRoot

$settings = (Get-Content (Join-Path -Path $labConfigRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $labConfigRoot

$labName = $labSettings.labName
$labPrefix = $labSettings.labPrefix
$labVersion = $labSettings.labVersion
$addressSpace = $labSettings.addressSpace

$vmFolder = $settings.virtualMachinesFolder
$guiServerImage = $settings.serverWindowsOperatingSystem
$serverImage = $settings.headlessWindowsServerOperatingSystem
$user = $settings.username
$password = $settings.password
$domain = $settings.domain

# derive the network addresses based on the subnet
$range = $addressSpace.Split('/')[0]
$base = Convert-NetworkAddressToLong $range
$dcIpNumber = $base + 3
$dcIpAddress = Convert-LongToNetworkAddress $dcIpNumber

######################################################
# setup lab and domain
######################################################

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -VmPath $vmFolder
Set-LabInstallationCredential -Username $user -Password $password
Add-LabDomainDefinition -Name $domain -AdminUser $user -AdminPassword $password

######################################################
# setup networking
######################################################
$adapterName="$labPrefix$labName"
Add-LabVirtualNetworkDefinition -Name "$adapterName" -AddressSpace $addressSpace # -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = "$($adapterName)Internet" }

######################################################
#defining default parameter values, as these ones are the same for all the machines
######################################################

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = $domain
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = $guiServerImage
    'Add-LabMachineDefinition:IsDomainJoined'= $true
    'Add-LabMachineDefinition:DnsServer1'= "$dcIpAddress"
}



######################################################
# domain controller
######################################################

Add-LabMachineDefinition -Name "$($labPrefix)DC1" -Roles RootDC -IpAddress $dcIpAddress -Network $adapterName

######################################################
# add needed machines
######################################################

# add the  sqlserver

$ipNumber = $base + 10
$ipAddress = Convert-LongToNetworkAddress $ipNumber
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch "$adapterName" -Ipv4Address $ipAddress
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name "$($labPrefix)SRV$($labVersion)" -MinMemory 1GB -MaxMemory 32GB -NetworkAdapter $netAdapter

# Execute it

Install-Lab
Checkpoint-LabVM -All -SnapshotName 'Initial State'