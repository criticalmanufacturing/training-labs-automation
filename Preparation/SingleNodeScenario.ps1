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
Add-LabVirtualNetworkDefinition  -Name "$labPrefix$labName"  -AddressSpace $addressSpace

######################################################
#defining default parameter values, as these ones are the same for all the machines
######################################################

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = "$labPrefix$labName"
    'Add-LabMachineDefinition:DomainName' = $domain
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = $serverImage
}

######################################################
# domain controller
######################################################

Add-LabMachineDefinition -Name "$($labPrefix)DC1" -Roles RootDC

######################################################
# add needed machines
######################################################

# add a server with a GUI because some things are hard to accomplish in PowerShell
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV01" -OperatingSystem $guiServerImage -MinMemory 1GB -MaxMemory 8GB

# Execute it
Install-Lab

Checkpoint-LabVM -All -SnapshotName 'Initial State'