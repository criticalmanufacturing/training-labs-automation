$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$domain = $settings.shortDomainUpperCase
$adminUser = $settings.username
$labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.user.json'

if(-Not (Test-Path -Path $labSettingsPath)) {
    $labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.default.json'
}

# Create JSON User string

$usersString = "`"Product.Users[0].Account`": `"$domain\\$adminUser`",`"Product.Users[0].UserName`": `"$adminUser`","
$usersString = $usersString + "`"Product.Users[1].Account`": `"$domain\\CMFService`",`"Product.Users[1].UserName`": `"CMFService`","

$userIndex = 2;

# Trainer accounts
For ($i=1; $i -le 10; $i++) {
    $usersString = $usersString + "`"Product.Users[$userIndex].Account`": `"$domain\\trainer$($i.ToString('00'))`",`"Product.Users[$userIndex].UserName`": `"trainer$($i.ToString('00'))`","

    $userIndex++
}

# Trainee accounts
For ($i=1; $i -le 25; $i++) {
    $usersString = $usersString + "`"Product.Users[$userIndex].Account`": `"$domain\\training$($i.ToString('00'))`",`"Product.Users[$userIndex].UserName`": `"training$($i.ToString('00'))`","
    $userIndex++
}

$labSettings = (Get-Content $labSettingsPath ) | ConvertFrom-Json
$labPrefix = $labSettings.labPrefix
$numberOfLabMachines = $labSettings.numberOfLabMachines
$startingMachineNumber = $labSettings.startingMachineNumber

$productIso = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfIsoName)"

$manifestTemplate = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($labSettings.cmfParametersFile)"

For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $manifestFile = Get-Content $manifestTemplate 
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $sqlMachine = "$($labPrefix)SQL"

    # Replace Tokens
    $manifestFile = $manifestFile -replace "<MACHINE>",$machineName
    $manifestFile = $manifestFile -replace "<SQLMACHINE>",$sqlMachine

    # Calculate system users
    $manifestFile = $manifestFile -replace "<USERS>",$usersString

    # Write-Host $manifestFile
    $manifest = $manifestFile | ConvertFrom-Json
    $systemName = "CMF$($i.ToString('00'))"
    $manifest.'Product.SystemName' = $systemName
    $manifest.'Product.Tenant.Name' = $systemName

    Dismount-LabIsoImage -ComputerName $machineName
    Mount-LabIsoImage -IsoPath $productIso -ComputerName $machineName

    $tmp = New-TemporaryFile
    $manifest | ConvertTo-Json | Out-File $tmp.FullName -Encoding ASCII

    $file = $tmp.FullName
    $dir = $tmp.DirectoryName

    $file = Join-Path -Path $dir -ChildPath parameters.json
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
        $Output = (.\tools\cmfdeploy.exe install $packageToInstall --logFileLocation="C:\temp" --parameters="c:\temp\parameters.json" --licenseId="$licenseId" --token="$refreshToken") | Out-String
        if ($Output.Contains("Installation failed")) {
            Write-Error $Output
        } else {
            Write-Host $Output
        }
    } -ArgumentList $packageToInstall,$licenseId,$refreshToken

    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSourcesLocation\ISOs\Silverlight_x64.exe" -CommandLine "/q"
    Install-LabSoftwarePackage -ComputerName $machineName -Path "$labSourcesLocation\ISOs\ChromeStandaloneSetup64.exe" -CommandLine "/silent /install"
}

