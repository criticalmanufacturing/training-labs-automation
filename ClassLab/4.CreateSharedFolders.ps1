$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot

$labPrefix = $labSettings.labPrefix
$numberOfLabMachines = $labSettings.numberOfLabMachines
$startingMachineNumber = $labSettings.startingMachineNumber

$ComputerNames = @()

For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $ComputerNames += $machineName
}

Invoke-LabCommand -ComputerName $computerNames -ActivityName 'Create Share' -ScriptBlock {
    New-Item "C:\ProductShare" -Type Directory -Force
    New-Item "C:\ProductShare\EFC" -Type Directory -Force
    New-Item "C:\ProductShare\Documents" -Type Directory -Force
    New-Item "C:\ProductShare\Documents\Permanent" -Type Directory -Force
    New-Item "C:\ProductShare\Documents\Temp" -Type Directory -Force
    New-Item "C:\ProductShare\Documents\Archive" -Type Directory -Force

    net share ProductShare=C:\ProductShare /GRANT:EVERYONE`,FULL
}

$ComputerNames = @("$($labPrefix)SQL")

if ($startingMachineNumber -eq 1) {
    Invoke-LabCommand -ComputerName $computerNames -ActivityName 'Create SQL share' -ScriptBlock {
        New-Item "D:\share" -Type Directory -Force
        net share share=D:\share /GRANT:EVERYONE`,FULL
    }
}
