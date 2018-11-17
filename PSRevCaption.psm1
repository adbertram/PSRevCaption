$script:configurationFilePath = "$PSScriptRoot\configuration.json"

function Get-PSRevCaptionConfiguration {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Sandbox', 'Production')]
		[string]$Endpoint
	)
	
	$ErrorActionPreference = 'Stop'

	function decrypt([string]$TextToDecrypt) {
		$secure = ConvertTo-SecureString $TextToDecrypt
		$hook = New-Object system.Management.Automation.PSCredential("test", $secure)
		$plain = $hook.GetNetworkCredential().Password
		return $plain
	}

	try {
		$config = Get-Content -Path $script:configurationFilePath | ConvertFrom-Json

		foreach ($item in 'ClientApiKey', 'UserApiKey', 'UserEmail', 'UserPassword') {
			if ($config.$Endpoint.$item) {
				$config.$Endpoint.$item = decrypt($config.$Endpoint.$item)
			}
		}
		$config.$Endpoint
	} catch {
		Write-Error $_.Exception.Message
	}
}

function Save-PSRevCaptionConfiguration {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Sandbox', 'Production')]
		[string]$Endpoint,

		[Parameter()]
		[string]$ClientApiKey,

		[Parameter()]
		[string]$UserApiKey,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$UserEmail,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$UserPassword
	)

	begin {
		function encrypt([string]$TextToEncrypt) {
			$secure = ConvertTo-SecureString $TextToEncrypt -AsPlainText -Force
			$encrypted = $secure | ConvertFrom-SecureString
			return $encrypted
		}
	}
	
	process {
		$config = Get-PSRevCaptionConfiguration

		foreach ($item in 'ClientApiKey', 'UserApiKey', 'UserEmail', 'UserPassword') {
			if ($var = Get-Variable -Name $item -ErrorAction Ignore) {
				$config.$Endpoint.$item = encrypt($var.Value)
			}
		}
		$config | ConvertTo-Json | Set-Content -Path $script:configurationFilePath
	}
}
