
$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot
$startingMachineNumber = $labSettings.startingMachineNumber
$certificate = $labSettings.certificateFile
$certificatePassword = $labSettings.certificatePassword
$numberOfLabMachines = $labSettings.numberOfLabMachines

$ComputerNames = @()

$certificateFile = Join-Path -Path $labSourcesLocation -ChildPath "ISOs\$certificate"

For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"

    # copy certificate
    Copy-LabFileItem -Path $certificateFile -ComputerName $machineName -DestinationFolderPath C:\Temp 

    $ComputerNames += $machineName
}

Invoke-LabCommand -ComputerName $ComputerNames  -ActivityName 'Create certificates' -ScriptBlock {
    param
    (
        [string] $certificate,
        [string] $certificatePassword
    )


    Import-PfxCertificate -Exportable -Password (ConvertTo-SecureString "$certificatePassword" -AsPlainText -force) -CertStoreLocation "cert:\LocalMachine\My" -FilePath "C:\Temp\$certificate"
    Import-PfxCertificate -Exportable -Password (ConvertTo-SecureString "$certificatePassword" -AsPlainText -force) -CertStoreLocation "cert:\LocalMachine\Root" -FilePath "C:\Temp\$certificate"    
} -ArgumentList $certificate, $certificatePassword

# To create new cert: New-SelfSignedCertificate -DnsName "*.cmflab.local" -CertStoreLocation "cert:\LocalMachine\My" -FriendlyName cmflablocal 
