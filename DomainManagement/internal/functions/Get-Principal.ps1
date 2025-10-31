function Get-Principal
{
	<#
	.SYNOPSIS
		Returns a principal's resolved AD object if able to.
	
	.DESCRIPTION
		Returns a principal's resolved AD object if able to.
		Will throw an exception if the AD connection fails.
		Will return nothing if the target domain does not contain the specified principal.
		Uses the credentials provided by Set-DMDomainCredential if available.

		Results will be cached automatically, subsequent callls returning the cached results.
	
	.PARAMETER Sid
		The SID of the principal to search.

	.PARAMETER Name
		The name of the principal to search for.

	.PARAMETER ObjectClass
		The objectClass of the principal to search for.
	
	.PARAMETER Domain
		The domain in which to look for the principal.

	.PARAMETER OutputType
		The format in which the output is being returned.
		- ADObject: Returns the full AD object with full information from AD
		- NTAccount: Returns a simple NT Account notation.

	.PARAMETER Refresh
		Do not use cached data, reload fresh data.

	.PARAMETER Target
		The target AD object this access rule applies to.
		Used for logging only.

	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-Principal -Sid $adObject.ObjectSID -Domain $redForestDomainFQDN

		Tries to return the principal from the specified domain based on the SID offered.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = 'SID')]
		[string]
		$Sid,

		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$ObjectClass,

		[Parameter(Mandatory = $true)]
		[string]
		$Domain,

		[ValidateSet('ADObject','NTAccount')]
		[string]
		$OutputType = 'ADObject',

		[switch]
		$Refresh,

		[AllowEmptyString()]
		[string]
		$Target,

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parametersAD = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process
	{
		$identity = $Sid
		if (-not $Sid) { $identity = "$($Domain)þ$($objectClass)þ$($Name)" }

		if ($script:resolvedPrincipals[$identity] -and -not $Refresh) {
			switch ($OutputType) {
				'ADObject' { return $script:resolvedPrincipals[$identity] }
				'NTAccount'
				{
					if ($script:resolvedPrincipals[$identity].objectSID.AccountDomainSid) { return [System.Security.Principal.NTAccount]"$((Get-Domain @parametersAD -Sid $script:resolvedPrincipals[$identity].objectSID.AccountDomainSid).Name)\$($script:resolvedPrincipals[$identity].SamAccountName)" }
					else { return [System.Security.Principal.NTAccount]"BUILTIN\$($script:resolvedPrincipals[$identity].SamAccountName)" }
				}
			}
		}

		try {
			if ($Domain -as [System.Security.Principal.SecurityIdentifier]) {
				$domainObject = Get-Domain @parametersAD -Sid $Domain
			}
			else {
				$domainObject = Get-Domain @parametersAD -DnsName $Domain
			}
			$parameters = @{
				Server = $domainObject.DNSRoot
			}
			$domainName = $domainObject.DNSRoot
		}
		catch {
			$parameters = @{
				Server = $Domain
			}
			$domainName = $Domain
		}
		if ($credentials = Get-DMDomainCredential -Domain $domainName) { $parameters['Credential'] = $credentials }

		$filter = "(objectSID=$Sid)"
		if (-not $Sid) { $filter = "(&(objectClass=$ObjectClass)(|(name=$Name)(samAccountName=$Name)(distinguishedName=$Name)))" }

		try { $adObject = Get-ADObject @parameters -LDAPFilter $filter -ErrorAction Stop -Properties * | Select-Object -First 1 }
		catch {
			try { $adObject = Get-ADObject @parametersAD -LDAPFilter $filter -ErrorAction Stop -Properties * | Select-Object -First 1 }
			catch { }
			if (-not $adObject) {
				if ($Target) { Write-PSFMessage -Level Warning -String 'Get-Principal.Resolution.FailedWithTarget' -StringValues $Sid, $Name, $ObjectClass, $Domain, $Target -Target $PSBoundParameters }
				else { Write-PSFMessage -Level Warning -String 'Get-Principal.Resolution.Failed' -StringValues $Sid, $Name, $ObjectClass, $Domain -Target $PSBoundParameters }
				throw
			}
		}
		if ($adObject) {
			$script:resolvedPrincipals[$identity] = $adObject
			switch ($OutputType) {
				'ADObject' { return $adObject }
				'NTAccount'
				{
					if ($adObject.objectSID.AccountDomainSid) { return [System.Security.Principal.NTAccount]"$((Get-Domain @parametersAD -Sid $adObject.objectSID.AccountDomainSid).Name)\$($adObject.SamAccountName)" }
					else { [System.Security.Principal.NTAccount]"BUILTIN\$($adObject.SamAccountName)" }
				}
			}
		}
	}
}