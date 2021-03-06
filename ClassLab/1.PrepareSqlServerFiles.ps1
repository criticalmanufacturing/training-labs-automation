$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot
$startingMachineNumber = $labSettings.startingMachineNumber

$ComputerNames = @("$($labSettings.labPrefix)SQL")

Copy-LabFileItem -Path ( Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($settings.sqlServerIsoFile)" ) -ComputerName $ComputerNames -DestinationFolderPath C:\Temp
Copy-LabFileItem -Path ( Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($settings.ssmsInstallerFile)" ) -ComputerName $ComputerNames -DestinationFolderPath C:\Temp
Copy-LabFileItem -Path ( Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($settings.reportingServicesInstallerFile)" ) -ComputerName $ComputerNames -DestinationFolderPath C:\Temp

$destinationIsoFileLocation = "C:\temp\$($settings.sqlServerIsoFile)"
Write-Host "ISO File will be at '$destinationIsoFileLocation'"

if ($startingMachineNumber -eq 1) {
    Invoke-LabCommand -ComputerName $ComputerNames  -ActivityName 'Prepare SQL Server Distribution Media' -ArgumentList $destinationIsoFileLocation -ScriptBlock {
        param
        (
            [string]$isoFile
        )

        New-Item -Path C:\SQL2017 -ItemType Directory
        $mountResult = Mount-DiskImage -ImagePath $isoFile -PassThru
        $volumeInfo = $mountResult | Get-Volume
        $driveInfo = Get-PSDrive -Name $volumeInfo.DriveLetter
        Copy-Item -Path ( Join-Path -Path $driveInfo.Root -ChildPath '*' ) -Destination C:\SQL2017\ -Recurse
        Dismount-DiskImage -ImagePath $isoFile
    }
}