function Get-DMGPPermissionFilter
{
	<#
		.SYNOPSIS
			Lists the registered Group Policy permission filters.
			
		.DESCRIPTION
			Lists the registered Group Policy permission filters.

		.PARAMETER Name
			The name to filter by.
			Default: '*'

		.EXAMPLE
			PS C:\> Get-DMGPPermissionFilter

			Lists all registered Group Policy permission filters
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	
	process
	{
		($script:groupPolicyPermissionFilters.Values) | Where-Object Name -like $Name
	}
}
