function Resolve-GPTargetServer {
	<#
	.SYNOPSIS
		Resolve the target to use for GPO Operations.
		
	.DESCRIPTION
		Resolve the target to use for GPO Operations.
		By default, all GPO Components work with the PDC Emulator, as it is the server targeted by all GPMC consoles.

		It will also - once per session - remind the user, that the target was redirected to the PDC.
		It returns a hashtable ready to use for splatting with AD commands, including Server and - if originally provided - Credential.
	
	.PARAMETER Server
		The original server to target.
	
	.PARAMETER Credential
		The credentials to use.
	
	.PARAMETER ForRemoting
		We require the connection parameters for PowerShell Remoting.
		Replaces "Server" with "ComputerName" in the resulting hashtable.
	
	.EXAMPLE
		PS C:\> Resolve-GPTargetServer -Server dc1.contoso.com -Credential $cred

		Returns a hashtable with the data required to execute AD commands (Keys "Server" & "Credential").
		If the original target server was not the PDC emulator, it was replaced with the PDC from contoso.com.
	#>
	[outputType([hashtable])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFComputer]
		$Server,

		[AllowNull()]
		[PSCredential]
		$Credential,

		[switch]
		$ForRemoting
	)
	begin {
		if (-not $script:cache_GPDomainTarget) {
			$script:cache_GPDomainTarget = @{}
		}
		$isEnabled = Get-PSFConfigValue -FullName 'DomainManagement.GroupPolicy.AlwaysUsePDC' -Fallback $true
	}
	process {
		$adParam = @{ Server = $Server }
		if ($Credential) { $adParam.Credential = $Credential }
		
		if (-not $isEnabled) {
			if ($ForRemoting) {
				$adParam.ComputerName = $adParam.Server
				$adParam.Remove("Server")
			}
			return $adParam
		}

		if (-not $script:cache_GPDomainTarget["$Server"]) {
			$script:cache_GPDomainTarget["$Server"] = Get-ADDomain @adParam
		}
		$domainObject = $script:cache_GPDomainTarget["$Server"]

		if ($domainObject.PDCEmulator -ne $Server) {
			if ($domainObject.DnsRoot -ne $Server) {
				Write-PSFMessage -Level Host -String 'Resolve-GPTargetServer.Info.ChangingToPDC' -StringValues $Server, $domainObject.PDCEmulator -Target $domainObject.DnsRoot -Once "$($Server)->$($domainObject.PDCEmulator)"
			}
			$adParam.Server = $domainObject.PDCEmulator
		}
		if ($ForRemoting) {
			$adParam.ComputerName = $adParam.Server
			$adParam.Remove("Server")
		}
		return $adParam
	}
}