function Unregister-DMServiceAccount
{
<#
	.SYNOPSIS
		Removes a service account from the list of registered service accounts.
	
	.DESCRIPTION
		Removes a service account from the list of registered service accounts.
	
	.PARAMETER Name
		The account to remove.
	
	.EXAMPLE
		PS C:\> Get-DMServiceAccount | Unregister-DMServiceAccount
	
		Clear all configured service accounts.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameItem in $Name)
		{
			$script:serviceAccounts.Remove($nameItem)
		}
	}
}
