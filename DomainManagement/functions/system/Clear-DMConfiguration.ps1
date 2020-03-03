function Clear-DMConfiguration
{
	<#
		.SYNOPSIS
			Clears the configuration, removing all registered settings.
		
		.DESCRIPTION
			Clears the configuration, removing all registered settings.
			Use this to clean up, e.g. when switching to a new configuration set.
		
		.EXAMPLE
			PS C:\> Clear-DMConfiguration

			Clears the configuration, removing all registered settings.
	#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		. "$script:ModuleRoot\internal\scripts\variables.ps1"
	}
}
