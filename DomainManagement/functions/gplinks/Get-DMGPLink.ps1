function Get-DMGPLink
{
	<#
	.SYNOPSIS
		Returns the list of registered group policy links.
	
	.DESCRIPTION
		Returns the list of registered group policy links.
		Use Register-DMGPLink to register new group policy links.
	
	.PARAMETER PolicyName
		The name of the GPO to filter by.
	
	.PARAMETER OrganizationalUnit
		The name of the OU the GPO is assigned to.
	
	.EXAMPLE
		PS C:\> Get-DMGPLink

		Returns all registered GPLinks
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	param (
		[string]
		$PolicyName = '*',
		
		[string]
		$OrganizationalUnit = '*'
	)
	
	process
	{
		($script:groupPolicyLinks.Values.Values) | Where-Object {
			($_.PolicyName -like $PolicyName) -and ($_.OrganizationalUnit -like $OrganizationalUnit)
		}
		($script:groupPolicyLinksDynamic.Values.Values) | Where-Object {
			($_.PolicyName -like $PolicyName) -and ($_.OrganizationalUnit -like $OrganizationalUnit)
		}
	}
}
