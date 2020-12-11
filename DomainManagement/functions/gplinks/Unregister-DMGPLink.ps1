function Unregister-DMGPLink
{
	<#
	.SYNOPSIS
		Removes a group policy link from the configured desired state.
	
	.DESCRIPTION
		Removes a group policy link from the configured desired state.
	
	.PARAMETER PolicyName
		The name of the policy to unregister.
	
	.PARAMETER OrganizationalUnit
		The name of the organizational unit the policy should be unregistered from.

	.PARAMETER OUFilter
		The filter of the filterbased policy link to remove
	
	.EXAMPLE
		PS C:\> Get-DMGPLink | Unregister-DMGPLink

		Clears all configured Group policy links.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	param (
		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$PolicyName,

		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Path')]
		[Alias('OU')]
		[string]
		$OrganizationalUnit,

		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[string]
		$OUFilter
	)
	
	process
	{
		switch ($PSCmdlet.ParameterSetName) {
			'Path'
			{
				$script:groupPolicyLinks[$OrganizationalUnit].Remove($PolicyName)
				if ($script:groupPolicyLinks[$OrganizationalUnit].Keys.Count -lt 1) { $script:groupPolicyLinks.Remove($OrganizationalUnit) }
			}
			'Filter'
			{
				$script:groupPolicyLinksDynamic[$OUFilter].Remove($PolicyName)
				if ($script:groupPolicyLinksDynamic[$OUFilter].Keys.Count -lt 1) { $script:groupPolicyLinksDynamic.Remove($OUFilter) }
			}
		}
		
	}
}