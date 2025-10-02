function Register-DMAccessRule {
	<#
	.SYNOPSIS
		Registers a new access rule as a desired state.
	
	.DESCRIPTION
		Registers a new access rule as a desired state.
		These are then compared with a domain's configuration when executing Test-DMAccessRule.
		See that command for more details on this procedure.
	
	.PARAMETER Path
		The path to the AD object to govern.
		This should be a distinguishedname.
		This path uses name resolution.
		For example %DomainDN% will be replaced with the DN of the target domain itself (and should probably be part of everyy single path).
	
	.PARAMETER ObjectCategory
		Instead of a path, define a category to apply the rule to.
		Categories are defined using Register-DMObjectCategory.
		This allows you to apply rules to a category of objects, rather than a specific path.
		With this you could apply a rule to all domain controller objects, for example.
	
	.PARAMETER Identity
		The identity to apply the rule to.
		Use the string '<Parent>' to apply the rule to the parent object of the object affected by this rule.
	
	.PARAMETER AccessControlType
		Whether this is an Allow or Deny rule.
	
	.PARAMETER ActiveDirectoryRights
		The actual rights to grant.
		This is a [string] type to allow some invalid values that happen in the field and are still applied by AD.
	
	.PARAMETER InheritanceType
		How the Access Rule is being inherited.
		None: Indicates no inheritance. The ACE information is only used on the object on which the ACE is set. ACE information is not inherited by any descendents of the object.
		All: Indicates inheritance that includes the object to which the ACE is applied, the object's immediate children, and the descendents of the object's children.
		Descendents: Indicates inheritance that includes the object's immediate children and the descendants of the object's children, but not the object itself.
		SelfAndChildren: Indicates inheritance that includes the object itself and its immediate children. It does not include the descendents of its children.
		Children: Indicates inheritance that includes the object's immediate children only, not the object itself or the descendents of its children.
	
	.PARAMETER InheritedObjectType
		Name or Guid of property or right affected by this rule.
		Access Rules are governed by ObjectType and InheritedObjectType to affect what objects to affect (e.g. Computer, User, ...),
		what properties to affect (e.g.: User-Account-Control) or what extended rights to grant.
		Which in what combination applies depends on the ActiveDirectoryRights set.
	
	.PARAMETER ObjectType
		Name or Guid of property or right affected by this rule.
		Access Rules are governed by ObjectType and InheritedObjectType to affect what objects to affect (e.g. Computer, User, ...),
		what properties to affect (e.g.: User-Account-Control) or what extended rights to grant.
		Which in what combination applies depends on the ActiveDirectoryRights set.

	.PARAMETER Optional
		The path this access rule object is assigned to is optional and need not exist.
		This makes the rule apply only if the object exists, without triggering errors if it doesn't.
		It will also ignore access errors on the object.
		Note: Only if all access rules assigned to an object are set to $true, will the object be considered optional.

    .PARAMETER Present
		Whether the access rule should exist or not.
		By default, it should.
		Set this to $false in order to explicitly delete an existing access rule.
        Set this to 'Undefined' to neither create nor delete it, in which case it will simply be accepted if it exists.
	
	.PARAMETER NoFixConfig
		By default, Test-DMAccessRule will generate a "FixConfig" result for accessrules that have been explicitly defined but are also part of the Schema Default permissions.
		If this setting is enabled, this result object is suppressed.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.

	.EXAMPLE
		PS C:\> Register-DMAccessRule -ObjectCategory DomainControllers -Identity '%DomainName%\Domain Admins' -ActiveDirectoryRights GenericAll

		Grants the domain admins of the target domain FullControl over all domain controllers, without any inheritance.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Path')]
		[string]
		$Path,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Category')]
		[string]
		$ObjectCategory,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Identity,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ActiveDirectoryRights,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[System.Security.AccessControl.AccessControlType]
		$AccessControlType = 'Allow',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[System.DirectoryServices.ActiveDirectorySecurityInheritance]
		$InheritanceType = 'None',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$ObjectType = '<All>',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$InheritedObjectType = '<All>',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Optional = $false,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[PSFramework.Utility.TypeTransformationAttribute([string])]
		[DomainManagement.TriBool]
		$Present = 'true',

		[bool]
		$NoFixConfig = $false,

		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Path' {
				if (-not $script:accessRules[$Path]) { $script:accessRules[$Path] = @() }
				$script:accessRules[$Path] += [PSCustomObject]@{
					PSTypeName            = 'DomainManagement.AccessRule'
					Path                  = $Path
					IdentityReference     = $Identity
					AccessControlType     = $AccessControlType
					ActiveDirectoryRights = $ActiveDirectoryRights
					InheritanceType       = $InheritanceType
					InheritedObjectType   = $InheritedObjectType
					ObjectType            = $ObjectType
					Optional              = $Optional
					Present               = $Present
					NoFixConfig           = $NoFixConfig
					ContextName           = $ContextName
				}
			}
			'Category' {
				if (-not $script:accessCategoryRules[$ObjectCategory]) { $script:accessCategoryRules[$ObjectCategory] = @() }
				$script:accessCategoryRules[$ObjectCategory] += [PSCustomObject]@{
					PSTypeName            = 'DomainManagement.AccessRule'
					Category              = $ObjectCategory
					IdentityReference     = $Identity
					AccessControlType     = $AccessControlType
					ActiveDirectoryRights = $ActiveDirectoryRights
					InheritanceType       = $InheritanceType
					InheritedObjectType   = $InheritedObjectType
					ObjectType            = $ObjectType
					Optional              = $Optional
					Present               = $Present
					NoFixConfig           = $NoFixConfig
					ContextName           = $ContextName
				}
			}
		}
	}
}
