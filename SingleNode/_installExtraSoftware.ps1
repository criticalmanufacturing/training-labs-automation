$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot

$labPrefix = $labSettings.labPrefix
$numberOfLabMachines = $labSettings.numberOfLabMachines

$machineName = "$($labPrefix)APPSRV01"
$systemName = "CMF"

Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\node-v8.16.0-x64.msi" -CommandLine "/qn"
Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\VSCodeUserSetup-x64-1.35.1.exe" -CommandLine "/VERYSILENT /MERGETASKS=!runcode"


# npm install --global --production windows-build-tools
# mkdir c:\verdaccio


