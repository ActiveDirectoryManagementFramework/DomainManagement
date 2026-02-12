function Test-GPPermissionFilter {
	<#
		.SYNOPSIS
			Tests, whether a GP Permission Filter applies to a specific GPO.

		.DESCRIPTION
			Tests, whether a GP Permission Filter applies to a specific GPO.
			Used primarily by Test-DMGPPermission to resolve applicable permissions that have target selection through filters.

		.PARAMETER GpoName
			The name of the GPO that is tested against.

		.PARAMETER Filter
			The filter string the represents the condition on which it applies.

		.PARAMETER Conditions
			The list of filter conditions contained in the filter-string.
			These are processed/parsed out when registering the filter using Register-DMGPPermissionFilter.

		.PARAMETER FilterHash
			The hashtable mapping filter to list of GPOs that the filter applies to.

		.EXAMPLE
			PS C:\> Test-GPPermissionFilter -GpoName $permissionObject.Name -Filter $_.Filter -Conditions $_.FilterConditions -FilterHash $filterToGPOMapping

			Tests, whether a GP Permission Filter applies to the specified GPO.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '')]
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$GpoName,

		[Parameter(Mandatory = $true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]
		$Filter,

		[Parameter(Mandatory = $true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string[]]
		$Conditions,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$FilterHash
	)

	if (-not $GpoName) {
		Write-PSFMessage -Level Warning -String 'Test-GPPermissionFilter.Error.BadAdGpoConfiguration.DisplayName'
		return
	}

	if (-not $Filter.Trim()) { return $false }

	$testResults = @{ }
	foreach ($condition in $Conditions) {
		$testResults[$condition] = $FilterHash[$condition].DisplayName -contains $GpoName
	}

	$predicate = {
		param (
			$MatchInfo
		)

		"`$testResults['$($MatchInfo.Value)']"
	}
	$pattern = $Conditions -join "|"
	$resolvedFilter = [regex]::Replace($Filter, $pattern, $predicate)

	<#
	This is actually a safe operation:
	- The filter condition is tokenized and parsed for a very limited set of legal tokens (logical operators, parenthesis and filter names)
	- The filter names are constrained so that only letters, numbers and underscores can be used, making them safe for regex and injection purposes.
	These safety measures have been implemented in the parameter validations of Register-DMGPPermission and Register-DMGPPermissionFilter
	#>
	Invoke-Expression $resolvedFilter
}