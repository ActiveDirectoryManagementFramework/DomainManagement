function Get-CategoryBasedRules {
	<#
	.SYNOPSIS
		Returns all access rules applicable to an ad object via category rules.
	
	.DESCRIPTION
		Returns all access rules applicable to an ad object via category rules.
	
	.PARAMETER ADObject
		The AD Object for which to resolve access rules by category.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER ConvertNameCommand
		A steppable pipeline wrapping Convert-DMSchemaGuid converting to name.
	
	.PARAMETER ConvertGuidCommand
		A steppable pipeline wrapping Convert-DMSchemaGuid converting to guid.
	
	.EXAMPLE
		PS C:\> Get-CategoryBasedRules -ADObject $foundADObject @parameters -ConvertNameCommand $convertCmdName -ConvertGuidCommand $convertCmdGuid

		Returns all access rules applicable to $foundADObject via category rules.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$ADObject,

		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential,

		$ConvertNameCommand,

		$ConvertGuidCommand
	)

	$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ADObject, Server, Credential

	$resolvedCategories = Resolve-DMObjectCategory @parameters
	foreach ($resolvedCategory in $resolvedCategories) {
		foreach ($ruleObject in $script:accessCategoryRules[$resolvedCategory.Name]) {
			$objectTypeGuid = $ConvertGuidCommand.Process($ruleObject.ObjectType)[0]
			$objectTypeName = $ConvertNameCommand.Process($ruleObject.ObjectType)[0]
			$inheritedObjectTypeGuid = $ConvertGuidCommand.Process($ruleObject.InheritedObjectType)[0]
			$inheritedObjectTypeName = $ConvertNameCommand.Process($ruleObject.InheritedObjectType)[0]

			try { $identity = Resolve-Identity @parameters -IdentityReference $ruleObject.IdentityReference }
			catch { Stop-PSFFunction -String 'Convert-AccessRule.Identity.ResolutionError' -Target $ruleObject -ErrorRecord $_ -Continue }

			[PSCustomObject]@{
				PSTypeName = 'DomainManagement.AccessRule.Converted'
				IdentityReference = $identity
				AccessControlType = $ruleObject.AccessControlType
				ActiveDirectoryRights = $ruleObject.ActiveDirectoryRights
				InheritanceFlags = $ruleObject.InheritanceFlags
				InheritanceType = $ruleObject.InheritanceType
				InheritedObjectType = $inheritedObjectTypeGuid
				InheritedObjectTypeName = $inheritedObjectTypeName
				ObjectFlags = $ruleObject.ObjectFlags
				ObjectType = $objectTypeGuid
				ObjectTypeName = $objectTypeName
				PropagationFlags = $ruleObject.PropagationFlags
				Present = $ruleObject.Present
			}
		}
	}
}