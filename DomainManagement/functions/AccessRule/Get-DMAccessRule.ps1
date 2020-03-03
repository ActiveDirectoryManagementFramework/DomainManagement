function Get-DMAccessRule
{
	<#
	.SYNOPSIS
		Returns the list of configured access rules.
	
	.DESCRIPTION
		Returns the list of configured access rules.
		These access rules define the desired state where delegation in a domain is concerned.
		This is consumed by Test-DMAccessRule, see the help on that command for more details.
	
	.PARAMETER Identity
		The Identity to filter by.
		This allows swiftly filtering by who is being granted permission.
	
	.EXAMPLE
		PS C:\> Get-DMAccessRule

		Returns a list of all registered accessrules
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Identity = '*'
	)
	
	process
	{
		($script:accessRules.Values | Write-Output | Where-Object IdentityReference -like $Identity)
		($script:accessCategoryRules.Values | Write-Output | Where-Object IdentityReference -like $Identity)
	}
}
