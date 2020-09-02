function Unregister-DMDomainLevel
{
<#
	.SYNOPSIS
		Removes the domain level configuration if present.
	
	.DESCRIPTION
		Removes the domain level configuration if present.
	
	.EXAMPLE
		PS C:\> Unregister-DMDomainLevel
	
		Removes the domain level configuration if present.
#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		$script:domainLevel = $null
	}
}
