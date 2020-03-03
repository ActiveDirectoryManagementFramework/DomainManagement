function Unregister-DMAccessRule
{
	<#
	.SYNOPSIS
		Removes a registered accessrule from the list of desired rules.
	
	.DESCRIPTION
		Removes a registered accessrule from the list of desired rules.
	
	.PARAMETER RuleObject
		The rule object to remove.
		Must be returned by Get-DMAccessRule
	
	.EXAMPLE
		PS C:\> Get-DMAccessRule | Unregister-DMAccessRule

		Removes all registered Access Rules, clearing the desired state of rules.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[PsfValidateScript('DomainManagement.Validate.TypeName.AccessRule', ErrorString = 'DomainManagement.Validate.TypeName.AccessRule.Failed')]
		$RuleObject
	)
	
	process
	{
		foreach ($ruleItem in $RuleObject) {
			if ($ruleItem.Path) {
				$script:accessRules[$ruleItem.Path] = $script:accessRules[$ruleItem.Path] | Where-Object { $_ -ne $ruleItem}
				if (-not $script:accessRules[$ruleItem.Path]) {
					$script:accessRules.Remove($ruleItem.Path)
				}
			}
			if ($ruleItem.Category) {
				$script:accessCategoryRules[$ruleItem.Category] = $script:accessCategoryRules[$ruleItem.Category] | Where-Object { $_ -ne $ruleItem}
				if (-not $script:accessCategoryRules[$ruleItem.Category]) {
					$script:accessCategoryRules.Remove($ruleItem.Category)
				}
			}
		}
	}
}