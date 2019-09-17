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

$productIso = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfIsoName)"

$manifestTemplate = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfParametersFile)"
$manifest = (Get-Content $manifestTemplate ) | ConvertFrom-Json

For ($i=1; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)APPSRV$($i.ToString('00'))"
    $systemName = "CMF$($i.ToString('00'))"

    $manifest.'Product.SystemName' = $systemName
    $manifest.'Product.Tenant.Name' = "CMF$($i.ToString('00'))"
    $manifest.'Product.ApplicationServer.Address' = $machineName    
    $manifest.'Product.Gateway.Address' = $machineName
    $manifest.'Product.LoadBalancer.Address' = $machineName    
    
    Dismount-LabIsoImage -ComputerName $machineName
    Mount-LabIsoImage -IsoPath $productIso -ComputerName $machineName
    $ComputerNames += $machineName

    $tmp = New-TemporaryFile

    $manifest | ConvertTo-Json | Out-File $tmp.FullName -Encoding ASCII

    $file = $tmp.FullName
    $dir = $tmp.DirectoryName

    $file = Join-Path -Path $dir -ChildPath manifest.json
    Remove-Item $file -ErrorAction Ignore

    Rename-Item -Path $tmp.FullName -NewName $file
    
    Copy-LabFileItem -Path $file -ComputerName $machineName -DestinationFolderPath C:\Temp 

    $packageToInstall = "$($labSettings.cmfPackageToInstall)"
    $licenseId = "$($labSettings.cmfLicenseId)"
    $refreshToken = "$($labSettings.cmfToken)"
    Invoke-LabCommand -ComputerName $machineName -ActivityName "Installing Critical Manufacturing on $machineName" -ScriptBlock {
        param([string] $packageToInstall, [string] $licenseId, [string] $refreshToken)
        # Check Internet connection
        ping portal.criticalmanufacturing.com
        # Move to ISO
        cd d:\

        # Delete log file
        if (Test-Path "C:\share\log.txt") { Remove-Item "C:\share\log.txt" }

        #Install
        $Output = (.\tools\cmfdeploy.exe install $packageToInstall --logFileLocation="C:\share" --parameters="c:\temp\manifest.json" --licenseId="$licenseId" --token="$refreshToken") | Out-String
        if ($Output.Contains("Installation failed")) {
            Write-Error $Output
        } else {
            Write-Host $Output
        }
    } -ArgumentList $packageToInstall,$licenseId,$refreshToken

    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\Silverlight_x64.exe" -CommandLine "/q"
    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\ChromeStandaloneSetup64.exe" -CommandLine "/silent /install"

    Invoke-LabCommand -ComputerName $machineName -ActivityName "Create Silverlight UI shortcut on $machineName" -ScriptBlock {
        param([string] $systemName)
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\Silverlight UI.url")
        $Favorite.TargetPath = "http://localhost:80/Silverlight";
        $Favorite.Save()
    } -ArgumentList $systemName

    Invoke-LabCommand -ComputerName $machineName -ActivityName "Create HTML UI shortcut on $machineName" -ScriptBlock {
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\HTML UI.lnk")
        $Favorite.TargetPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        $Favorite.Arguments = "http://localhost:80/";
        $Favorite.Save()
    }
		
	Invoke-LabCommand -ComputerName $machineName -ActivityName "Create Help shortcut on $machineName" -ScriptBlock {
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\Documentation UI.lnk")
        $Favorite.TargetPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        $Favorite.Arguments = "http://localhost:80/Help";
        $Favorite.Save()
    }
}

