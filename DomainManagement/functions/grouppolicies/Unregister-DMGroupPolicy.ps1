function Unregister-DMGroupPolicy
{
	<#
		.SYNOPSIS
			Removes a group policy object from the list of desired gpos.
		
		.DESCRIPTION
			Removes a group policy object from the list of desired gpos.
		
		.PARAMETER Name
			The name of the GPO to remove from the list of ddesired gpos
		
		.EXAMPLE
			PS C:\> Get-DMGroupPolicy | Unregister-DMGroupPolicy

			Clears all configured GPOs
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
		[Alias('DisplayName')]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameItem in $Name) {
			$script:groupPolicyObjects.Remove($nameItem)
		}
	}
}
