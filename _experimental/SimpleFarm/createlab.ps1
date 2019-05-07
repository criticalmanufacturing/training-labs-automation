Write-Host "==========================================="
Write-Host "Starting lab creation"
Write-Host "==========================================="

. .\0.SimpleFarmScenario.ps1

Write-Host "==========================================="
Write-Host "Copying SQL Server Files"
Write-Host "==========================================="

. .\1.PrepareSqlServerFiles.ps1

Write-Host "==========================================="
Write-Host "Installing and configuring SQL Server"
Write-Host "==========================================="

. .\2.DeployConfiguration.ps1

Restart-LabVM -ComputerName "SFSQLSRV01"
Restart-LabVM -ComputerName "SFSQLSRV02"

