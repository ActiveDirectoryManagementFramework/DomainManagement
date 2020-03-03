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
	
	.EXAMPLE
		PS C:\> Get-DMGPLink | Unregister-DMGPLink

		Clears all configured Group policy links.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$PolicyName,

		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('OU')]
		[string]
		$OrganizationalUnit
	)
	
	process
	{
		$script:groupPolicyLinks[$OrganizationalUnit].Remove($PolicyName)
		if ($script:groupPolicyLinks[$OrganizationalUnit].Keys.Count -lt 1) { $script:groupPolicyLinks.Remove($OrganizationalUnit) }
	}
}