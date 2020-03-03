function Get-DMGPPermission
{
	<#
		.SYNOPSIS
			Lists registered GP permission rules.

		.DESCRIPTION
			Lists registered GP permission rules.
			These represent the desired state for how access to Group Policy Objects should be configured.

		.PARAMETER GpoName
			The name of the GPO the rule was assigned to.

		.PARAMETER Identity
			The name of trustee receiving permissions.

		.PARAMETER Filter
			The filter string assigned to the access rule to return.

		.PARAMETER IsGlobal
			Only return rules that apply to ALL GPOs globally.

		.EXAMPLE
			PS C:\> Get-DMGPPermmission

			Returns all registered permissions.
	#>
	[CmdletBinding()]
	param (
		[string]
		$GpoName,

		[string]
		$Identity,

		[string]
		$Filter,

		[switch]
		$IsGlobal
	)
	
	process
	{
		$results = foreach ($rule in $script:groupPolicyPermissions.Values) {
			if ((Test-PSFParameterBinding -ParameterName GpoName) -and ($rule.GpoName -notlike $GpoName)) { continue }
			if ((Test-PSFParameterBinding -ParameterName Identity) -and ($rule.Identity -notlike $Identity)) { continue }
			if ((Test-PSFParameterBinding -ParameterName Filter) -and ($rule.Filter -notlike $Filter)) { continue }
			if ($IsGlobal -and -not $rule.All) { continue }

			$rule
		}
		$results
	}
}