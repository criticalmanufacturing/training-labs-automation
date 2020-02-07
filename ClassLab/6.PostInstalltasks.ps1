$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$domain = $settings.domain

$labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.user.json'
if(-Not (Test-Path -Path $labSettingsPath)) {
    $labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.default.json'
}

$labSettings = (Get-Content $labSettingsPath ) | ConvertFrom-Json
$labPrefix = $labSettings.labPrefix
$numberOfLabMachines = $labSettings.numberOfLabMachines
$startingMachineNumber = $labSettings.startingMachineNumber

For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $systemName = "CMF$($i.ToString('00'))"

    Invoke-LabCommand -ComputerName $machineName -ActivityName "Post tasks on $machineName" -ScriptBlock {
        param([string] $systemName, [string] $machineName, [string] $domain)

        # HTML5 Link
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\HTML UI.lnk")
        $Favorite.TargetPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        $Favorite.Arguments = "https://$machineName.$domain/";
        $Favorite.Save()

        
        # Documentation UI
        $Shell = New-Object -ComObject ("WScript.Shell")
        $Favorite = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\Documentation UI.lnk")
        $Favorite.TargetPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        $Favorite.Arguments = "https://$machineName.$domain/Help";
        $Favorite.Save()

        # Change service to automatic
        Set-Service -Name "cmfDiscoveryService$($systemName)" -StartupType Automatic
    } -ArgumentList $systemName, $machineName, $domain
}
