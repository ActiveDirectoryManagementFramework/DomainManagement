function Get-DMGPRegistrySetting {
	<#
	.SYNOPSIS
		Returns the registered group policy registry settings.
	
	.DESCRIPTION
		Returns the registered group policy registry settings.
	
	.PARAMETER PolicyName
		The name of the policy to filter by.
	
	.PARAMETER Key
		Filter by the key affected.
	
	.PARAMETER ValueName
		Filter by the name of the value set.
	
	.EXAMPLE
		PS C:\> Get-DMGPRegistrySetting

		Returns all registered group policy registry settings.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$PolicyName = '*',

		[string]
		$Key = '*',

		[string]
		$ValueName = '*'
	)
	
	process {
		$script:groupPolicyRegistrySettings.Values | Where-Object {
			$_.PolicyName -like $PolicyName -and
			$_.Key -like $Key -and
			$_.ValueName -like $ValueName
		}
	}
}