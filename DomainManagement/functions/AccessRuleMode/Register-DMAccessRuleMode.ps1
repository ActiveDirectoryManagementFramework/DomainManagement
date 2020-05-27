function Register-DMAccessRuleMode {
	<#
	.SYNOPSIS
		Register the processing mode for access rules on a specified object.
	
	.DESCRIPTION
		Register the processing mode for access rules on a specified object.
		This is used by the AccessRule Component exclusively.
	
	.PARAMETER Path
		The path to the AD object to govern.
		This should be a distinguishedname.
		This path uses name resolution.
		For example %DomainDN% will be replaced with the DN of the target domain itself (and should probably be part of everyy single path).
	
	.PARAMETER PathMode
		Whether to only target a specific path or the target path and all items beneath it.
	
	.PARAMETER ObjectCategory
		Instead of a path, define a category to apply the processing mode to.
		Categories are defined using Register-DMObjectCategory.
		This allows you to apply processing mode to a category of objects, rather than a specific path.
		With this you could apply a processing mode to all domain controller objects, for example.
	
	.PARAMETER Mode
		Determines, how the AccessRules are applied on the target object:
		- Constrained: All non-defined AccessRules will be removed.
		- Additive: Non-defined AccessRules on the targeted object will be ignored.
		By default, with no AccessRuleMode defined, all objects are considered to be in Constrained mode.
	
	.EXAMPLE
		PS C:\> Register-DMAccessRuleMode -Path 'OU=Company,%DomainDN%' -PathMode SubTree -Mode Additive

		Configures the specified OU and all items beneath it to be in additive mode.
		Defined AccessRules will be applied if missing, but previously existing rules remain untouched.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Path')]
		[string]
		$Path,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Path')]
		[ValidateSet('SingleItem', 'SubTree')]
		[string]
		$PathMode = 'SingleItem',

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Category')]
		[string]
		$ObjectCategory,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Constrained', 'Additive')]
		[string]
		$Mode
	)
	
	process {
		$identity = 'Path:{0}:{1}' -f $PathMode,$Path
		if ($ObjectCategory) { $identity = 'Category:{0}' -f $ObjectCategory }
		
		$script:accessRuleMode[$identity] = [PSCustomObject]@{
			PSTypeName     = 'DomainManagement.AccessRuleMode'
			Identity       = $identity
			Type           = $PSCmdlet.ParameterSetName
			Path           = $Path
			PathMode       = $PathMode
			ObjectCategory = $ObjectCategory
			Mode           = $Mode
		}
	}
}
