Register-PSFTeppScriptblock -Name 'DomainManagement.GPPermissionFilter.Name' -ScriptBlock {
	(Get-DMGPPermissionFilter).Name
}
Register-PSFTeppArgumentCompleter -Command Get-DMGPPermissionFilter -Parameter Name -Name 'DomainManagement.GPPermissionFilter.Name'
Register-PSFTeppArgumentCompleter -Command Unregister-DMGPPermissionFilter -Parameter Name -Name 'DomainManagement.GPPermissionFilter.Name'