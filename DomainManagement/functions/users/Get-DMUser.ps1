function Get-DMUser
{
	<#
		.SYNOPSIS
			Lists registered ad users.
		
		.DESCRIPTION
			Lists registered ad users.
		
		.PARAMETER Name
			The name to filter by.
			Defaults to '*'
		
		.EXAMPLE
			PS C:\> Get-DMUser

			Lists all registered ad users.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*'
	)
	
	process
	{
		($script:users.Values | Where-Object SamAccountName -like $Name)
	}
}
