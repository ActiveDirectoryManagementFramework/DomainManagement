function Get-DMGroupMembership
{
	<#
	.SYNOPSIS
		Returns the list of configured group memberships.
	
	.DESCRIPTION
		Returns the list of configured group memberships.
	
	.PARAMETER Group
		Name of the group to filter by.
	
	.PARAMETER Name
		Name of the entity being granted groupmembership to filter by.
	
	.EXAMPLE
		PS C:\> Get-DMGroupMembership

		List all configured group memberships.
	#>
	
	[CmdletBinding()]
	param (
		[string]
		$Group = '*',

		[string]
		$Name = '*'
	)
	
	process
	{
		$results = foreach ($key in $script:groupMemberShips.Keys) {
			if ($key -notlike $Group) { continue }

			if ($script:groupMemberShips[$key].Count -gt 0) {
				foreach ($innerKey in $script:groupMemberShips[$key].Keys) {
					$script:groupMemberShips[$key][$innerKey]
				}
			}
			else {
				[PSCustomObject]@{
					PSTypeName = 'DomainManagement.GroupMembership'
					Name = '<Empty>'
					Domain = '<Empty>'
					ItemType = '<Empty>'
					Group = $key
				}
			}
		}
		$results | Sort-Object Group
	}
}
