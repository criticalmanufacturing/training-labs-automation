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

$ComputerNames = @()


For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $systemName = "CMF$($i.ToString('00'))"

    Copy-LabFileItem -Path ( Join-Path -Path $labSourcesLocation -ChildPath "ISOs\PartnersTrainingCoreMasterData.xlsx" ) -ComputerName $machineName -DestinationFolderPath C:\Temp

    Invoke-LabCommand -ComputerName $machineName -ActivityName "Installing Master Data on $machineName" -ScriptBlock {
        param([string]$systemName)        
        
        cd 'C:\Program Files\CriticalManufacturing\MasterDataLoader'

        .\MasterData.exe "c:\temp\PartnersTrainingCoreMasterData.xlsx" /createincollection:false

    } -ArgumentList $systemName
}

