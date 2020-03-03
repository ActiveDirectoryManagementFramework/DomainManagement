function Unregister-DMNameMapping
{
	<#
	.SYNOPSIS
		Removes a registered name mapping.
	
	.DESCRIPTION
		Removes a registered name mapping.
		Mapped names are used for stringr replacement when invoking domain configurations.
	
	.PARAMETER Name
		The name(s) of the mapping to purge.
	
	.EXAMPLE
		PS C:\> Get-DMNameMapping | Unregister-DMNameMapping

		Removes all registered name mappings.
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
			$script:nameReplacementTable.Remove($nameItem)
		}
	}
}
