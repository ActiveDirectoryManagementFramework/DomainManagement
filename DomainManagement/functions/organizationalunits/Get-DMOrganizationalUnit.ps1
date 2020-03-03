function Get-DMOrganizationalUnit
{
	<#
	.SYNOPSIS
		Returns the list of configured Organizational Units.
	
	.DESCRIPTION
		Returns the list of configured Organizational Units.
		Does not in any way retrieve data from a domain.
		The returned list of OUs represent the desired state for each domain of the current context.
	
	.PARAMETER Name
		Name of the OU to filter by.
	
	.PARAMETER Path
		Path of the OU to filter by.
	
	.EXAMPLE
		PS C:\> Get-DMOrganizationalUnit

		Return all configured OUs.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*',

		[string]
		$Path = '*'
	)
	
	process
	{
		($script:organizationalUnits.Values | Where-Object Name -like $Name | Where-Object Path -like $Path)
	}
}
