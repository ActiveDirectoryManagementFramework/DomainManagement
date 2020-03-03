function Get-DMPasswordPolicy
{
	<#
	.SYNOPSIS
		Returns the list of configured Finegrained Password policies defined as the desired state.
	
	.DESCRIPTION
		Returns the list of configured Finegrained Password policies defined as the desired state.
	
	.PARAMETER Name
		The name of the password policy to filter by.
	
	.EXAMPLE
		PS C:\> Get-DMPasswordPolicy

		Returns all defined PSO objects.
	#>
	
	[CmdletBinding()]
	param (
		[string]
		$Name = '*'
	)
	
	process
	{
		($script:passwordPolicies.Values | Where-Object Name -like $Name)
	}
}
