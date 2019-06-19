$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot

$labPrefix = $labSettings.labPrefix

$productIso = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfIsoName)"

$manifestTemplate = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\template.json"
$manifest = (Get-Content $manifestTemplate ) | ConvertFrom-Json

$machineName = "$($labPrefix)APPSRV01"
$systemName = "CMF"

$manifest.'Product.SystemName' = $systemName
$manifest.'Product.Tenant.Name' = "CMF"
$manifest.'Product.ApplicationServer.Address' = $machineName    
$manifest.'Product.Gateway.Address' = $machineName
$manifest.'Product.LoadBalancer.Address' = $machineName
$manifest.'Product.Database.BackupShare' = "\\$($machineName)\share"
$manifest.'Package[Product.Database.Online].Database.Server' = "$($machineName)\online"
$manifest.'Package[Product.Database.Ods].Database.Server' = "$($machineName)\ODS"
$manifest.'Package[Product.Database.Dwh].Database.Server' = "$($machineName)\ODS"
$manifest.'Package[Product.Database.As].Database.Server' = "$($machineName)\ODS"
$manifest.'Package.ReportingServices.Address' = "http://$($machineName)/ReportServer"
$manifest.'Product.ElectronicFailureCatalog.Location' = "\\$($machineName)\share\efc"
$manifest.'Agent.MasterHostName' = $machineName

Mount-LabIsoImage -IsoPath $productIso -ComputerName $machineName

$tmp = New-TemporaryFile

$manifest | ConvertTo-Json | Out-File $tmp.FullName -Encoding ASCII

$file = $tmp.FullName
$dir = $tmp.DirectoryName

$file = Join-Path -Path $dir -ChildPath manifest.json
Remove-Item $file -ErrorAction Ignore

Rename-Item -Path $tmp.FullName -NewName $file

Copy-LabFileItem -Path $file -ComputerName $machineName -DestinationFolderPath C:\Temp 

Invoke-LabCommand -ComputerName $machineName -ActivityName "Installing Critical Manufacturing on $machineName" -ScriptBlock {
    cd d:\

    .\tools\cmfdeploy.exe install CriticalManufacturing@6.4.0 -parameters c:\temp\manifest.json
}

Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\Silverlight_x64.exe" -CommandLine "/q"
Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\ChromeStandaloneSetup64.exe" -CommandLine "/silent /install"

Invoke-LabCommand -ComputerName $machineName -ActivityName "Create Silverlight UI shortcut on $machineName" -ScriptBlock {
    param([string] $systemName)
    $Shell = New-Object -ComObject ("WScript.Shell")
    $Favorite = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\Silverlight UI.url")
    $Favorite.TargetPath = "http://localhost:81/$($systemName)";
    $Favorite.Save()
} -ArgumentList $systemName

Invoke-LabCommand -ComputerName $machineName -ActivityName "Create HTML UI shortcut on $machineName" -ScriptBlock {
    param([string] $systemName)
    $Shell = New-Object -ComObject ("WScript.Shell")
    $Favorite = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\HTML UI.lnk")
    $Favorite.TargetPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    $Favorite.Arguments = "http://localhost:82/";
    $Favorite.Save()
}


