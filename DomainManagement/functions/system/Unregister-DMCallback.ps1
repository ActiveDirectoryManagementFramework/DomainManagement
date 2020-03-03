function Unregister-DMCallback
{
	<#
	.SYNOPSIS
		Removes a callback from the list of registered callbacks.
	
	.DESCRIPTION
		Removes a callback from the list of registered callbacks.

		For more details on this system, call:
		Get-Help about_DM_callbacks
	
	.PARAMETER Name
		The name of the callback to remove.
	
	.EXAMPLE
		PS C:\> Get-DMCallback | Unregister-DMCallback

		Unregisters all callback scriptblocks that have been registered.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameItem in $Name) {
			$script:callbacks.Remove($nameItem)
		}
	}
}
