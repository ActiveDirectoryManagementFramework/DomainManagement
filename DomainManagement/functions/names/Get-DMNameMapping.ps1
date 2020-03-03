function Get-DMNameMapping
{
	<#
		.SYNOPSIS
			List the registered name mappings
		
		.DESCRIPTION
			List the registered name mappings
			Mapped names are used for stringr replacement when invoking domain configurations.
		
		.PARAMETER Name
			The name to filter by.
			Defaults to '*'
		
		.EXAMPLE
			PS C:\> Get-DMNameMapping

			List all registered mappings
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	
	process
	{
		foreach ($key in $script:nameReplacementTable.Keys) {
			if ($key -notlike $Name) { continue }

			[PSCustomObject]@{
				PSTypeName = 'DomainManagement.Name.Mapping'
				Name = $key
				Value = $script:nameReplacementTable[$key]
			}
		}
	}
}
