$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

$ComputerNames = @('SNAPPSRV01','SNAPPSRV02','SNAPPSRV03','SNAPPSRV04','SNAPPSRV05','SNAPPSRV06','SNAPPSRV07','SNAPPSRV08','SNAPPSRV09','SNAPPSRV10','SNAPPSRV11','SNAPPSRV12')

Invoke-LabCommand -ComputerName $computerNames -ActivityName 'Create Share' -ScriptBlock {
    New-Item "C:\Share" -Type Directory -Force
    New-Item "C:\Share\EFC" -Type Directory -Force
    net share Share=C:\Share /GRANT:EVERYONE`,FULL
}