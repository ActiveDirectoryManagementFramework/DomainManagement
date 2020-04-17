function Test-DMOrganizationalUnit
{
	<#
		.SYNOPSIS
			Tests whether the configured OrganizationalUnit match a domain's configuration.
		
		.DESCRIPTION
			Tests whether the configured OrganizationalUnit match a domain's configuration.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.EXAMPLE
			PS C:\> Test-DMOrganizationalUnit

			Tests whether the configured OrganizationalUnits' state matches the current domain OrganizationalUnit setup.
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
		Assert-Configuration -Type OrganizationalUnits -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		#region Process Configured OUs
		:main foreach ($ouDefinition in $script:organizationalUnits.Values) {
			$resolvedDN = Resolve-String -Text $ouDefinition.DistinguishedName

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'OrganizationalUnit'
				Identity = $resolvedDN
				Configuration = $ouDefinition
			}

			if (-not $ouDefinition.Present) {
				if ($adObject = Get-ADOrganizationalUnit @parameters -LDAPFilter "(distinguishedName=$resolvedDN)" -Properties Description, nTSecurityDescriptor) {
					New-TestResult @resultDefaults -Type ShouldDelete -ADObject $adObject
				}
				continue main
			}
			
			#region Case: Does not exist
			if (-not (Test-ADObject @parameters -Identity $resolvedDN)) {
				$oldNamedOUs = foreach ($oldDN in ($ouDefinition.OldNames | Resolve-String)) {
					foreach ($adOrgUnit in (Get-ADOrganizationalUnit @parameters -LDAPFilter "(distinguishedName=$oldDN)" -Properties Description, nTSecurityDescriptor)) {
						$adOrgUnit
					}
				}

				switch (($oldNamedOUs | Measure-Object).Count) {
					#region Case: No old version present
					0
					{
						New-TestResult @resultDefaults -Type ConfigurationOnly
						continue main
					}
					#endregion Case: No old version present

					#region Case: One old version present
					1
					{
						New-TestResult @resultDefaults -Type Rename -ADObject $oldNamedOUs
						continue main
					}
					#endregion Case: One old version present

					#region Case: Too many old versions present
					default
					{
						New-TestResult @resultDefaults -Type MultipleOldOUs -ADObject $oldNamedOUs
						continue main
					}
					#endregion Case: Too many old versions present
				}
			}
			#endregion Case: Does not exist

			$adObject = Get-ADOrganizationalUnit @parameters -Identity $resolvedDN -Properties Description, nTSecurityDescriptor
			
			[System.Collections.ArrayList]$changes = @()
			Compare-Property -Property Description -Configuration $ouDefinition -ADObject $adObject -Changes $changes -Resolve

			if ($changes.Count) {
				New-TestResult @resultDefaults -Type Changed -Changed $changes.ToArray() -ADObject $adObject
			}
		}
		#endregion Process Configured OUs

		#region Process Managed Containers
		$foundOUs = foreach ($searchBase in (Resolve-ContentSearchBase @parameters -IgnoreMissingSearchbase)) {
			Get-ADOrganizationalUnit @parameters -LDAPFilter '(!(isCriticalSystemObject=*))' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope -Properties nTSecurityDescriptor | Where-Object DistinguishedName -Ne $searchBase.SearchBase
		}

		$resolvedConfiguredNames = $script:organizationalUnits.Values.DistinguishedName | Resolve-String

		$resultDefaults = @{
			Server = $Server
			ObjectType = 'OrganizationalUnit'
		}

		foreach ($existingOU in $foundOUs) {
			if ($existingOU.DistinguishedName -in $resolvedConfiguredNames) { continue } # Ignore configured OUs - they were previously configured for moving them, if they should not be in these containers
			
			New-TestResult @resultDefaults -Type ShouldDelete -ADObject $existingOU -Identity $existingOU.Name
		}
		#endregion Process Managed Containers
	}
}
