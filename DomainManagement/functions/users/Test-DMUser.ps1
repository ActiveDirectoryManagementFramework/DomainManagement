function Test-DMUser
{
	<#
		.SYNOPSIS
			Tests whether the configured users match a domain's configuration.
		
		.DESCRIPTION
			Tests whether the configured users match a domain's configuration.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.EXAMPLE
			PS C:\> Test-DMUser

			Tests whether the configured users' state matches the current domain user setup.
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
		Assert-Configuration -Type Users -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		#region Process Configured Users
		:main foreach ($userDefinition in $script:users.Values) {
			$resolvedSamAccName = Resolve-String -Text $userDefinition.SamAccountName
			$resolvedName = Resolve-String -Text $userDefinition.Name

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'User'
				Identity = $resolvedSamAccName
				Configuration = $userDefinition
			}

			#region User that needs to be removed
			if (-not $userDefinition.Present) {
				try { $adObject = Get-ADUser @parameters -Identity $resolvedSamAccName -Properties Description, PasswordNeverExpires -ErrorAction Stop }
				catch { continue } # Only errors when user not present = All is well
				
				New-TestResult @resultDefaults -Type ShouldDelete -ADObject $adObject
				continue
			}
			#endregion User that needs to be removed

			#region Users that don't exist but should | Users that need to be renamed
			try { $adObject = Get-ADUser @parameters -Identity $resolvedSamAccName -Properties Description, PasswordNeverExpires -ErrorAction Stop }
			catch
			{
				$oldUsers = foreach ($oldName in ($userDefinition.OldNames | Resolve-String)) {
					try { Get-ADUser @parameters -Identity $oldName -Properties Description, PasswordNeverExpires -ErrorAction Stop }
					catch { }
				}

				switch (($oldUsers | Measure-Object).Count) {
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
						New-TestResult @resultDefaults -Type Rename -ADObject $oldUsers
						continue main
					}
					#endregion Case: One old version present

					#region Case: Too many old versions present
					default
					{
						New-TestResult @resultDefaults -Type MultipleOldUsers -ADObject $oldUsers
						continue main
					}
					#endregion Case: Too many old versions present
				}
			}
			#endregion Users that don't exist but should | Users that need to be renamed

			#region Existing Users, might need updates
			# $adObject contains the relevant object

			[System.Collections.ArrayList]$changes = @()
			Compare-Property -Property GivenName -Configuration $userDefinition -ADObject $adObject -Changes $changes -Resolve
			Compare-Property -Property Surname -Configuration $userDefinition -ADObject $adObject -Changes $changes -Resolve
			if ($null -ne $userDefinition.Description) { Compare-Property -Property Description -Configuration $userDefinition -ADObject $adObject -Changes $changes -Resolve }
			Compare-Property -Property PasswordNeverExpires -Configuration $userDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property UserPrincipalName -Configuration $userDefinition -ADObject $adObject -Changes $changes -Resolve
			Compare-Property -Property Name -Configuration $userDefinition -ADObject $adObject -Changes $changes -Resolve
			$ouPath = ($adObject.DistinguishedName -split ",",2)[1]
			if ($ouPath -ne (Resolve-String -Text $userDefinition.Path)) {
				$null = $changes.Add('Path')
			}
			if ($userDefinition.Enabled -ne "Undefined") {
				if ($adObject.Enabled -ne $userDefinition.Enabled) {
					$null = $changes.Add('Enabled')
				}
			}
			if ($changes.Count) {
				New-TestResult @resultDefaults -Type Changed -Changed $changes.ToArray() -ADObject $adObject
			}
			#endregion Existing Users, might need updates
		}
		#endregion Process Configured Users

		#region Process Managed Containers
		$foundUsers = foreach ($searchBase in (Resolve-ContentSearchBase @parameters)) {
			Get-ADUser @parameters -LDAPFilter '(!(isCriticalSystemObject=*))' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope
		}

		$resolvedConfiguredNames = $script:users.Values.SamAccountName | Resolve-String
		$exclusionPattern = $script:contentMode.UserExcludePattern -join "|"

		$resultDefaults = @{
			Server = $Server
			ObjectType = 'User'
		}

		foreach ($existingUser in $foundUsers) {
			if ($existingUser.SamAccountName -in $resolvedConfiguredNames) { continue } # Ignore configured users - they were previously configured for moving them, if they should not be in these containers
			if (1000 -ge ($existingUser.SID -split "-")[-1]) { continue } # Ignore BuiltIn default users
			if ($exclusionPattern -and $existingUser.Name -match $exclusionPattern) { continue } # Skip whitelisted usernames

			New-TestResult @resultDefaults -Type ShouldDelete -ADObject $existingUser -Identity $existingUser.Name
		}
		#endregion Process Managed Containers
	}
}
