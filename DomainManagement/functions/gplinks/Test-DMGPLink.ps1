function Test-DMGPLink
{
	<#
	.SYNOPSIS
		Tests, whether the configured group policy linking matches the desired state.
	
	.DESCRIPTION
		Tests, whether the configured group policy linking matches the desired state.
		Define the desired state using the Register-DMGPLink command.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMGPLink -Server contoso.com

		Tests, whether the group policy links of contoso.com match the configured state
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
		Assert-Configuration -Type GroupPolicyLinks -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		$gpoDisplayToDN = @{ }
		$gpoDNToDisplay = @{ }
		foreach ($adPolicyObject in (Get-ADObject @parameters -LDAPFilter '(objectCategory=groupPolicyContainer)' -Properties DisplayName, DistinguishedName)) {
			$gpoDisplayToDN[$adPolicyObject.DisplayName] = $adPolicyObject.DistinguishedName
			$gpoDNToDisplay[$adPolicyObject.DistinguishedName] = $adPolicyObject.DisplayName
		}

		#region Process Configuration
		foreach ($organizationalUnit in $script:groupPolicyLinks.Keys) {
			$resolvedName = Resolve-String -Text $organizationalUnit
			$desiredState = $script:groupPolicyLinks[$organizationalUnit].Values

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'GPLink'
				Identity = $resolvedName
				Configuration = $desiredState
			}
			
			try {
				$adObject = Get-ADObject @parameters -Identity $resolvedName -ErrorAction Stop -Properties gPLink, Name, DistinguishedName
				$resultDefaults['ADObject'] = $adObject
			}
			catch {
				Write-PSFMessage -String 'Test-DMGPLink.OUNotFound' -StringValues $resolvedName -ErrorRecord $_ -Tag 'panic','failed'
				New-TestResult @resultDefaults -Type 'MissingParent'
				Continue
			}

			$currentState = $adObject | ConvertTo-GPLink -PolicyMapping $gpoDNToDisplay
			Add-Member -InputObject $adObject -MemberType NoteProperty -Name LinkedGroupPolicyObjects -Value $currentState -Force
			if (-not $currentState) {
				New-TestResult @resultDefaults -Type 'New'
					continue
			}

			$currentStateFilteredSorted = $currentState | Where-Object Status -ne 'Disabled' | Sort-Object Precedence
			$currentStateSorted = $currentState | Sort-Object Precedence
			$desiredStateSorted = $desiredState | Sort-Object Precedence

			if (Compare-Array -ReferenceObject $currentStateFilteredSorted.DisplayName -DifferenceObject ($desiredStateSorted.PolicyName | Resolve-String) -Quiet -OrderSpecific) {
				if (Compare-Array -ReferenceObject $currentStateSorted.DisplayName -DifferenceObject ($desiredStateSorted.PolicyName | Resolve-String) -Quiet -OrderSpecific) { continue }
				else {
					New-TestResult @resultDefaults -Type 'UpdateDisabledOnly' -Changed ($currentStateSorted | Where-Object DisplayName -notin $desiredStateSorted.PolicyName)
					continue
				}
			}

			if ($currentStateSorted | Where-Object Status -eq 'Disabled') {
				New-TestResult @resultDefaults -Type 'UpdateSomeDisabled' -Changed ($currentStateSorted | Where-Object DisplayName -notin $desiredStateSorted.PolicyName)
				continue
			}

			New-TestResult @resultDefaults -Type 'Update' -Changed ($currentStateSorted | Where-Object DisplayName -notin $desiredStateSorted.PolicyName)
		}
		#endregion Process Configuration

		#region Process Managed Estate
		# OneLevel needs to be converted to base, as searching for OUs with "OneLevel" would return unmanaged OUs.
		# This search however is targeted at GPOs linked to managed OUs only.
		$translateScope = @{
			'Subtree' = 'Subtree'
			'OneLevel' = 'Base'
			'Base' = 'Base'
		}
		$configuredContainers = $script:groupPolicyLinks.Keys | Resolve-String
		$adObjects = foreach ($searchBase in (Resolve-ContentSearchBase @parameters)) {
			Get-ADObject @parameters -LDAPFilter '(gPLink=*)' -SearchBase $searchBase.SearchBase -SearchScope $translateScope[$searchBase.SearchScope] -Properties gPLink, Name, DistinguishedName
		}

		foreach ($adObject in $adObjects) {
			# If we have a configuration on it, it has already been processed
			if ($adObject.DistinguishedName -in $configuredContainers) { continue }
			if ([string]::IsNullOrWhiteSpace($adObject.GPLink)) { continue }

			$linkObjects = $adObject | ConvertTo-GPLink -PolicyMapping $gpoDNToDisplay
			Add-Member -InputObject $adObject -MemberType NoteProperty -Name LinkedGroupPolicyObjects -Value $linkObjects -Force
			if (-not ($linkObjects | Where-Object Status -eq Enabled)) {
				New-TestResult -ObjectType GPLink -Type 'DeleteDisabledOnly' -Identity $adObject.DistinguishedName -Server $Server -ADObject $adObject
				continue
			}
			elseif (-not ($linkObjects | Where-Object Status -eq Disabled)) {
				New-TestResult -ObjectType GPLink -Type 'Delete' -Identity $adObject.DistinguishedName -Server $Server -ADObject $adObject
				continue
			}
			New-TestResult -ObjectType GPLink -Type 'DeleteSomeDisabled' -Identity $adObject.DistinguishedName -Server $Server -ADObject $adObject
		}
		#endregion Process Managed Estate
	}
}
