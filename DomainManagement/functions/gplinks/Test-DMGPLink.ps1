function Test-DMGPLink {
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
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type GroupPolicyLinks, GroupPolicyLinksDynamic -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters

		#region Utility Functions
		function Get-OUData {
			[CmdletBinding()]
			param (
				$Parameters
			)

			$ous = @{ }
			#region Explicit OUs
			foreach ($organizationalUnit in $script:groupPolicyLinks.Keys) {
				$resolvedOU = Resolve-String -Text $organizationalUnit
				$ous[$resolvedOU] = [PSCustomObject]@{
					OrganizationalUnit = $resolvedOU
					ProcessingMode     = 'Additive'	
					Include            = @()
					Exclude            = @()
					ExtendedInclude    = @()
				}
				$ous[$resolvedOU].Include = $script:groupPolicyLinks[$organizationalUnit].Values | Where-Object Present
				$ous[$resolvedOU].Exclude = $script:groupPolicyLinks[$organizationalUnit].Values | Where-Object Present -EQ $false
				if ($ous[$resolvedOU].Include.ProcessingMode -contains 'Constrained') {
					$ous[$resolvedOU].ProcessingMode = 'Constrained'
				}
			}
			#region Explicit OUs
			
			#region Filter-Based OUs
			foreach ($filter in $script:groupPolicyLinksDynamic.Keys) {
				$adObjects = Resolve-ADObject @Parameters -Filter (Resolve-String -Text $filter) -ObjectClass organizationalUnit
				$values = $script:groupPolicyLinksDynamic[$filter].Values
				
				foreach ($adObject in $adObjects) {
					if (-not $ous[$adObject.DistinguishedName]) {
						$ous[$adObject.DistinguishedName] = [PSCustomObject]@{
							OrganizationalUnit = $adObject.DistinguishedName
							ProcessingMode     = 'Additive'	
							Include            = @()
							Exclude            = @()
							ExtendedInclude    = @()
						}
					}
					$container = $ous[$adObject.DistinguishedName]
					$container.Include = $container.Include, $values | Remove-PSFNull -Enumerate | Where-Object Present
					$container.Exclude = $container.Exclude, $values | Remove-PSFNull -Enumerate | Where-Object Present -EQ $false
					if ($container.Include.ProcessingMode -contains 'Constrained') {
						$container.ProcessingMode = 'Constrained'
					}
				}
			}
			#endregion Filter-Based OUs
			
			$ous.Values
		}
		
		function New-Update {
			[CmdletBinding()]
			param (
				$PolicyName,
				$Status,
				$Action
			)

			[PSCustomObject]@{
				PSTypeName = 'DomainManagement.GPLink.Update'
				Action     = $Action
				Policy     = $PolicyName
				Status     = $Status
			}
		}
		
		function Get-LinkUpdate {
			[CmdletBinding()]
			param (
				$Configuration,
				$ADObject
			)

			$includeSorted = $Configuration.Include | Sort-Object @{ Expression = { $_.Tier }; Descending = $true }, Precedence | Where-Object PolicyName -NotIn $Configuration.Exclude.PolicyName
			$currentSorted = $ADObject.LinkedGroupPolicyObjects | Sort-Object Precedence

			if ($Configuration.ProcessingMode -eq 'Additive') {
				$currentAdditive = $ADObject.LinkedGroupPolicyObjects | Where-Object DisplayName -NotIn $includeSorted.PolicyName | Where-Object DisplayName -NotIn $Configuration.Exclude.PolicyName | Sort-Object Precedence | Add-Member -MemberType NoteProperty -Name Tier -Value 0 -PassThru -Force | Add-Member -MemberType AliasProperty -Name PolicyName -Value DisplayName -PassThru -Force
				$newDesiredState = @($currentAdditive) + @($includeSorted) | Write-Output | Remove-PSFNull | Sort-Object @{ Expression = { $_.Tier }; Descending = $true }, Precedence
			}
			else { $newDesiredState = $includeSorted }
			$Configuration.ExtendedInclude = $newDesiredState
				
			if (Compare-Array -ReferenceObject $newDesiredState.PolicyName -DifferenceObject $currentSorted.DisplayName -OrderSpecific -Quiet) {
				return
			}

			$index = 0
			foreach ($desired in $newDesiredState) {
				if ($currentSorted.DisplayName -notcontains $desired.PolicyName) {
					New-Update -Action Add -PolicyName $desired.PolicyName -Status 'Enabled'
					$index = $index + 1
					continue
				}
				if ($index -gt @($currentSorted).Count -or $desired.PolicyName -ne $currentSorted[$index].DisplayName) {
					New-Update -Action Reorder -PolicyName $desired.PolicyName -Status 'Enabled'
					$index = $index + 1
					continue
				}
				$index = $index + 1
			}
			foreach ($current in $currentSorted) {
				if ($current.DisplayName -notin $newDesiredState.PolicyName) {
					New-Update -Action Delete -PolicyName $current.DisplayName -Status $current.Status
				}
			}
		}
		#endregion Utility Functions

		$gpoDisplayToDN = @{ }
		$gpoDNToDisplay = @{ }
		foreach ($adPolicyObject in (Get-ADObject @parameters -LDAPFilter '(objectCategory=groupPolicyContainer)' -Properties DisplayName, DistinguishedName)) {
			$gpoDisplayToDN[$adPolicyObject.DisplayName] = $adPolicyObject.DistinguishedName
			$gpoDNToDisplay[$adPolicyObject.DistinguishedName] = $adPolicyObject.DisplayName
		}
	}
	process {
		#region Process Configuration
		$ouData = Get-OUData -Parameters $parameters
		foreach ($ouDatum in $ouData) {
			$resultDefaults = @{
				Server        = $Server
				ObjectType    = 'GPLink'
				Identity      = $ouDatum.OrganizationalUnit
				Configuration = $ouDatum
			}

			#region Handle AD Object doesn't exist
			try {
				$adObject = Get-ADObject @parameters -Identity $ouDatum.OrganizationalUnit -ErrorAction Stop -Properties gPLink, Name, DistinguishedName
				$resultDefaults['ADObject'] = $adObject
			}
			catch {
				Write-PSFMessage -String 'Test-DMGPLink.OUNotFound' -StringValues $ouDatum.OrganizationalUnit -ErrorRecord $_ -Tag 'panic', 'failed'
				New-TestResult @resultDefaults -Type 'MissingParent'
				Continue
			}
			#endregion Handle AD Object doesn't exist

			#region Handle AD Object does not contain any links
			$currentState = $adObject | ConvertTo-GPLink -PolicyMapping $gpoDNToDisplay
			Add-Member -InputObject $adObject -MemberType NoteProperty -Name LinkedGroupPolicyObjects -Value $currentState -Force
			if (-not $currentState) {
				New-TestResult @resultDefaults -Type 'New'
				continue
			}
			#endregion Handle AD Object does not contain any links

			$updates = Get-LinkUpdate -Configuration $ouDatum -ADObject $adObject
			if ($updates) {
				New-TestResult @resultDefaults -Type 'Update' -Changed $updates
			}
		}

		#region Process Managed Estate
		# OneLevel needs to be converted to base, as searching for OUs with "OneLevel" would return unmanaged OUs.
		# This search however is targeted at GPOs linked to managed OUs only.
		$translateScope = @{
			'Subtree'  = 'Subtree'
			'OneLevel' = 'Base'
			'Base'     = 'Base'
		}
		$adObjects = foreach ($searchBase in (Resolve-ContentSearchBase @parameters)) {
			Get-ADObject @parameters -LDAPFilter '(gPLink=*)' -SearchBase $searchBase.SearchBase -SearchScope $translateScope[$searchBase.SearchScope] -Properties gPLink, Name, DistinguishedName
		}

		foreach ($adObject in $adObjects) {
			# If we have a configuration on it, it has already been processed
			if ($adObject.DistinguishedName -in $ouData.OrganizationalUnit) { continue }
			if ([string]::IsNullOrWhiteSpace($adObject.GPLink)) { continue }

			$linkObjects = $adObject | ConvertTo-GPLink -PolicyMapping $gpoDNToDisplay
			Add-Member -InputObject $adObject -MemberType NoteProperty -Name LinkedGroupPolicyObjects -Value $linkObjects -Force

			$changes = foreach ($linkedObject in $linkObjects) {
				New-Update -PolicyName $linkedObject.DisplayName -Status $linkedObject.Status -Action Delete
			}
			New-TestResult -ObjectType GPLink -Type 'Delete' -Identity $adObject.DistinguishedName -Server $Server -ADObject $adObject -Changed $changes
		}
		#endregion Process Managed Estate
	}
}
