function Test-DMWmiFilter {
	<#
	.SYNOPSIS
		Tests, whether the WMI Filter conform to the desired state
	
	.DESCRIPTION
		Tests, whether the WMI Filter conform to the desired state
		
		Use Register-DMWmiFilter to define the desired state.
		Use Invoke-DMWmiFilter to bring the target domain into the desired state.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMWmiFilter -Server contoso.com

		Checks whether the "contoso.com"-domain's WMI filters are in the desired state.
	#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		#region Utility Functions
		function Compare-WmiFilter {
			[CmdletBinding()]
			param (
				$Configuration,

				$ADFilters,

				[Hashtable]
				$Parameters
			)

			$tresult = @{
				ObjectType    = 'WmiFilter'
				Identity      = $Configuration.Name
				Server        = $Parameters.Server
				Configuration = $Configuration
			}

			if ($Configuration.Name -notin $ADFilters.Name) {
				New-TestResult @tresult -Type Create
				return
			}
			$adFilter = $ADFilters | Where-Object Name -EQ $Configuration.Name | Select-Object -First 1
			$tresult.ADObject = $adFilter

			$changes = [System.Collections.ArrayList]::new()
			$compare = @{
				Configuration = $Configuration
				ADObject      = $adFilter
				Changes       = $changes
				AsUpdate      = $true
				Type          = 'WmiFilter'
			}
			Compare-Property @compare -Property Author
			Compare-Property @compare -Property Description -Resolve
			Compare-Property @compare -Property CreatedOn -ADProperty CreationDate

			#region Compare WMI Filter Conditions
			#region Verify whether all intended queries are already applied
			foreach ($query in $Configuration.Query) {
				if ($adFilter.Query | Where-Object { $_.Query -eq $query.Query -and $_.Namespace -eq $query.Namespace }) {
					continue
				}
				$change = New-Change -Property Query -OldValue $adFilter.Query -NewValue $Configuration.Query -Identity $Configuration.name -Type WmiFilter
				$changes.Add($change)
				break
			}
			#endregion Verify whether all intended queries are already applied

			#region Check for extra queries in existing WMI Filter
			if ($changes.Property -notcontains 'Query') {
				foreach ($query in $adFilter.Query) {
					if ($Configuration.Query | Where-Object { $_.Query -eq $query.Query -and $_.Namespace -eq $query.Namespace }) {
						continue
					}
					$change = New-Change -Property Query -OldValue $adFilter.Query -NewValue $Configuration.Query -Identity $Configuration.name -Type WmiFilter
					$changes.Add($change)
					break
				}
			}
			#endregion Check for extra queries in existing WMI Filter
			#endregion Compare WMI Filter Conditions

			if ($changes.Count -lt 1) { return }

			New-TestResult @tresult -Type Update -Changed $changes
		}
		#endregion Utility Functions

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type wmifilter -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		$adWmiFilter = Get-ADWmiFilter @parameters
		$configWmiFilter = Get-DMWmiFilter

		foreach ($filter in $configWmiFilter) {
			Compare-WmiFilter -Configuration $filter -ADFilters $adWmiFilter -Parameters $parameters
		}

		#region Process Undefined WmiFilters that exist in AD
		if (-not $script:contentMode.RemoveUnknownWmiFilter) { return }

		foreach ($filter in $adWmiFilter) {
			if ($filter.Name -in $configWmiFilter.Name) { continue }

			New-TestResult -ObjectType WmiFilter -Type Delete -Identity $filter.Name -Server $Server -ADObject $filter
		}
		#endregion Process Undefined WmiFilters that exist in AD
	}
}
