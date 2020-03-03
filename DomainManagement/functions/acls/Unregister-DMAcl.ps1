function Unregister-DMAcl
{
	<#
	.SYNOPSIS
		Removes a acl that had previously been registered.
	
	.DESCRIPTION
		Removes a acl that had previously been registered.
	
	.PARAMETER Path
		The path (distinguishedName) of the acl to remove.
	
	.EXAMPLE
		PS C:\> Get-DMAcl | Unregister-DMAcl

		Clears all registered acls.
	#>
	
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Path
	)
	
	process
	{
		foreach ($pathItem in $Path) {
			$script:acls.Remove($pathItem)
		}
	}
}
