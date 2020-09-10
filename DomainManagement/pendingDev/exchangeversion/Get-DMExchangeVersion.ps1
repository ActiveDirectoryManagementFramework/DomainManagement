function Get-DMExchangeVersion
{
<#
	.SYNOPSIS
		Returns the defined Exchange domain configuration to apply.
	
	.DESCRIPTION
		Returns the defined Exchange domain configuration to apply.
	
	.EXAMPLE
		PS C:\> Get-DMExchangeVersion
	
		Returns the defined Exchange domain configuration to apply.
#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		$script:exchangeVersion
	}
}
