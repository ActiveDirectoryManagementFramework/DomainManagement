function Unregister-DMAccessRuleMode
{
	<#
	.SYNOPSIS
		Removes previously registered AccessRule processing modes.
	
	.DESCRIPTION
		Removes previously registered AccessRule processing modes.
		Prioritizes Identity over Path over ObjectCategory.
	
	.PARAMETER Identity
		The Identity of the AccessRule processing mode to remove.
	
	.PARAMETER Path
		The Path of the AccessRule processing mode to remove.
	
	.PARAMETER ObjectCagegory
		The ObjectCategory of the AccessRule processing mode to remove.
	
	.EXAMPLE
		PS C:\> Get-DMAccessRuleMode | Unregister-DMAccessRuleMode

		Clears all registered AccessRule processing modes.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Identity,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Path,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$ObjectCagegory
	)
	
	process
	{
		if ($Identity) { $script:accessRuleMode.Remove($Identity) }
		elseif ($Path) { $script:accessRuleMode.Remove("Path:$Path") }
		elseif ($ObjectCagegory) { $script:accessRuleMode.Remove("Category:$ObjectCategory") }
	}
}
