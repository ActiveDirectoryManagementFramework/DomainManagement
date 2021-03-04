function Get-DMExchange
{
<#
	.SYNOPSIS
		Returns the defined Exchange domain configuration to apply.
	
	.DESCRIPTION
		Returns the defined Exchange domain configuration to apply.
	
	.EXAMPLE
		PS C:\> Get-DMExchange
	
		Returns the defined Exchange domain configuration to apply.
#>
	[CmdletBinding()]
	param (
		
	)
	
	process {
		$script:exchangeVersion
	}
}
