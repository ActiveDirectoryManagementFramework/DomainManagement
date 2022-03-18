function Resolve-GPFilterMapping {
	<#
	.SYNOPSIS
		Determines which filter conditions apply to which GPO
	
	.DESCRIPTION
		Determines which filter conditions apply to which GPO
		Used by components that apply rules based on GPOs, such as GP Permissions and GP Ownership.
	
	.PARAMETER Conditions
		The list of conditions that need to be evaluated.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Resolve-GPFilterMapping @parameters -Conditions ($ownerConfig.FilterConditions | Remove-PSFNull -Enumerate | Sort-Object -Unique)

		Returns a mapping of which of the conditions needed and what GPOs they apply to.
	#>
	[CmdletBinding()]
	param (
		[AllowEmptyCollection()]
		[string[]]
		$Conditions,

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)

	process {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

		$result = [PSCustomObject]@{
			Success          = $true
			Mapping          = @{ }
			Conditions       = $Conditions
			AllGpos = @()
			MissingCondition = $null
			ErrorType        = 'None'
			ErrorData        = @()
			ErrorTarget      = $null
		}

		$allFilters = @{ }
		foreach ($filterObject in Get-DMGPPermissionFilter) {
			$allFilters[$filterObject.Name] = $filterObject
		}

		$result.MissingCondition = $Conditions | Where-Object { $_ -notin $allFilters.Keys }
		if ($result.MissingCondition) {
			$result.ErrorType = 'MissingCondition'
			$result.Success = $false
			$result
			return
		}

		if ($Conditions) { $relevantFilters = $allFilters | ConvertTo-PSFHashtable -Include $Conditions }
		else { $relevantFilters = @() }

		$allGpos = Get-ADObject @parameters -LDAPFilter '(objectCategory=groupPolicyContainer)' -Properties DisplayName
		$result.AllGpos = $allGpos
		$filterToGPOMapping = @{ }
		$managedGPONames = (Get-DMGroupPolicy).DisplayName | Resolve-String
		#region Process individual filter conditions
		:conditions foreach ($condition in $relevantFilters.Values) {
			switch ($condition.Type) {
				#region Managed - Do we define the policy using the GroupPolicy Component?
				'Managed' {
					if ($condition.Reverse -xor (-not $condition.Managed)) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -NotIn $managedGPONames }
					else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -In $managedGPONames }
				}
				#endregion Managed - Do we define the policy using the GroupPolicy Component?

				#region Path - Resolve by where GPOs are linked
				'Path' {
					$searchBase = Resolve-String -Text $condition.Path
					if (-not (Test-ADObject @parameters -Identity $searchBase)) {
						if ($condition.Optional) {
							Write-PSFMessage -String 'Resolve-GPFilterMapping.Filter.Path.DoesNotExist.SilentlyContinue' -StringValues $Condition.Name, $searchBase -Target $condition
							continue conditions
						}
						$result.Success = $false
						$result.ErrorType = 'PathNotFound'
						$result.ErrorData = $searchBase
						$result.ErrorTarget = $condition
						$result
						return
					}

					$objects = Get-ADObject @parameters -SearchBase $searchBase -SearchScope $condition.Scope -LDAPFilter '(|(objectCategory=OrganizationalUnit)(objectCategory=domainDNS))' -Properties gPLink
					$allLinkedGpoDNs = $objects | ConvertTo-GPLink | Select-Object -ExpandProperty DistinguishedName -Unique
					if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DistinguishedName -NotIn $allLinkedGpoDNs }
					else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DistinguishedName -In $allLinkedGpoDNs }
				}
				#endregion Path - Resolve by where GPOs are linked

				#region GPName - Match by name, using either direct comparison, wildcard or regex
				'GPName' {
					$resolvedGpoName = Resolve-String -Text $condition.GPName
					switch ($condition.Mode) {
						'Explicit' {
							if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -NE $resolvedGpoName }
							else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -EQ $resolvedGpoName }
						}
						'Wildcard' {
							if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -NotLike $resolvedGpoName }
							else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -Like $resolvedGpoName }
						}
						'Regex' {
							if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -NotMatch $resolvedGpoName }
							else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -Match $resolvedGpoName }
						}
					}
				}
				#endregion GPName - Match by name, using either direct comparison, wildcard or regex
			}
		}
		#endregion Process individual filter conditions
		$result.Mapping = $filterToGPOMapping
		$result
	}
}