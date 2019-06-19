$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.user.json'
if(-Not (Test-Path -Path $labSettingsPath)) {
    $labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.default.json'
}

$labSettings = (Get-Content $labSettingsPath ) | ConvertFrom-Json
$labPrefix = $labSettings.labPrefix
$numberOfLabMachines = $labSettings.numberOfLabMachines

$ComputerNames = @()


For ($i=1; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)APPSRV$($i.ToString('00'))"
    $systemName = "CMF$($i.ToString('00'))"
    
    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\vs_community.exe" -CommandLine "/q"
}

