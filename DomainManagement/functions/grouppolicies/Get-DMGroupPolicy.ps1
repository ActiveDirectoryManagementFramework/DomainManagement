function Get-DMGroupPolicy
{
	<#
	.SYNOPSIS
		Returns all registered GPO objects.
	
	.DESCRIPTION
		Returns all registered GPO objects.
		Thsi represents the _desired_ state, not any actual state.
	
	.PARAMETER Name
		The name to filter by.
	
	.EXAMPLE
		PS C:\> Get-DMGroupPolicy

		Returns all registered GPOs
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*'
	)
	
	process
	{
		($script:groupPolicyObjects.Values | Where-Object DisplayName -like $name)
	}
}
