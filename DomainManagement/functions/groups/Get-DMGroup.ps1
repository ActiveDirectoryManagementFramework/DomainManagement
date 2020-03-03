function Get-DMGroup
{
	<#
		.SYNOPSIS
			Lists registered ad groups.
		
		.DESCRIPTION
			Lists registered ad groups.
		
		.PARAMETER Name
			The name to filter by.
			Defaults to '*'
		
		.EXAMPLE
			PS C:\> Get-DMGroup

			Lists all registered ad groups.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*'
	)
	
	process
	{
		($script:groups.Values | Where-Object Name -like $Name)
	}
}
