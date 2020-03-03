function ConvertTo-FilterName {
	<#
		.SYNOPSIS
			Converts a GP permission filter string into a list of the names of conditions included in the filter.

		.DESCRIPTION
			Converts a GP permission filter string into a list of the names of conditions included in the filter.
			Deduplicates results.

		.PARAMETER Filter
			The filter to parse.

		.EXAMPLE
			C:\> ConvertTo-FilterName -Filter $Filter

			Converts the filter in $Filter into the deduplicated names of the conditions to apply.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Filter
	)

	$tokens = $null
	$errors = $null
	$null = [System.Management.Automation.Language.Parser]::ParseInput($Filter, [ref]$tokens, [ref]$errors)

	$tokens | Where-Object Kind -eq Identifier | Select-Object -ExpandProperty Text -Unique
}