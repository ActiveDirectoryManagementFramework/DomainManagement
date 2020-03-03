function Resolve-String
{
	<#
		.SYNOPSIS
			Resolves a string, inserting all registered placeholders as appropriate.
		
		.DESCRIPTION
			Resolves a string, inserting all registered placeholders as appropriate.
			Use Register-DMNameMapping to configure your own replacements.
		
		.PARAMETER Text
			The string on which to perform the replacements.

		.EXAMPLE
			PS C:\> Resolve-String -Text $_.GroupName

			Returns the resolved name of the input string (probably the finalized name of a new group to add).
	#>
	[OutputType([string])]
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[string[]]
		$Text
	)
	
	begin
	{
		$replacementScript = {
			param (
				[string]
				$Match
			)

			if ($script:nameReplacementTable[$Match]) { $script:nameReplacementTable[$Match] }
			else { $Match }
		}

		$pattern = $script:nameReplacementTable.Keys -join "|"
	}
	process
	{
		foreach ($textItem in $Text) {
			if (-not $textItem) { return $textItem}
			[regex]::Replace($textItem, $pattern, $replacementScript)
		}
	}
}
