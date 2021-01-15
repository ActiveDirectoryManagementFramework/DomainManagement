function Get-DMServiceAccount
{
<#
	.SYNOPSIS
		List the configured service accounts.
	
	.DESCRIPTION
		List the configured service accounts.
	
	.PARAMETER Name
		Name to filter by.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-DMServiceAccount
	
		List all configured service accounts.
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	process
	{
		($script:serviceAccounts.Values) | Where-Object Name -like $Name
	}
}
