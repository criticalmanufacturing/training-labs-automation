
$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

Copy-LabFileItem -Path ( Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($settings.sqlServerIsoFile)" ) -ComputerName SNAPPSRV01 -DestinationFolderPath C:\Temp
Copy-LabFileItem -Path ( Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($settings.ssmsInstallerFile)" ) -ComputerName SNAPPSRV01 -DestinationFolderPath C:\Temp
Copy-LabFileItem -Path ( Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$($settings.reportingServicesInstallerFile)" ) -ComputerName SNAPPSRV01 -DestinationFolderPath C:\Temp

$destinationIsoFileLocation = "C:\temp\$($settings.sqlServerIsoFile)"
Write-Host "ISO File will be at '$destinationIsoFileLocation'"

Invoke-LabCommand -ComputerName SNAPPSRV01 -ActivityName 'Prepare SQL Server Distribution Media' -ArgumentList $destinationIsoFileLocation -ScriptBlock {
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