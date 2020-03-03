function Unregister-DMGPPermissionFilter
{
	<#
	.SYNOPSIS
		Removes a GP Permission Filter.
	
	.DESCRIPTION
		Removes a GP Permission Filter.
	
	.PARAMETER Name
		The name of the filter to remove.
	
	.EXAMPLE
		PS C:\> Get-DMGPPermissionFilter | Unregister-DMGPPermissionFilter

		Removes all registered GP Permission Filter.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($filterName in $Name) {
			$script:groupPolicyPermissionFilters.Remove($filterName)
		}
	}
}
