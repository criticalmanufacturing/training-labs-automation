$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

$ComputerNames = @('SNAPPSRV01')

Invoke-LabCommand -ComputerName $computerNames -ActivityName 'Create Share' -ScriptBlock {
    New-Item "C:\Share" -Type Directory -Force
    New-Item "C:\Share\EFC" -Type Directory -Force
    net share Share=C:\Share /GRANT:EVERYONE`,FULL
}