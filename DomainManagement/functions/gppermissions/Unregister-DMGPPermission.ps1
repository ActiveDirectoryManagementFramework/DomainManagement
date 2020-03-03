function Unregister-DMGPPermission
{
	<#
	.SYNOPSIS
		Removes a registered GP Permission.
	
	.DESCRIPTION
		Removes a registered GP Permission.
	
	.PARAMETER PermissionIdentity
		The identity string of a GP permission.
		This is NOT the user/group assigned permission (Identity property) but instead the unique identifier of the permission setting (PermissionIdentity property).
	
	.EXAMPLE
		PS C:\> Get-DMGPPermission | Unregister-DMGPPermission

		Clear all defined configuration.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
		[string[]]
		$PermissionIdentity
	)
	
	process
	{
		foreach ($identityString in $PermissionIdentity) {
			$script:groupPolicyPermissions.Remove($identityString)
		}
	}
}
