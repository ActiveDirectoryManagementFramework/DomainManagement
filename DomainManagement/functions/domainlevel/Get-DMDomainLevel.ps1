function Get-DMDomainLevel
{
<#
	.SYNOPSIS
		Returns the defined desired state if configured.
	
	.DESCRIPTION
		Returns the defined desired state if configured.
	
	.EXAMPLE
		PS C:\> Get-DMDomainLevel
	
		Returns the defined desired state if configured.
#>
	[CmdletBinding()]
	Param (
	
	)
	process
	{
		$script:domainLevel
	}
}
