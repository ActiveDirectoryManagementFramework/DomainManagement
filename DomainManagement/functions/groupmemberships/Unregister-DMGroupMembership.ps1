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
	
	.EXAMPLE
		PS C:\> Get-DMGroupMembership | Unregister-DMGroupMembership

		Removes all configured desired group memberships.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('User', 'Group', 'foreignSecurityPrincipal', '<Empty>')]
		[string]
		$ItemType,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Group
	)
	
	process
	{
		if (-not $script:groupMemberShips[$Group]) { return }
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