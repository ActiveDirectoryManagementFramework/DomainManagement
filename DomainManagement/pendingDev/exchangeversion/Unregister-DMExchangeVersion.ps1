function Unregister-DMExchangeVersion
{
<#
	.SYNOPSIS
		Clears the defined exchange domain configuration from the loaded configuration set.
	
	.DESCRIPTION
		Clears the defined exchange domain configuration from the loaded configuration set.
	
	.EXAMPLE
		PS C:\> Unregister-DMExchangeVersion
	
		Clears the defined exchange domain configuration from the loaded configuration set.
#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		$script:exchangeVersion = $null
	}
}
