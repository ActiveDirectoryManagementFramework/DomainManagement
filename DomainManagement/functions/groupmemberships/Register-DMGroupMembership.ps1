function Register-DMGroupMembership
{
<#
	.SYNOPSIS
		Registers a group membership assignment as desired state.
	
	.DESCRIPTION
		Registers a group membership assignment as desired state.
		Any group with configured membership will be considered "managed" where memberships are concerned.
		This will causse all non-registered memberships to be configured for purging.
	
	.PARAMETER Name
		The name of the user or group to grant membership in the target group.
		This parameter also accepts SIDs instead of names.
		Note: %DomainSID% is the placeholder for the domain SID, %RootDomainSID% the one for the forest root domain.
	
	.PARAMETER Domain
		Domain the entity is from, that is being granted group membership.
	
	.PARAMETER ItemType
		The type of object being granted membership.
	
	.PARAMETER Group
		The group to define members for.
	
	.PARAMETER Empty
		Whether the specified group should be empty.
		By default, groups are only considered when at least one member has been defined.
		Flagging a group for being empty will clear all members from it.
	
	.PARAMETER Mode
		How the defined group membership will be processed:
		- Default:             Member must exist and be member of the group.
		- MayBeMember:         Principal must exist but may be a member. No add action will be generated if not a member, but also no remove action if it already is a member.
		- MemberIfExists:      If Principal exists, make it a member.
		- MayBeMemberIfExists: Both existence and membership are optional for this principal.
	
	.PARAMETER GroupProcessingMode
		Governs how ALL group memberships on the targeted group will be processed.
		Supported modes:
		- Constrained: Existing Group Memberships not defined will be removed
		- Additive: Group Memberships defined will be applied, but non-configured memberships will be ignored.
		If no setting is defined, it will default to 'Constrained'
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content $configPath | ConvertFrom-Json | Write-Output | Register-DMGroupMembership
		
		Imports all defined groupmemberships from the targeted json configuration file.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'Entry')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Entry')]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Entry')]
		[string]
		$Domain,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Entry')]
		[ValidateSet('User', 'Group', 'foreignSecurityPrincipal')]
		[string]
		$ItemType,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Entry')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Empty')]
		[string]
		$Group,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Empty')]
		[bool]
		$Empty,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Default', 'MayBeMember', 'MemberIfExists', 'MayBeMemberIfExists')]
		[string]
		$Mode = 'Default',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Constrained', 'Additive')]
		[string]
		$GroupProcessingMode,
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process
	{
		if (-not $script:groupMemberShips[$Group])
		{
			$script:groupMemberShips[$Group] = @{ }
		}
		if ($Name)
		{
			$script:groupMemberShips[$Group]["$($ItemType):$($Name)"] = [PSCustomObject]@{
				PSTypeName = 'DomainManagement.GroupMembership'
				Name	   = $Name
				Domain	   = $Domain
				ItemType   = $ItemType
				Group	   = $Group
				Mode	   = $Mode
				ContextName = $ContextName
			}
		}
		elseif ($Empty)
		{
			$script:groupMemberShips[$Group] = @{ }
		}
		
		if ($GroupProcessingMode)
		{
			$script:groupMemberShips[$Group]['__Configuration'] = [PSCustomObject]@{
				PSTypeName = 'DomainManagement.GroupMembership.Configuration'
				ProcessingMode = $GroupProcessingMode
			}
		}
	}
}
