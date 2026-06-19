function Get-DMAcl {
	<#
		.SYNOPSIS
			Lists registered acls.
		
		.DESCRIPTION
			Lists registered acls.
		
		.PARAMETER Path
			The name to filter by.
			Defaults to '*'
		
		.EXAMPLE
			PS C:\> Get-DMAcls

			Lists all registered acls.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Path = '*'
	)
	
	process {
		($script:acls.Values) | Where-Object Path -Like $Path
		($script:aclsByCategory.Values) | Where-Object Category -Like $Path
		$script:aclDefaultOwner | Where-Object Path -Like $Path
	}
}
