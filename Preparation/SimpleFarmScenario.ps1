# #################################################################################################
# Critical Manufacturing Training Labs
#
# Author: Pedro Salgueiro
# Purpose: Create a simple application server farm and sql server farm for training purposes
#
# #################################################################################################

$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

$labName = 'SimpleFarmLab'
$labPrefix = "SF"
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

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = "$labPrefix$labName"
    'Add-LabMachineDefinition:DomainName' = $domain
    'Add-LabMachineDefinition:MinMemory' = 512MB
    'Add-LabMachineDefinition:Memory' = 512MB
    'Add-LabMachineDefinition:MaxMemory' = 8192MB
    'Add-LabMachineDefinition:OperatingSystem' = $serverImage
}

# domain controller
Add-LabMachineDefinition -Name "$($labPrefix)DC1" -Roles RootDC

# add needed machines
# add a server with a GUI because some things are hard to accomplish in PowerShell
 Add-LabMachineDefinition -Name "$($labPrefix)APPSRV01" -OperatingSystem $guiServerImage 
 Add-LabMachineDefinition -Name "$($labPrefix)APPSRV02"
 Add-LabMachineDefinition -Name "$($labPrefix)APPSRV03"

Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV01" -OperatingSystem $guiServerImage
Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV02"

Add-LabMachineDefinition -Name "$($labPrefix)CLT01" -OperatingSystem $clientImage -MinMemory 1GB -MaxMemory 4GB -Memory 1GB

# After this do 
Install-Lab

Checkpoint-LabVM -All -SnapshotName 'Initial State'