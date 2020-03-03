function Unregister-DMPasswordPolicy
{
	<#
	.SYNOPSIS
		Remove a PSO from the list of desired PSOs that are applied to a domain.
	
	.DESCRIPTION
		Remove a PSO from the list of desired PSOs that are applied to a domain.
	
	.PARAMETER Name
		The name of the PSO to remove.
	
	.EXAMPLE
		PS C:\> Unregister-DMPasswordPolicy -Name "T0 Admin Policy"

		Removes the "T0 Admin Policy" policy.
	#>
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($entry in $Name) {
			$script:passwordPolicies.Remove($entry)
		}
	}
}
