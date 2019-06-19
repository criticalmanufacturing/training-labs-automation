$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot

$ComputerNames = @("$($labSettings.labPrefix)APPSRV01")

Invoke-LabCommand -ComputerName $computerNames -ActivityName 'Create Share' -ScriptBlock {
    New-Item "C:\Share" -Type Directory -Force
    New-Item "C:\Share\EFC" -Type Directory -Force
    net share Share=C:\Share /GRANT:EVERYONE`,FULL
}