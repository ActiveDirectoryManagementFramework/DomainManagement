function Unregister-DMExchange
{
<#
	.SYNOPSIS
		Clears the defined exchange domain configuration from the loaded configuration set.
	
	.DESCRIPTION
		Clears the defined exchange domain configuration from the loaded configuration set.
	
	.EXAMPLE
		PS C:\> Unregister-DMExchange
	
		Clears the defined exchange domain configuration from the loaded configuration set.
#>
	[CmdletBinding()]
	param (
		
	)
	
	process {
		$script:exchangeVersion = $null
	}
}
