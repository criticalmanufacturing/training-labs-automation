# IMPORTANT: You need to dot source this script for it to run properly
$settings = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath '..\settings.user.json') ) | ConvertFrom-Json
$labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.user.json'
if(-Not (Test-Path -Path $labSettingsPath)) {
    $labSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '.\labSettings.default.json'
}

Configuration IISConfigurationData
{
    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    # Dynamically find the applicable nodes from configuration data
    Node localhost
    {

		WindowsFeature Server {
			Name = "Web-Server"
			Ensure = "Present"
		}	

		WindowsFeature Compression {
			Name = "Web-Dyn-Compression"
			Ensure = "Present"
		}

		WindowsFeature BasicAuth {
			Name = "Web-Basic-Auth"
			Ensure = "Present"
		}		

		WindowsFeature WindowsAuth {
			Name = "Web-Windows-Auth"
			Ensure = "Present"
		}

		WindowsFeature NetExt45 {
			Name = "Web-Net-Ext45"
			Ensure = "Present"
		}

		WindowsFeature AspNet45 {
			Name = "Web-Asp-Net45"
			Ensure = "Present"
		}

		WindowsFeature WebSockets {
			Name = "Web-WebSockets"
			Ensure = "Present"
		}

		WindowsFeature ManagementTools {
			Name = "Web-Mgmt-Tools"
			Ensure = "Present"
		}

		WindowsFeature NetFramework {
			Name = "NET-Framework-45-Core"
			Ensure = "Present"
		}

		WindowsFeature NetFrameworkAspNet {
			Name = "NET-Framework-45-ASPNET"
			Ensure = "Present"
		}

		WindowsFeature WebScriptingTools {
			Name = "Web-Scripting-Tools"
			Ensure = "Present"
		}		

		WindowsFeature WebMgmtService {
			Name = "Web-Mgmt-Service"
			Ensure = "Present"
		}		
    }
}


$ConfigurationData = @{
    # Node specific data
    AllNodes = @(
       # All the WebServer has following identical information
       @{
            NodeName                    = 'localhost'
            DefaultWebSitePath = "C:\inetpub\wwwroot"
       }
    )
}

$labSettings = (Get-Content $labSettingsPath ) | ConvertFrom-Json
$labPrefix = $labSettings.labPrefix
$numberOfLabMachines = $labSettings.numberOfLabMachines
$startingMachineNumber = $labSettings.startingMachineNumber

$ComputerNames = @()

For ($i=$startingMachineNumber; $i -le $numberOfLabMachines; $i++) {
    $machineName = "$($labPrefix)SRV$($i.ToString('00'))"
    $ComputerNames += $machineName
}

Invoke-LabDscConfiguration -Configuration (Get-Command -Name IISConfigurationData) -ConfigurationData $ConfigurationData -ComputerName $ComputerNames 
