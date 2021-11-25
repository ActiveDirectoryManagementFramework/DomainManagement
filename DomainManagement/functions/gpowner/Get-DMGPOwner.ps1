function Get-DMGPOwner
{
	<#
	.SYNOPSIS
		Returns the list of defined group policy ownerships.
	
	.DESCRIPTION
		Returns the list of defined group policy ownerships.
		This represents the _desired_ state in your domain, not the one that actually pertains.
	
	.PARAMETER GpoName
		The name of the by which to filter.
	
	.PARAMETER Identity
		The identity reference to be made owner.
	
	.PARAMETER Filter
		The actual filter logic that determines, whether a policy should be affected by the given rule.
	
	.PARAMETER IsGlobal
		Only return the global / default owner setting
	
	.EXAMPLE
		PS C:\> Get-DMGPOwner

		Returns all configured GP ownerships
	#>
	[CmdletBinding()]
	Param (
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
		$results = foreach ($rule in $script:groupPolicyOwners.Values) {
			if ((Test-PSFParameterBinding -ParameterName GpoName) -and ($rule.GpoName -notlike $GpoName)) { continue }
			if ((Test-PSFParameterBinding -ParameterName Identity) -and ($rule.Identity -notlike $Identity)) { continue }
			if ((Test-PSFParameterBinding -ParameterName Filter) -and ($rule.Filter -notlike $Filter)) { continue }
			if ($IsGlobal -and -not $rule.All) { continue }

			$rule
		}
		$results
	}
}
