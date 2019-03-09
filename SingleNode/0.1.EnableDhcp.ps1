$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json

$labPrefix = "SN"
$domain = $settings.domain
$user = $settings.username
$password = $settings.password
$adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($settings.shortDomain)\$($user)", $password 

$password = $password | ConvertTo-SecureString  -AsPlainText -Force

Invoke-LabCommand -ComputerName SNAPPSRV01 `
    -ActivityName 'Prepare SQL Server Distribution Media' `
    -ArgumentList "$($labPrefix)DC1", "$($labPrefix)DC1.($domain)", $domain, $adminCredential `
    -ScriptBlock {
param
(
    [string]$dhcpDnsName,
    [string]$dcDnsName,
    [string]$dnsDomain,
    $Credential
)

Install-WindowsFeature DHCP -IncludeManagementTools
netsh dhcp add securitygroups
Restart-service dhcpserver

Add-DhcpServerInDC -DnsName $dhcpDnsName -IPAddress 192.168.80.3
Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
Set-DhcpServerv4DnsSetting -ComputerName $dhcpDnsName -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True
Set-DhcpServerDnsCredential -Credential $Credential -ComputerName $dhcpDnsName
Add-DhcpServerv4Scope -name "Intranet" -StartRange 192.168.80.30 -EndRange 192.168.80.60 -SubnetMask 255.255.0.0 -State Active
Add-DhcpServerv4ExclusionRange -ScopeID 192.168.80.0 -StartRange 192.168.80.1 -EndRange 192.168.80.15
Set-DhcpServerv4OptionValue -OptionID 3 -Value 192.168.80.3 -ScopeID 192.168.80.0 -ComputerName 
Set-DhcpServerv4OptionValue -DnsDomain $dnsDomain -DnsServer 192.168.80.3

}