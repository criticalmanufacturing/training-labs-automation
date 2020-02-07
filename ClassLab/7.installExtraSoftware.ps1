$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.user.json'
if(-Not (Test-Path -Path $labSettingsPath)) {
    $labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.default.json'
}

$labSettings = (Get-Content $labSettingsPath ) | ConvertFrom-Json
$labPrefix = $labSettings.labPrefix
$numberOfLabMachines = $labSettings.numberOfLabMachines
$startingMachineNumber = $labSettings.startingMachineNumber

For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $systemName = "CMF$($i.ToString('00'))"
    
    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\npp.7.8.1.Installer.x64.exe" -CommandLine "/S"
    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\VSCodeSetup-x64-1.40.0.exe" -CommandLine "/VERYSILENT /MERGETASKS=!runcode"
    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\vs_community.exe" -CommandLine "/q"
}
