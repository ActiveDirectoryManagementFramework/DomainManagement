function Unregister-DMGPRegistrySetting
{
	<#
	.SYNOPSIS
		Removes defined group policy registry settings.
	
	.DESCRIPTION
		Removes defined group policy registry settings.
	
	.PARAMETER PolicyName
		The name of the GPO the registry setting has been applied to.
	
	.PARAMETER Key
		The registry key affected.
	
	.PARAMETER ValueName
		The name of the value this applies to.
	
	.EXAMPLE
		PS C:\> Get-DMGPRegistrySetting | Unregister-DMGPRegistrySetting

		Clears all defined group policy registry settings.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$PolicyName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Key,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ValueName
	)
	
	process
	{
		$identity = $PolicyName, $Key, $ValueName -join "þ"
		$script:groupPolicyRegistrySettings.Remove($identity)
	}
}
