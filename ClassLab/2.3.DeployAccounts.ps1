$UtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Utils';
Import-Module $UtilsPath\Helpers.psm1

$labSourcesLocation = Get-LabSourcesLocation
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$adminPassword = $settings.password
$shortDomain = $settings.shortDomain

$labSettings = Get-LabSettings -labConfigRoot $PSScriptRoot
$startingMachineNumber = $labSettings.startingMachineNumber
$numberOfLabMachines = $labSettings.numberOfLabMachines

$ComputerNames = @("$($labSettings.labPrefix)DC")

Invoke-LabCommand -ComputerName $ComputerNames  -ActivityName 'Create AD Accounts' -ScriptBlock {
    param
    (
        [string] $adminPassword
    )

    # Service User
    $userName = "CMFService";
    $password = "CMF123Service";
    New-ADUser -Name $userName -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true -AccountPassword (ConvertTo-SecureString $password -AsPlainText -force) -passThru 
    Add-ADGroupMember -Identity "Remote Desktop Users" -Members $userName

    # Trainer accounts
    For ($i=1; $i -le 10; $i++) {
        $userName = "trainer$($i.ToString('00'))";
        $password = "$adminPassword";
        New-ADUser -Name $userName -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true -AccountPassword (ConvertTo-SecureString $password -AsPlainText -force) -passThru 
        Add-ADGroupMember -Identity "Remote Desktop Users" -Members $userName
    }

    # Trainee accounts
    For ($i=1; $i -le 25; $i++) {
        $userName = "training$($i.ToString('00'))";
        $password = "trgCMF$($i.ToString('00'))";

        New-ADUser -Name $userName -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true -AccountPassword (ConvertTo-SecureString $password -AsPlainText -force) -passThru 
        Add-ADGroupMember -Identity "Remote Desktop Users" -Members $userName
    }
} -ArgumentList $adminPassword

$ComputerNames = @()
For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $ComputerNames += $machineName
}
$ComputerNames += "$($labPrefix)SQL"

Invoke-LabCommand -ComputerName $ComputerNames  -ActivityName 'Update policies' -ScriptBlock {
    param
    (
        [string] $shortDomain
    )

    $userName = "CMFService";
    Add-LocalGroupMember -Group "Administrators" -Member "$shortDomain\$userName"

    # Trainer accounts
    For ($i=1; $i -le 10; $i++) {
        $userName = "trainer$($i.ToString('00'))";
        Add-LocalGroupMember -Group "Administrators" -Member "$shortDomain\$userName"
    }

    # Trainee accounts
    For ($i=1; $i -le 25; $i++) {
        $userName = "training$($i.ToString('00'))";
        Add-LocalGroupMember -Group "Administrators" -Member "$shortDomain\$userName"
    }

    gpupdate /Force
} -ArgumentList $shortDomain


