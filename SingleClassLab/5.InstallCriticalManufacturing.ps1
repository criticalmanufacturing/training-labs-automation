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

$productIso = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfIsoName)"

$manifestTemplate = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfParametersFile)"
$machineName = "$($labPrefix)SRV$($labVersion)"

For ($i=1; $i -le $numberOfLabMachines; $i++) {
    $zerozeroId = $i.ToString('00');
    $manifest = (Get-Content $manifestTemplate ) | ConvertFrom-Json
    $manifestFileName = "manifest$($zerozeroId).json"

    $systemName = "CMF$($zerozeroId)"
    $manifest.'Product.SystemName' = $systemName
    $manifest.'Product.Tenant.Name' = $systemName  
    $manifest.'Product.Tenant.Name' = $systemName
    $manifest.'Packages.Root.TargetDirectory' = $manifest.'Packages.Root.TargetDirectory' + '\' + $systemName
    $manifest.'Product.ApplicationServer.Port' = [string]([int]$manifest.'Product.ApplicationServer.Port' + $i)
    $manifest.'Product.ApplicationServer.WcfPort' = [string]([int]$manifest.'Product.ApplicationServer.WcfPort' + $i)
    $manifest.'Product.SecurityPortal.ClientSecret' = $manifest.'Product.SecurityPortal.ClientSecret' + $systemName
    $manifest.'Product.MessageBus.TenantSecurityToken' = $manifest.'Product.MessageBus.TenantSecurityToken' + $systemName
    $manifest.'Product.MessageBus.GlobalSecurityToken' = $manifest.'Product.MessageBus.GlobalSecurityToken' + $systemName
    $manifest.'Product.Gateway.Cluster.Port' = [string]([int]$manifest.'Product.Gateway.Cluster.Port' + $i)
    $manifest.'Product.Gateway.Cluster.BroadcastPort' = [string]([int]$manifest.'Product.Gateway.Cluster.BroadcastPort' + $i)
    $manifest.'Product.LoadBalancer.Port' = [string]([int]$manifest.'Product.LoadBalancer.Port' + $i)
    $manifest.'Product.LoadBalancer.HostLinkPort' = [string]([int]$manifest.'Product.LoadBalancer.HostLinkPort' + $i)
    $manifest.'Product.LoadBalancer.GatewayLinkPort' = [string]([int]$manifest.'Product.LoadBalancer.GatewayLinkPort' + $i)
    $manifest.'Product.Presentation.IisConfiguration.Binding.Port' = [string]([int]$manifest.'Product.Presentation.IisConfiguration.Binding.Port' + $i)

    $manifest.'Product.Gateway.Port' = [string]([int]$manifest.'Product.Gateway.Port' + $i)
    $manifest.'Product.Presentation.IisConfiguration.SupportPort' = [string]([int]$manifest.'Product.Presentation.IisConfiguration.SupportPort' - $i)

    
    Dismount-LabIsoImage -ComputerName $machineName
    Mount-LabIsoImage -IsoPath $productIso -ComputerName $machineName

    $tmp = New-TemporaryFile

    $manifest | ConvertTo-Json | Out-File $tmp.FullName -Encoding ASCII

    $file = $tmp.FullName
    $dir = $tmp.DirectoryName

    $file = Join-Path -Path $dir -ChildPath $manifestFileName
    Remove-Item $file -ErrorAction Ignore

    Rename-Item -Path $tmp.FullName -NewName $file
    
    Copy-LabFileItem -Path $file -ComputerName $machineName -DestinationFolderPath C:\Temp 

    $packageToInstall = "$($labSettings.cmfPackageToInstall)"
    $licenseId = "$($labSettings.cmfLicenseId)"
    $refreshToken = "$($labSettings.cmfToken)"
    Invoke-LabCommand -ComputerName $machineName -ActivityName "Installing Critical Manufacturing $systemName" -ScriptBlock {
        param([string] $packageToInstall, [string] $licenseId, [string] $refreshToken, [string] $manifestFileName)
        # Check Internet connection
        ping portal.criticalmanufacturing.com
        # Move to ISO
        cd d:\

        # Delete log file
        # if (Test-Path "C:\share\log.txt") { Remove-Item "C:\share\log.txt" }

        #Install
        $Output = (.\tools\cmfdeploy.exe install $packageToInstall --logFileLocation="C:\share" --parameters="c:\Temp\$($manifestFileName)" --licenseId="$licenseId" --token="$refreshToken") | Out-String
        if ($Output.Contains("Installation failed")) {
            Write-Error $Output
        } else {
            Write-Host $Output
        }
    } -ArgumentList $packageToInstall,$licenseId,$refreshToken, $manifestFileName
}

