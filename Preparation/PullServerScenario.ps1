# #################################################################################################
# Critical Manufacturing Training Labs
#
# Author: Pedro Salgueiro
# Purpose: Create a application server farm to showcase DSC pull servers
#
# #################################################################################################


$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

$labName = 'PullServerLab'
$labPrefix = "PS"
$addressSpace = '192.168.90.0/24'
$vmFolder = $settings.virtualMachinesFolder
$guiServerImage = $settings.serverWindowsOperatingSystem
$clientImage = $settings.clientWindowsOperatingSystem
$serverImage = $settings.headlessWindowsServerOperatingSystem
$user = $settings.username
$password = $settings.password
$domain = $settings.domain

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
    'Add-LabMachineDefinition:MaxMemory' = 8192MB
    'Add-LabMachineDefinition:OperatingSystem' = $serverImage
}

# domain controller
Add-LabMachineDefinition -Name "$($labPrefix)DC1" -Roles RootDC

# router
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name DRouter -Roles Routing -NetworkAdapter $netAdapter

#CA
Add-LabMachineDefinition -Name CA1 -Roles CaRoot

#DSC Pull Server
$role = Get-LabMachineRoleDefinition -Role DSCPullServer -Properties @{ DatabaseEngine = 'mdb' }
Add-LabMachineDefinition -Name "$($labPrefix)PullSrv" -Roles $role

# add needed machines ( and add a GUI to one of the nodes )
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV01" -OperatingSystem $guiServerImage 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV02"
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV03"

Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV01"
Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV02"

Add-LabMachineDefinition -Name "$($labPrefix)CLT01" -OperatingSystem $clientImage

Install-Lab

Checkpoint-LabVM -All -SnapshotName 'Initial State'


