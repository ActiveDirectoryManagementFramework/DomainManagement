function Unregister-DMObject
{
	<#
	.SYNOPSIS
		Unregisters a configured active directory objects.
	
	.DESCRIPTION
		Unregisters a configured active directory objects.
	
	.PARAMETER Identity
		The paths to the object to unregister.
		Requires the full, unresolved identity as dn (CN=<Name>,<Path>).
	
	.EXAMPLE
		PS C:\> Get-DMObject | Unregister-DMObject

		Clears all configured AD objects.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Identity
	)
	
	process
	{
		foreach ($pathString in $Identity) {
			$script:objects.Remove($pathString)
		}
	}
}