function Unregister-DMUser
{
	<#
	.SYNOPSIS
		Removes a user that had previously been registered.
	
	.DESCRIPTION
		Removes a user that had previously been registered.
	
	.PARAMETER Name
		The name of the user to remove.
	
	.EXAMPLE
		PS C:\> Get-DMUser | Unregister-DMUser

		Clears all registered users.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('SamAccountName')]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameItem in $Name) {
			$script:users.Remove($nameItem)
		}
	}
}
