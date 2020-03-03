function Get-DMCallback
{
	<#
	.SYNOPSIS
		Returns the list of registered callbacks.
	
	.DESCRIPTION
		Returns the list of registered callbacks.

		For more details on this system, call:
		Get-Help about_DM_callbacks
	
	.PARAMETER Name
		The name of the callback.
		Supports wildcard filtering.
	
	.EXAMPLE
		PS C:\> Get-DMCallback

		Returns a list of all registered callbacks
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	
	process
	{
		$script:callbacks.Values | Where-Object Name -like $Name
	}
}
