function Get-DMAccessRuleMode
{
	<#
	.SYNOPSIS
		Retrieve registered AccessRule processing modes.
	
	.DESCRIPTION
		Retrieve registered AccessRule processing modes.
		These are used to define, how AccessRules will be processed.
	
	.PARAMETER Path
		Filter by the path the AccessRule processing mode applies to.
	
	.PARAMETER ObjectCategory
		Filter by the object category the AccessRule processing mode applies to.
	
	.EXAMPLE
		PS C:\> Get-DMAccessRuleMode

		List all registered AccessRule processing modes.
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Path = '*',

		[string]
		$ObjectCategory = '*'
	)
	
	process
	{
		$script:accessRuleMode.Values | Where-Object Path -like $Path | Where-Object ObjectCategory -like $ObjectCategory
	}
}
