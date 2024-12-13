function Unregister-DMGroupMembership
{
	<#
	.SYNOPSIS
		Removes entries from the list of desired group memberships.
	
	.DESCRIPTION
		Removes entries from the list of desired group memberships.
	
	.PARAMETER Name
		Name of the identity being granted group membership
	
	.PARAMETER ItemType
		The type of object the identity being granted group membership is.
	
	.PARAMETER Group
		The group being granted membership in.

	.PARAMETER ProcessingMode
		The processing mode to apply for the group's membership management.
	
	.EXAMPLE
		PS C:\> Get-DMGroupMembership | Unregister-DMGroupMembership

		Removes all configured desired group memberships.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
		[ValidateSet('User', 'Group', 'foreignSecurityPrincipal', 'Computer', '<Empty>')]
		[string]
		$ItemType,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Processing')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
		[string]
		$Group,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Processing')]
		[string]
		$ProcessingMode
	)
	
	process
	{
		if (-not $script:groupMemberShips[$Group]) { return }
		if ($ProcessingMode) {
			$null = $script:groupMemberShips[$Group].Remove('__Configuration')
			if (-not $script:groupMemberShips[$Group].Count) {
				$null = $script:groupMemberShips.Remove($Group)
			}
			return
		}
		if ($Name -eq '<empty>') {
			$null = $script:groupMemberShips.Remove($Group)
			return
		}
		if (-not $script:groupMemberShips[$Group]["$($ItemType):$($Name)"]) { return }
		$null = $script:groupMemberShips[$Group].Remove("$($ItemType):$($Name)")
		if (-not $script:groupMemberShips[$Group].Count) {
			$null = $script:groupMemberShips.Remove($Group)
		}
	}
}