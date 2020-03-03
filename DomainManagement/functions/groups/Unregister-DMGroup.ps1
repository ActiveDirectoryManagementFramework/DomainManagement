function Unregister-DMGroup
{
	<#
	.SYNOPSIS
		Removes a group that had previously been registered.
	
	.DESCRIPTION
		Removes a group that had previously been registered.
	
	.PARAMETER Name
		The name of the group to remove.
	
	.EXAMPLE
		PS C:\> Get-DMGroup | Unregister-DMGroup

		Clears all registered groups.
	#>
	
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameItem in $Name) {
			$script:groups.Remove($nameItem)
		}
	}
}
