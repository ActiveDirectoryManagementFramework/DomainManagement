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
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
			[CmdletBinding()]
			param (
				$PolicyName,
				$Status,
				$Action,
				$Identity
			)

			$update = [PSCustomObject]@{
				PSTypeName = 'DomainManagement.GPLink.Update'
				Action     = $Action
				Policy     = $PolicyName
				Status     = $Status
				Identity   = $Identity
			}
			Add-Member -InputObject $update -MemberType ScriptMethod -Name ToString -Value {
				'{0}: {1}' -f $this.Action, $this.Policy
			} -Force -PassThru
		}
		
		function ConvertTo-LinkConfigWithState {
			<#
			.SYNOPSIS
				Convert config object to new object and match it with the state of the current item.
			#>
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$LinkObject,

				[AllowNull()]
				$CurrentLinks,

				[hashtable]
				$GpoDisplayToDN = @{ }
			)

			process {
				foreach ($linkItem in $LinkObject) {
					if (-not $linkItem) { continue }
					$currentLink = $CurrentLinks | Where-Object DisplayName -EQ $linkItem.PolicyName

					$itemHash = $linkItem | ConvertTo-PSFHashtable
					$itemHash.PSTypeName = 'DomainManagement.GPLink'
					$itemHash.StateValid = ($linkItem.State -eq $currentLink.Status) -or ($currentLink -and $linkItem.State -eq 'Undefined')
					$itemHash.CurrentState = $currentLink.Status
					$itemHash.PolicyName = $itemHash.PolicyName | Resolve-String
					$itemHash.DistinguishedName = $GpoDisplayToDN[$itemHash.PolicyName]

					$object = [PSCustomObject]$itemHash

					Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value {
						switch ($this.State) {
							'Enabled' { $this.PolicyName }
							'Disabled' { '~|{0}' -f $this.PolicyName }
							'Enforced' { '*|{0}' -f $this.PolicyName }
						}
					} -Force
					Add-Member -InputObject $object -MemberType ScriptMethod -Name ToLink -Value {
						# [LDAP://cn={F4A6ADB1-BEDE-497D-901F-F24B19394951},cn=policies,cn=system,DC=contoso,DC=com;0][LDAP://cn={2036B9B6-D5C1-4756-B7AB-8291A9B26521},cn=policies,cn=system,DC=contoso,DC=com;0]
						$statusLabel = $this.State
						if ($statusLabel -eq 'Undefined' -and $this.CurrentState) { $statusLabel = $this.CurrentState }
						elseif ($statusLabel -eq 'Undefined') { $statusLabel = 'Enabled' }

						$status = switch ($statusLabel) {
							'Enabled' { "0" }
							'Disabled' { "1" }
							'Enforced' { "2" }
						}
						'[LDAP://{0};{1}]' -f $this.DistinguishedName, $status
					}

					$object
				}
			}
		}

		function ConvertFrom-ADLink {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$LinkObject
			)
			process {
				foreach ($object in $LinkObject) {
					$objectHash = $object | ConvertTo-PSFHashtable
					$objectHash.Tier = 0
					$objectHash.PolicyName = $objectHash.DisplayName
					$objectHash.StateValid = $true
					$objectHash.CurrentState = $objectHash.Status
					$objectHash.State = $objectHash.Status

					$item = [PSCustomObject]$objectHash

					Add-Member -InputObject $item -MemberType ScriptMethod -Name ToString -Value {
						switch ($this.Status) {
							'Enabled' { $this.DisplayName }
							'Disabled' { '~|{0}' -f $this.DisplayName }
							'Enforced' { '*|{0}' -f $this.DisplayName }
						}
					} -Force
					Add-Member -InputObject $item -MemberType ScriptMethod -Name ToLink -Value {
						# [LDAP://cn={F4A6ADB1-BEDE-497D-901F-F24B19394951},cn=policies,cn=system,DC=contoso,DC=com;0][LDAP://cn={2036B9B6-D5C1-4756-B7AB-8291A9B26521},cn=policies,cn=system,DC=contoso,DC=com;0]
						$status = '0'
						if ($this.Status -eq 'Disabled') { $status = '1' }
						if ($this.Status -eq 'Enforced') { $status = '2' }
						'[LDAP://{0};{1}]' -f $this.DistinguishedName, $status
					}

					$item
				}
			}
		}

		function Get-LinkUpdate {
			[CmdletBinding()]
			param (
				$Configuration,
				$ADObject,
				$GpoDisplayToDN
			)

			$currentSorted = $ADObject.LinkedGroupPolicyObjects | Sort-Object Precedence
			$includeSorted = $Configuration.Include | Sort-Object @{ Expression = { $_.Tier }; Descending = $true }, Precedence | Where-Object PolicyName -NotIn $Configuration.Exclude.PolicyName | ConvertTo-LinkConfigWithState -CurrentLinks $currentSorted -GpoDisplayToDN $GpoDisplayToDN

			if ($Configuration.ProcessingMode -eq 'Additive') {
				$currentAdditive = $ADObject.LinkedGroupPolicyObjects | Where-Object DisplayName -NotIn $includeSorted.PolicyName | Where-Object DisplayName -NotIn $Configuration.Exclude.PolicyName | Sort-Object Precedence | ConvertFrom-ADLink
				$newDesiredState = @($currentAdditive) + @($includeSorted) | Write-Output | Remove-PSFNull | Sort-Object @{ Expression = { $_.Tier }; Descending = $true }, Precedence
			}
			else { $newDesiredState = $includeSorted }
			$Configuration.ExtendedInclude = $newDesiredState
			
			$orderCorrect = Compare-Array -ReferenceObject $newDesiredState.PolicyName -DifferenceObject $currentSorted.DisplayName -OrderSpecific -Quiet
			if ($orderCorrect -and $newDesiredState.StateValid -notcontains $false) {
				return
			}

			$index = 0
			foreach ($desired in $newDesiredState) {
				if ($currentSorted.DisplayName -notcontains $desired.PolicyName) {
					if ($desired.DistinguishedName) {
						New-Update -Action Add -PolicyName $desired.PolicyName -Status 'Enabled' -Identity $ADObject.DistinguishedName
					}
					else {
						New-Update -Action GpoMissing -PolicyName $desired.PolicyName -Status 'Enabled' -Identity $ADObject.DistinguishedName
					}
					$index = $index + 1
					continue
				}
				if ($index -gt @($currentSorted).Count -or $desired.PolicyName -ne $currentSorted[$index].DisplayName) {
					New-Update -Action Reorder -PolicyName $desired.PolicyName -Status 'Enabled' -Identity $ADObject.DistinguishedName
					$index = $index + 1
					continue
				}
				if (-not $desired.StateValid) {
					New-Update -Action State -PolicyName $desired.PolicyName -Status $desired.State -Identity $ADObject.DistinguishedName
					$index = $index + 1
					continue
				}
				$index = $index + 1
			}
			foreach ($current in $currentSorted) {
				if ($current.DisplayName -notin $newDesiredState.PolicyName) {
					New-Update -Action Delete -PolicyName $current.DisplayName -Status $current.Status -Identity $ADObject.DistinguishedName
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
				$updates = foreach ($includedLink in $ouDatum.Include) {
					New-Update -Action Create -PolicyName $includedLink.PolicyName -Status $includedLink.State -Identity $ouDatum.OrganizationalUnit
				}
				New-TestResult @resultDefaults -Type 'Create' -Changed $updates
				continue
			}
			#endregion Handle AD Object does not contain any links

			$updates = Get-LinkUpdate -Configuration $ouDatum -ADObject $adObject -GpoDisplayToDN $gpoDisplayToDN
			if ($updates) {
				New-TestResult @resultDefaults -Type 'Update' -Changed ($updates | Sort-Object {
						if ($_.Action -eq "Delete") { 0 }
						elseif ($_.Action -eq "Reorder") { 1 }
						else { 2 }
					})
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
				New-Update -PolicyName $linkedObject.DisplayName -Status $linkedObject.Status -Action Delete -Identity $adObject.DistinguishedName
			}
			New-TestResult -ObjectType GPLink -Type 'Delete' -Identity $adObject.DistinguishedName -Server $Server -ADObject $adObject -Changed $changes
		}
		#endregion Process Managed Estate
	}
}