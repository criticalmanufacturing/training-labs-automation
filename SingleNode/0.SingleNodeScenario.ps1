# #################################################################################################
# Critical Manufacturing Training Labs
#
# Author: Pedro Salgueiro
# Purpose: Create a server node and a separate domain controller for training purpose
#
# #################################################################################################


$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

$labName = 'SingleNodeLab'
$labPrefix = "SN"
$addressSpace = '192.168.80.0/24'
$vmFolder = $settings.virtualMachinesFolder
$guiServerImage = $settings.serverWindowsOperatingSystem
$serverImage = $settings.headlessWindowsServerOperatingSystem
$user = $settings.username
$password = $settings.password
$domain = $settings.domain

######################################################
# setup lab and domain
######################################################

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -VmPath $vmFolder
Set-LabInstallationCredential -Username $user -Password $password
Add-LabDomainDefinition -Name $domain -AdminUser $user -AdminPassword $password

######################################################
# setup networking
######################################################
Add-LabVirtualNetworkDefinition -Name "$labPrefix$labName" -AddressSpace $addressSpace # -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

######################################################
#defining default parameter values, as these ones are the same for all the machines
######################################################

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = "$labPrefix$labName"
    'Add-LabMachineDefinition:DomainName' = $domain
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = $guiServerImage
    'Add-LabMachineDefinition:IsDomainJoined'= $true
    'Add-LabMachineDefinition:DnsServer1'= '192.168.80.3'
}

######################################################
# domain controller
######################################################

######################################################
# add network
######################################################
Add-LabMachineDefinition -Name "$($labPrefix)DC1" -Roles RootDC -IpAddress 192.168.80.3

######################################################
# add needed machines
######################################################

# add a server with a GUI because some things are hard to accomplish in PowerShell
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV01" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.4
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV02" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.5
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV03" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.6 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV04" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.7 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV05" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.8 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV06" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.9 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV07" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.10 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV08" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.11 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV09" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.12 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV10" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.13 
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV11" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.14
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV12" -MinMemory 1GB -MaxMemory 4GB -IpAddress 192.168.80.15

# Execute it
Install-Lab

Checkpoint-LabVM -All -SnapshotName 'Initial State'