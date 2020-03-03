Register-PSFTeppScriptblock -Name 'DomainManagement.GPPermission.GpoName' -ScriptBlock {
	(Get-DMGPPermission).GpoName
}
Register-PSFTeppScriptblock -Name 'DomainManagement.GPPermission.Identity' -ScriptBlock {
	(Get-DMGPPermission).Identity
}
Register-PSFTeppScriptblock -Name 'DomainManagement.GPPermission.Filter' -ScriptBlock {
	(Get-DMGPPermission).Filter
}

Register-PSFTeppArgumentCompleter -Command Get-DMGPPermission -Parameter GpoName -Name 'DomainManagement.GPPermission.GpoName'
Register-PSFTeppArgumentCompleter -Command Get-DMGPPermission -Parameter Identity -Name 'DomainManagement.GPPermission.Identity'
Register-PSFTeppArgumentCompleter -Command Get-DMGPPermission -Parameter Filter -Name 'DomainManagement.GPPermission.Filter'