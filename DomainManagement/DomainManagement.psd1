@{
	# Script module or binary module file associated with this manifest
	RootModule         = 'DomainManagement.psm1'
	
	# Version number of this module.
	ModuleVersion      = '1.9.210'
	
	# ID used to uniquely identify this module
	GUID               = '0a405382-ebc2-445b-8325-541535810193'
	
	# Author of this module
	Author             = 'Friedrich Weinmann'
	
	# Company or vendor of this module
	CompanyName        = 'Microsoft'
	
	# Copyright statement for this module
	Copyright          = 'Copyright (c) 2019 Friedrich Weinmann'
	
	# Description of the functionality provided by this module
	Description        = 'Module to manage domain configuration'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion  = '5.1'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules    = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.12.346' }
		
		# Additional Dependencies, cannot declare due to bug in dependency handling in PS5.1
		# @{ ModuleName = 'ADSec'; ModuleVersion = '1.0.0' }
		# @{ ModuleName = 'ResolveString'; ModuleVersion = '1.0.0' }
		# @{ ModuleName = 'ADMF.Core'; ModuleVersion = '1.1.6' }
	)
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @('bin\DomainManagement.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\DomainManagement.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess   = @('xml\DomainManagement.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport  = @(
		'Clear-DMConfiguration'
		'Convert-DMSchemaGuid'
		'Find-DMObjectCategoryItem'
		'Get-DMAccessRule'
		'Get-DMAccessRuleMode'
		'Get-DMAcl'
		'Get-DMCallback'
		'Get-DMContentMode'
		'Get-DMDomainCredential'
		'Get-DMDomainData'
		'Get-DMDomainLevel'
		'Get-DMExchange'
		'Get-DMGPLink'
		'Get-DMGPOwner'
		'Get-DMGPPermission'
		'Get-DMGPPermissionFilter'
		'Get-DMGPRegistrySetting'
		'Get-DMGroup'
		'Get-DMGroupMembership'
		'Get-DMGroupPolicy'
		'Get-DMNameMapping'
		'Get-DMObject'
		'Get-DMObjectCategory'
		'Get-DMObjectDefaultPermission'
		'Get-DMOrganizationalUnit'
		'Get-DMPasswordPolicy'
		'Get-DMServiceAccount'
		'Get-DMUser'
		'Get-DMWmiFilter'
		'Invoke-DMAccessRule'
		'Invoke-DMAcl'
		'Invoke-DMDomainData'
		'Invoke-DMDomainLevel'
		'Invoke-DMExchange'
		'Invoke-DMGPLink'
		'Invoke-DMGPOwner'
		'Invoke-DMGPPermission'
		'Invoke-DMGroup'
		'Invoke-DMGroupMembership'
		'Invoke-DMGroupPolicy'
		'Invoke-DMObject'
		'Invoke-DMOrganizationalUnit'
		'Invoke-DMPasswordPolicy'
		'Invoke-DMServiceAccount'
		'Invoke-DMUser'
		'Invoke-DMWmiFilter'
		'Register-DMAccessRule'
		'Register-DMAccessRuleMode'
		'Register-DMAcl'
		'Register-DMBuiltInSID'
		'Register-DMCallback'
		'Register-DMDomainData'
		'Register-DMDomainLevel'
		'Register-DMExchange'
		'Register-DMGPLink'
		'Register-DMGPOwner'
		'Register-DMGPPermission'
		'Register-DMGPPermissionFilter'
		'Register-DMGPRegistrySetting'
		'Register-DMGroup'
		'Register-DMGroupMembership'
		'Register-DMGroupPolicy'
		'Register-DMNameMapping'
		'Register-DMObject'
		'Register-DMObjectCategory'
		'Register-DMOrganizationalUnit'
		'Register-DMPasswordPolicy'
		'Register-DMServiceAccount'
		'Register-DMUser'
		'Register-DMWmiFilter'
		'Reset-DMDomainCredential'
		'Resolve-DMAccessRuleMode'
		'Resolve-DMObjectCategory'
		'Set-DMContentMode'
		'Set-DMDomainContext'
		'Set-DMDomainCredential'
		'Set-DMRedForestContext'
		'Test-DMAccessRule'
		'Test-DMAcl'
		'Test-DMDomainLevel'
		'Test-DMExchange'
		'Test-DMGPLink'
		'Test-DMGPOwner'
		'Test-DMGPPermission'
		'Test-DMGPRegistrySetting'
		'Test-DMGroup'
		'Test-DMGroupMembership'
		'Test-DMGroupPolicy'
		'Test-DMObject'
		'Test-DMOrganizationalUnit'
		'Test-DMPasswordPolicy'
		'Test-DMServiceAccount'
		'Test-DMUser'
		'Test-DMWmiFilter'
		'Unregister-DMAccessRule'
		'Unregister-DMAccessRuleMode'
		'Unregister-DMAcl'
		'Unregister-DMCallback'
		'Unregister-DMDomainData'
		'Unregister-DMDomainLevel'
		'Unregister-DMExchange'
		'Unregister-DMGPLink'
		'Unregister-DMGPOwner'
		'Unregister-DMGPPermission'
		'Unregister-DMGPPermissionFilter'
		'Unregister-DMGPRegistrySetting'
		'Unregister-DMGroup'
		'Unregister-DMGroupMembership'
		'Unregister-DMGroupPolicy'
		'Unregister-DMNameMapping'
		'Unregister-DMObject'
		'Unregister-DMObjectCategory'
		'Unregister-DMOrganizationalUnit'
		'Unregister-DMPasswordPolicy'
		'Unregister-DMServiceAccount'
		'Unregister-DMUser'
		'Unregister-DMWmiFilter'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport    = ''
	
	# Variables to export from this module
	VariablesToExport  = ''
	
	# Aliases to export from this module
	AliasesToExport    = ''
	
	# List of all modules packaged with this module
	ModuleList         = @()
	
	# List of all files packaged with this module
	FileList           = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData        = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags         = @('activedirectory', 'domain', 'admf')
			
			# A URL to the license for this module.
			LicenseUri   = 'https://github.com/ActiveDirectoryManagementFramework/DomainManagement/blob/master/LICENSE'
			
			# A URL to the main website for this project.
			ProjectUri   = 'https://admf.one'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/ActiveDirectoryManagementFramework/DomainManagement/blob/master/DomainManagement/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}