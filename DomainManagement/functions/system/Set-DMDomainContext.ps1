function Set-DMDomainContext
{
	<#
		.SYNOPSIS
			Updates the domain settings for string replacement.
		
		.DESCRIPTION
			Updates the domain settings for string replacement.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.EXAMPLE
			PS C:\> Set-DMDomainContext @parameters

			Updates the current domain context
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
	}
	process
	{
		$domainObject = Get-ADDomain @parameters
		$forestObject = Get-ADForest @parameters
		if ($forestObject.RootDomain -eq $domainObject.DNSRoot) {
			$forestRootDomain = $domainObject
			$forestRootSID = $forestRootDomain.DomainSID.Value
		}
		else {
			try {
				$cred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
				$forestRootDomain = Get-ADDomain @cred -Server $forestObject.RootDomain -ErrorAction Stop
				$forestRootSID = $forestRootDomain.DomainSID.Value
			}
			catch {
				$forestRootDomain = [PSCustomObject]@{
					Name = $forestObject.RootDomain.Split(".",2)[0]
					DNSRoot = $forestObject.RootDomain
					DistinguishedName = 'DC={0}' -f ($forestObject.RootDomain.Split(".") -join ",DC=")
				}
				$forestRootSID = (Get-ADObject @parameters -SearchBase "CN=System,$($domainObject.DistinguishedName)" -SearchScope OneLevel -LDAPFilter "(&(objectClass=trustedDomain)(trustPartner=$($forestObject.RootDomain)))" -Properties securityIdentifier).securityIdentifier.Value
			}
		}

		$script:domainContext.Name = $domainObject.Name
		$script:domainContext.Fqdn = $domainObject.DNSRoot
		$script:domainContext.DN = $domainObject.DistinguishedName
		$script:domainContext.ForestFqdn = $forestObject.Name

		Register-DMNameMapping -Name '%DomainName%' -Value $domainObject.Name
		Register-DMNameMapping -Name '%DomainFqdn%' -Value $domainObject.DNSRoot
		Register-DMNameMapping -Name '%DomainDN%' -Value $domainObject.DistinguishedName
		Register-DMNameMapping -Name '%DomainSID%' -Value $domainObject.DomainSID.Value
		Register-DMNameMapping -Name '%RootDomainName%' -Value $forestRootDomain.Name
		Register-DMNameMapping -Name '%RootDomainFqdn%' -Value $forestRootDomain.DNSRoot
		Register-DMNameMapping -Name '%RootDomainDN%' -Value $forestRootDomain.DistinguishedName
		Register-DMNameMapping -Name '%RootDomainSID%' -Value $forestRootSID
		Register-DMNameMapping -Name '%ForestFqdn%' -Value $forestObject.Name

		if ($Credential) {
			Set-DMDomainCredential -Domain $domainObject.DNSRoot -Credential $Credential
			Set-DMDomainCredential -Domain $domainObject.Name -Credential $Credential
			Set-DMDomainCredential -Domain $domainObject.DistinguishedName -Credential $Credential
		}
	}
}
