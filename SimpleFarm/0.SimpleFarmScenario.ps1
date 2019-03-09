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
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

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
Add-LabMachineDefinition -Name "$($labPrefix)CA1" -Roles CaRoot

# add network
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch "$labPrefix$labName"
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name "$($labPrefix)ROUTER" -Roles Routing  -NetworkAdapter $netAdapter

# add needed machines

$appSrvCluster = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'APPSRVCLT'; ClusterIp = '192.168.90.60' }

# add a server with a GUI because some things are hard to accomplish in PowerShell
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV01" -OperatingSystem $guiServerImage -Roles $appSrvCluster, WebServer
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV02" -Roles $appSrvCluster, WebServer
Add-LabMachineDefinition -Name "$($labPrefix)APPSRV03" -Roles $appSrvCluster, WebServer

$sqlCluster = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'SQLCLT'; ClusterIp = '192.168.90.120' }

Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV01" -OperatingSystem $guiServerImage -Roles $sqlCluster
Add-LabMachineDefinition -Name "$($labPrefix)SQLSRV02" -Roles $sqlCluster

Add-LabMachineDefinition -Name "$($labPrefix)CLT01" -OperatingSystem $clientImage -MinMemory 1GB -MaxMemory 4GB -Memory 1GB

Install-Lab

Install-LabSoftwarePackage -ComputerName "$($labPrefix)APPSRV01" -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName "$($labPrefix)SQLSRV01" -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Checkpoint-LabVM -All -SnapshotName 'Initial State'