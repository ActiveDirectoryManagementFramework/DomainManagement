function Resolve-String {
	<#
		.SYNOPSIS
			Resolves a string, inserting all registered placeholders as appropriate.
		
		.DESCRIPTION
			Resolves a string, inserting all registered placeholders as appropriate.
			Use Register-DMNameMapping to configure your own replacements.
		
		.PARAMETER Text
			The string on which to perform the replacements.
	
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.

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
		$Text,

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

		$replacementScript = {
			param (
				[string]
				$Match
			)

			if ($Match -like "%!*%") {
				try { (Invoke-DMDomainData -Name $Match.Trim('%!') @parameters -EnableException).Data }
				catch { throw }
			}
			if ($script:nameReplacementTable[$Match]) { $script:nameReplacementTable[$Match] }
			else { $Match }
		}

		$pattern = $script:nameReplacementTable.Keys -join "|"
		if ($Server) { $pattern += '|{0}' -f ($script:domainDataScripts.Values.Placeholder -join "|") }
	}
	process {
		foreach ($textItem in $Text) {
			if (-not $textItem) { return $textItem }
			try { [regex]::Replace($textItem, $pattern, $replacementScript) }
			catch { throw }
		}
	}
}
