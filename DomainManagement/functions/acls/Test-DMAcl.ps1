function Test-DMAcl
{
	<#
		.SYNOPSIS
			Tests whether the configured groups match a domain's configuration.
		
		.DESCRIPTION
			Tests whether the configured groups match a domain's configuration.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.EXAMPLE
			PS C:\> Test-DMGroup

			Tests whether the configured groups' state matches the current domain group setup.
	#>
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
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Acls -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		#region processing configuration
		foreach ($aclDefinition in $script:acls.Values) {
			$resolvedPath = Resolve-String -Text $aclDefinition.Path

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'Acl'
				Identity = $resolvedPath
				Configuration = $aclDefinition
			}

			
			if (-not (Test-ADObject @parameters -Identity $resolvedPath))  {
				if ($aclDefinition.Optional) { continue }
				Write-PSFMessage -String 'Test-DMAcl.ADObjectNotFound' -StringValues $resolvedPath -Tag 'panic','failed' -Target $aclDefinition
				New-TestResult @resultDefaults -Type 'MissingADObject'
				Continue
			}

			try { $aclObject = Get-AdsAcl @parameters -Path $resolvedPath -EnableException }
			catch {
				if ($aclDefinition.Optional) { continue }
				Write-PSFMessage -String 'Test-DMAcl.NoAccess' -StringValues $resolvedPath -Tag 'panic','failed' -Target $aclDefinition -ErrorRecord $_
				New-TestResult @resultDefaults -Type 'NoAccess'
				Continue
			}
			# Ensure Owner Name is present - may not always resolve
			$ownerSID = $aclObject.GetOwner([System.Security.Principal.SecurityIdentifier])
			if ($aclObject.Owner -and -not $ownerSID.AccountDomainSid) { Add-Member -InputObject $aclObject -MemberType NoteProperty -Name Owner2 -Value $aclObject.Owner }
			else {
				try { $domain = (Get-Domain @parameters -Sid $ownerSID.AccountDomainSid).DNSRoot }
				catch {
					Write-PSFMessage -String 'Test-DMAcl.OwnerDomainNotResolved' -StringValues $resolvedPath -Tag 'panic','failed' -Target $aclDefinition -ErrorRecord $_
					New-TestResult @resultDefaults -Type 'OwnerNotResolved'
					Continue
				}
				try { $ntaccount = Get-Principal @parameters -Sid $ownerSID -Domain $domain -OutputType NTAccount }
				catch {
					Write-PSFMessage -String 'Test-DMAcl.OwnerPrincipalNotResolved' -StringValues $resolvedPath -Tag 'panic','failed' -Target $aclDefinition -ErrorRecord $_
					New-TestResult @resultDefaults -Type 'OwnerNotResolved'
					Continue
				}
				Add-Member -InputObject $aclObject -MemberType NoteProperty -Name Owner2 -Value $ntaccount
			}

			[System.Collections.ArrayList]$changes = @()
			Compare-Property -Property Owner -Configuration $aclDefinition -ADObject $aclObject -Changes $changes -Resolve -ADProperty Owner2
			Compare-Property -Property NoInheritance -Configuration $aclDefinition -ADObject $aclObject -Changes $changes -ADProperty AreAccessRulesProtected

			if ($changes.Count) {
				New-TestResult @resultDefaults -Type Changed -Changed $changes.ToArray() -ADObject $aclObject
			}
		}
		#endregion processing configuration

		#region check if all ADObejcts are managed
		<#
		Object Types ignored:
		- Service Connection Point
		- RID Set
		- DFSR Settings objects
		- Computer objects
		Pre-defining domain controllers or other T0 servers and their meta-information objects would be an act of futility and probably harmful.
		#>
		$foundADObjects = foreach ($searchBase in (Resolve-ContentSearchBase @parameters -NoContainer)) {
			Get-ADObject @parameters -LDAPFilter '(&(objectCategory=*)(!(|(objectCategory=serviceConnectionPoint)(objectCategory=rIDSet)(objectCategory=msDFSR-LocalSettings)(objectCategory=msDFSR-Subscriber)(objectCategory=msDFSR-Subscription)(objectCategory=computer))))' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope
		}
		
		$resolvedConfiguredPaths = $script:acls.Values.Path | Resolve-String
		$resultDefaults = @{
			Server = $Server
			ObjectType = 'Acl'
		}

		foreach ($foundADObject in $foundADObjects) {
			if ($foundADObject.DistinguishedName -in $resolvedConfiguredPaths) { continue }
			
			New-TestResult @resultDefaults -Type ShouldManage -ADObject $foundADObject -Identity $foundADObject.DistinguishedName
		}
		#endregion check if all ADObejcts are managed
	}
}
