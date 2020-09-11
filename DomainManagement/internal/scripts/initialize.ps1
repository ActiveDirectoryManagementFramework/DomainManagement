$PSDefaultParameterValues['Resolve-String:ModuleName'] = 'ADMF.Core'
$PSDefaultParameterValues['Register-StringMapping:ModuleName'] = 'ADMF.Core'
$PSDefaultParameterValues['Clear-StringMapping:ModuleName'] = 'ADMF.Core'
$PSDefaultParameterValues['Unregister-StringMapping:ModuleName'] = 'ADMF.Core'

Register-PSFCallback -Name DomainManagement.ConfigurationReset -ModuleName ADMF.Core -CommandName Clear-AdcConfiguration -ScriptBlock {
	Clear-DMConfiguration
}