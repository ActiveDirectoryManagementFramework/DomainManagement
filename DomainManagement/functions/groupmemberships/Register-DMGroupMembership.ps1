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
		$Empty
	)
	
	process
	{
		if (-not $script:groupMemberShips[$Group]) {
			$script:groupMemberShips[$Group] = @{ }
		}
		if ($Name) {
			$script:groupMemberShips[$Group]["$($ItemType):$($Name)"] = [PSCustomObject]@{
				PSTypeName = 'DomainManagement.GroupMembership'
				Name = $Name
				Domain = $Domain
				ItemType = $ItemType
				Group = $Group
			}
		}
		else {
			$script:groupMemberShips[$Group] = @{ }
		}
	}
}
