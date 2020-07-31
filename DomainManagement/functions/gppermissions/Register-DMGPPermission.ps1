function Register-DMGPPermission {
	<#
	.SYNOPSIS
		Registers a GP permission as the desired state.
	
	.DESCRIPTION
		Registers a GP permission as the desired state.

		Permissions can be applied in three ways:
		- Explicitly to a specific GPO
		- To ALL GPOs
		- To GPOs that match a specific filter string.

		For defining filter conditions, see the help on Register-DMGPPermissionFilter.

		Another important concept is the "Managed" concept.
		By default, all GPOs are considered unmanaged, where GP Permissions are concerned.
		This means, any additional permissionss that have been applied are ok.
		By setting a GPO's permissions under management - by applying a permission rule that uses the -Managed parameter - any permissions not defined for it will be removed.
	
	.PARAMETER GpoName
		Name of the GPO this permission applies to.
		Subject to string insertion.
	
	.PARAMETER Filter
		The filter condition governing, what GPOs these permissions apply to.
		A filter string can consist of the following elements:
		- Names of filter conditions
		- Logical operators
		- Parenthesis

		Example filter strings:
		- 'IsManaged'
		- 'IsManaged -and -not (IsDomainDefault -or IsDomainControllerDefault)'
		- '-not (IsManaged) -and (IsTier1 -or IsSupport)'
	
	.PARAMETER All
		This access rule applies to ALL GPOs.
	
	.PARAMETER Identity
		The group or user to assign permissions to.
		Subject to string insertion.
	
	.PARAMETER ObjectClass
		What kind of object the assigned identity is.
		Can be any legal object class in AD.
		Only object classes that have a SID should be chosen though (otherwise, assigning permissions to it gets kind of difficult).
	
	.PARAMETER Permission
		What kind of permission to grant.
	
	.PARAMETER Deny
		Whether to create a Deny rule, rather than an Allow rule.

	.PARAMETER NoPermissionChange
		Disable application of a set of permissions.
		Setting this flag allows defining a rule that only applies the "Managed" state (see below).
	
	.PARAMETER Managed
		Whether the affected GPOs should be considered "Under Management".
		A GPO "Under Management" will have all non-defined permissions removed.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\gpopermissions.json | ConvertFrom-Json | Write-Output | Register-DMGPPermission

		Reads all settings from the provided json file and registers them.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Explicit')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ExplicitNoChange')]
		[string]
		$GpoName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FilterNoChange')]
		[PsfValidateScript('DomainManagement.Validate.GPPermissionFilter', ErrorString = 'DomainManagement.Validate.GPPermissionFilter')]
		[string]
		$Filter,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AllNoChange')]
		[switch]
		$All,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Explicit')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[PsfValidateScript('DomainManagement.Validate.Identity',  ErrorString = 'DomainManagement.Validate.Identity')]
		[string]
		$Identity,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Explicit')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[string]
		$ObjectClass,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Explicit')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[ValidateSet('GpoApply', 'GpoRead', 'GpoEdit', 'GpoEditDeleteModifySecurity', 'GpoCustom')]
		[string]
		$Permission,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Explicit')]
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[switch]
		$Deny,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ExplicitNoChange')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FilterNoChange')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AllNoChange')]
		[switch]
		$NoPermissionChange,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[switch]
		$Managed,

		[string]
		$ContextName = '<Undefined>'
	)
	
	begin {
		$allowHash = @{
			$false = "Allow"
			$true  = "Deny"
		}
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Explicit' {
				$permIdentity = 'Explicit|{0}|{1}|{2}|{3}' -f $GpoName, $Identity, $Permission, $allowHash[$Deny.ToBool()]

				$script:groupPolicyPermissions[$permIdentity] = [PSCustomObject]@{
					PSTypeName         = 'DomainManagement.Configuration.GPPermission'
					PermissionIdentity = $permIdentity
					Type               = $PSCmdlet.ParameterSetName
					GpoName            = $GpoName
					Identity           = $Identity
					ObjectClass        = $ObjectClass
					Permission         = $Permission
					Deny               = $Deny.ToBool()
					Managed            = $Managed.ToBool()
					ContextName        = $ContextName
				}
			}
			'Filter' {
				$permIdentity = 'Filter|{0}|{1}|{2}|{3}' -f $Filter, $Identity, $Permission, $allowHash[$Deny.ToBool()]

				$script:groupPolicyPermissions[$permIdentity] = [PSCustomObject]@{
					PSTypeName         = 'DomainManagement.Configuration.GPPermission'
					PermissionIdentity = $permIdentity
					Type               = $PSCmdlet.ParameterSetName
					Filter             = $Filter
					FilterConditions   = (ConvertTo-FilterName -Filter $Filter)
					Identity           = $Identity
					ObjectClass        = $ObjectClass
					Permission         = $Permission
					Deny               = $Deny.ToBool()
					Managed            = $Managed.ToBool()
					ContextName        = $ContextName
				}
			}
			'All' {
				$permIdentity = 'All|{0}|{1}|{2}' -f $Identity, $Permission, $allowHash[$Deny.ToBool()]

				$script:groupPolicyPermissions[$permIdentity] = [PSCustomObject]@{
					PSTypeName         = 'DomainManagement.Configuration.GPPermission'
					PermissionIdentity = $permIdentity
					Type               = $PSCmdlet.ParameterSetName
					All                = $true
					Identity           = $Identity
					ObjectClass        = $ObjectClass
					Permission         = $Permission
					Deny               = $Deny.ToBool()
					Managed            = $Managed.ToBool()
					ContextName        = $ContextName
				}
			}
			'ExplicitNoChange' {
				$permIdentity = 'NoChange|Explicit|{0}' -f $GpoName

				$script:groupPolicyPermissions[$permIdentity] = [PSCustomObject]@{
					PSTypeName         = 'DomainManagement.Configuration.GPPermission'
					PermissionIdentity = $permIdentity
					Type               = $PSCmdlet.ParameterSetName
					GpoName            = $GpoName
					Managed            = $Managed.ToBool()
					ContextName        = $ContextName
				}
			}
			'FilterNoChange' {
				$permIdentity = 'NoChange|Filter|{0}' -f $Filter
				$script:groupPolicyPermissions[$permIdentity] = [PSCustomObject]@{
					PSTypeName         = 'DomainManagement.Configuration.GPPermission'
					PermissionIdentity = $permIdentity
					Type               = $PSCmdlet.ParameterSetName
					Filter             = $Filter
					FilterConditions   = (ConvertTo-FilterName -Filter $Filter)
					Managed            = $Managed.ToBool()
					ContextName        = $ContextName
				}
			}
			'AllNoChange' {
				$script:groupPolicyPermissions['NoChange|All'] = [PSCustomObject]@{
					PSTypeName         = 'DomainManagement.Configuration.GPPermission'
					PermissionIdentity = 'NoChange|All'
					Type               = $PSCmdlet.ParameterSetName
					All                = $true
					Managed            = $Managed.ToBool()
					ContextName        = $ContextName
				}
			}
		}
	}
}