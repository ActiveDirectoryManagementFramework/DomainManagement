function Test-DMGroup
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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
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
		Assert-Configuration -Type Groups -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		:main foreach ($groupDefinition in $script:groups.Values) {
			$resolvedName = Resolve-String -Text $groupDefinition.Name

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'Group'
				Identity = $resolvedName
				Configuration = $groupDefinition
			}

			#region Group that needs to be removed
			if (-not $groupDefinition.Present) {
				try { $adObject = Get-ADGroup @parameters -Identity $resolvedName -ErrorAction Stop }
				catch { continue } # Only errors when group not present = All is well
				
				New-TestResult @resultDefaults -Type ShouldDelete -ADObject $adObject
				continue
			}
			#endregion Group that needs to be removed

			#region Groups that don't exist but should | Groups that need to be renamed
			try { $adObject = Get-ADGroup @parameters -Identity $resolvedName -Properties Description -ErrorAction Stop }
			catch
			{
				$oldGroups = foreach ($oldName in ($groupDefinition.OldNames | Resolve-String)) {
					try { Get-ADGroup @parameters -Identity $oldName -Properties Description, PasswordNeverExpires -ErrorAction Stop }
					catch { }
				}

				switch (($oldGroups | Measure-Object).Count) {
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
						New-TestResult @resultDefaults -Type Rename -ADObject $oldGroups
						continue main
					}
					#endregion Case: One old version present

					#region Case: Too many old versions present
					default
					{
						New-TestResult @resultDefaults -Type MultipleOldGroups -ADObject $oldGroups
						continue main
					}
					#endregion Case: Too many old versions present
				}
			}
			#endregion Groups that don't exist but should | Groups that need to be renamed

			#region Existing Groups, might need updates
			# $adObject contains the relevant object

			[System.Collections.ArrayList]$changes = @()
			Compare-Property -Property Description -Configuration $groupDefinition -ADObject $adObject -Changes $changes -Resolve
			Compare-Property -Property Category -Configuration $groupDefinition -ADObject $adObject -Changes $changes -ADProperty GroupCategory
			Compare-Property -Property Scope -Configuration $groupDefinition -ADObject $adObject -Changes $changes -ADProperty GroupScope
			$ouPath = ($adObject.DistinguishedName -split ",",2)[1]
			if ($ouPath -ne (Resolve-String -Text $groupDefinition.Path)) {
				$null = $changes.Add('Path')
			}
			if ($changes.Count) {
				New-TestResult @resultDefaults -Type Changed -Changed $changes.ToArray() -ADObject $adObject
			}
			#endregion Existing Groups, might need updates
		}

		$foundGroups = foreach ($searchBase in (Resolve-ContentSearchBase @parameters)) {
			Get-ADGroup @parameters -LDAPFilter '(!(isCriticalSystemObject=*))' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope
		}

		$resolvedConfiguredNames = $script:groups.Values.Name | Resolve-String
		$resultDefaults = @{
			Server = $Server
			ObjectType = 'Group'
		}

		foreach ($existingGroup in $foundGroups) {
			if ($existingGroup.Name -in $resolvedConfiguredNames) { continue }
			if (1000 -ge ($existingGroup.SID -split "-")[-1]) { continue } # Ignore BuiltIn default groups

			New-TestResult @resultDefaults -Type ShouldDelete -ADObject $existingGroup -Identity $existingGroup.Name
		}
	}
}
