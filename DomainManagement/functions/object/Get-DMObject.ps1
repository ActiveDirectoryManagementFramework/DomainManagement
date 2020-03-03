function Get-DMObject
{
	<#
	.SYNOPSIS
		Returns configured active directory objects.
	
	.DESCRIPTION
		Returns configured active directory objects.
	
	.PARAMETER Path
		The path to filter by.

	.PARAMETER Name
		The name to filter by.
	
	.EXAMPLE
		PS C:\> Get-DMObject

		Returns all registered objects
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Path = '*',

		[string]
		$Name = '*'
	)
	
	process
	{
		($script:objects.Values | Where-Object Path -like $Path | Where-Object Name -like $Name)
	}
}