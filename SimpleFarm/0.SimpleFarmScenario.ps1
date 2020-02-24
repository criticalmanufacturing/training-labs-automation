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
$addressSpace = $labSettings.addressSpace

$vmFolder = $settings.virtualMachinesFolder
$guiServerImage = $settings.serverWindowsOperatingSystem
$serverImage = $settings.headlessWindowsServerOperatingSystem
$user = $settings.username
$password = $settings.password
$domain = $settings.domain
$numberOfLabMachines = $labSettings.numberOfLabMachines
$startingMachineNumber = $labSettings.startingMachineNumber
$numberOfFarms = $labSettings.numberOfFarms

# derive the network addresses based on the subnet
$range = $addressSpace.Split('/')[0]
$base = Convert-NetworkAddressToLong $range
$dcIpNumber = $base + 3
$dcIpAddress = Convert-LongToNetworkAddress $dcIpNumber

######################################################
# setup lab and domain
######################################################

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -VmPath $vmFolder -ReferenceDiskSizeInGB 40
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
    'Add-LabMachineDefinition:Memory' = 3GB
    'Add-LabMachineDefinition:OperatingSystem' = $guiServerImage
    'Add-LabMachineDefinition:IsDomainJoined'= $true
    'Add-LabMachineDefinition:DnsServer1'= "$dcIpAddress"
}



######################################################
# domain controller
######################################################
Add-LabMachineDefinition -Name "$($labPrefix)DC" -Roles RootDC -IpAddress $dcIpAddress -Network $adapterName
######################################################
# add needed machines
######################################################

# add the  sqlserver


For ($j=1; $j -le $numberOfFarms; $j++) {
    $farmLetter = [char](64 + $j);

    $ipNumber = $base + $j * 10
    $ipAddress = Convert-LongToNetworkAddress $ipNumber
    $netAdapter = @()
    $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch "$adapterName" -Ipv4Address $ipAddress
    $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp

    Add-LabMachineDefinition -Name "$($labPrefix)$($farmLetter)SQL01" -MinMemory 1GB -MaxMemory 4GB -NetworkAdapter $netAdapter

    $ipNumber = $ipNumber + 1
    $netAdapter = @()
    $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch "$adapterName" -Ipv4Address $ipAddress
    $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp

    Add-LabMachineDefinition -Name "$($labPrefix)$($farmLetter)SQL02" -MinMemory 1GB -MaxMemory 4GB -NetworkAdapter $netAdapter 


    # add the app servers

    For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
        $machineName = "$($labPrefix)$($farmLetter)SRV$($i.ToString('00'))"
        $ipNumber = $base + ($j * 10) + $i
        $ipAddress = Convert-LongToNetworkAddress $ipNumber
        $netAdapter = @()
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch "$adapterName" -Ipv4Address $ipAddress
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
        Write-Host "Adding machine $machineName with ip $ipAddress"

        Add-LabMachineDefinition -Name $machineName -MinMemory 1GB -MaxMemory 4GB -NetworkAdapter $netAdapter
    }

    # Execute it

}


Install-Lab
Checkpoint-LabVM -All -SnapshotName 'Initial State'


