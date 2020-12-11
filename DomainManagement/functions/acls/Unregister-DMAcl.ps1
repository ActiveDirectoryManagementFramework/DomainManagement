function Unregister-DMAcl
{
	<#
	.SYNOPSIS
		Removes a acl that had previously been registered.
	
	.DESCRIPTION
		Removes a acl that had previously been registered.
	
	.PARAMETER Path
		The path (distinguishedName) of the acl to remove.

	.PARAMETER Category
		The object category the acl settings apply to
	
	.EXAMPLE
		PS C:\> Get-DMAcl | Unregister-DMAcl

		Clears all registered acls.
	#>
	
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Path,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Category
	)
	
	process
	{
		foreach ($pathItem in $Path) {
			if ($pathItem -eq '<default>') { $script:aclDefaultOwner = $null }
			else { $script:acls.Remove($pathItem) }
		}
		foreach ($categoryItem in $Category) {
			$script:aclByCategory.Remove($categoryItem)
		}
	}
}
