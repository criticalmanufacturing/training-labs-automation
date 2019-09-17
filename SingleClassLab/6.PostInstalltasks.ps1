$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.user.json'
if(-Not (Test-Path -Path $labSettingsPath)) {
    $labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.default.json'
}

$labSettings = (Get-Content $labSettingsPath ) | ConvertFrom-Json
$labPrefix = $labSettings.labPrefix
$labVersion = $labSettings.labVersion
$numberOfLabMachines = $labSettings.numberOfHosts


$manifestTemplate = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfParametersFile)"
$machineName = "$($labPrefix)SRV$($labVersion)"
$address = "$($machineName).cmflab.com"

For ($i=1; $i -le $numberOfLabMachines; $i++) {
    $zerozeroId = $i.ToString('00');
    $manifest = (Get-Content $manifestTemplate ) | ConvertFrom-Json

    $systemName = "CMF$($zerozeroId)"
    $bindingPort = [string]([int]$manifest.'Product.Presentation.IisConfiguration.Binding.Port' + $i)
    

    Invoke-LabCommand -ComputerName $machineName -ActivityName "Configuring Tools for $systemName" -ScriptBlock {
        param([string] $systemName,  [string] $bindingPort, [string] $address)
        
        #create system directory
        New-Item -Path "C:\Tools" -Name "$systemName" -ItemType Directory

        # Silverlight link
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut("C:\Tools\$($systemName)\Silverlight UI.url")
        $Favorite.TargetPath = "http://$($address):$($bindingPort)/Silverlight";
        $Favorite.Save()

        # HTML5 Link
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut("C:\Tools\$($systemName)\HTML UI.lnk")
        $Favorite.TargetPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        $Favorite.Arguments = "http://$($address):$($bindingPort)/";
        $Favorite.Save()
    
        
        # Documentation UI
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut("C:\Tools\$($systemName)\Documentation UI.lnk")
        $Favorite.TargetPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        $Favorite.Arguments = "http://$($address):$($bindingPort)/Help";
        $Favorite.Save()
    
        # Change service to automatic
        Set-Service -Name "cmfDiscoveryService$($systemName)" -StartupType Automatic

        # Copy Master data loader
        New-Item -Path "C:\Tools\$($systemName)" -Name "MasterDataLoader" -ItemType Directory
        Copy-Item -Path "C:\Program Files\CriticalManufacturing\$($systemName)\MasterDataLoader\*" -Destination "C:\Tools\$($systemName)\MasterDataLoader" -Recurse


    } -ArgumentList $systemName, $bindingPort, $address
}

Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\Silverlight_x64.exe" -CommandLine "/q"
Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSources\ISOs\ChromeStandaloneSetup64.exe" -CommandLine "/silent /install"

