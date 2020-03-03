function Get-Domain
{
	<#
	.SYNOPSIS
		Returns the domain object associated with a SID or fqdn.
	
	.DESCRIPTION
		Returns the domain object associated with a SID or fqdn.

		This command uses caching to avoid redundant and expensive lookups & searches.
	
	.PARAMETER Sid
		The domain SID to search by.
	
	.PARAMETER DnsName
		The domain FQDN / full dns name.
		May _also_ be just the Netbios name, but DNS name will take precedence!
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-Domain @parameters -Sid $sid

		Returns the domain object associated with the $sid
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Sid')]
		[string]
		$Sid,

		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$DnsName,

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

		if (-not $script:SIDtoDomain) { $script:SIDtoDomain = @{ } }
		if (-not $script:DNStoDomain) { $script:DNStoDomain = @{ } }
		if (-not $script:NetBiostoDomain) { $script:NetBiostoDomain = @{ } }
		
		# Define variable to prevent superscope lookup
		$internalSid = $null
		$domainObject = $null
	}
	process
	{
		if ($Sid) {
			$internalSid = ([System.Security.Principal.SecurityIdentifier]$Sid).AccountDomainSid.Value
		}
		if ($internalSid -and $script:SIDtoDomain[$internalSid]) { return $script:SIDtoDomain[$internalSid] }
		if ($DnsName -and $script:DNStoDomain[$DnsName]) { return $script:DNStoDomain[$DnsName] }
		if ($DnsName -and $script:NetBiostoDomain[$DnsName]) { return $script:NetBiostoDomain[$DnsName] }

		$identity = $internalSid
		if ($DnsName) { $identity = $DnsName }

		$credsToUse = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		$forestObject = Get-ADForest @parameters
		foreach ($domainName in $forestObject.Domains) {
			if ($script:DNSToDomain.Keys -contains $domainName) { continue }
			try {
				$domainObject = Get-ADDomain -Server $domainName @credsToUse -ErrorAction Stop
				$script:SIDtoDomain["$($domainObject.DomainSID)"] = $domainObject
				$script:DNStoDomain["$($domainObject.DNSRoot)"] = $domainObject
				$script:NetBiostoDomain["$($domainObject.NetBIOSName)"] = $domainObject
			}
			catch { }
		}

		if ($script:SIDtoDomain[$identity]) { return $script:SIDtoDomain[$identity] }
		if ($script:DNStoDomain[$identity]) { return $script:DNStoDomain[$identity] }
		if ($script:NetBiostoDomain[$identity]) { return $script:NetBiostoDomain[$identity] }

		try { $domainObject = Get-ADDomain @parameters -Identity $identity -ErrorAction Stop }
		catch {
			if (-not $domainObject) {
				try { $domainObject = Get-ADDomain -Identity $identity -ErrorAction Stop }
				catch { }
			}
			if (-not $domainObject) { throw }
		}

		if ($domainObject) {
			$script:SIDtoDomain["$($domainObject.DomainSID)"] = $domainObject
			$script:DNStoDomain["$($domainObject.DNSRoot)"] = $domainObject
			$script:NetBiostoDomain["$($domainObject.NetBIOSName)"] = $domainObject
			if ($DnsName) { $script:DNStoDomain[$DnsName] = $domainObject }
			$domainObject
		}
	}
}