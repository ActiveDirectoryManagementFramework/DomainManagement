function Unregister-DMGPOwner
{
	<#
	.SYNOPSIS
		Removes entries from the desired state for group policy ownership.
	
	.DESCRIPTION
		Removes entries from the desired state for group policy ownership.
	
	.PARAMETER EntryIdentity
		The identity of the entry.
	
	.EXAMPLE
		PS C:\> Get-DMGPOwner | Unregister-DMGPOwner

		Clears all defines group policy ownerships
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
		[string[]]
		$EntryIdentity
	)
	
	process
	{
		foreach ($identityString in $EntryIdentity) {
			$script:groupPolicyOwners.Remove($identityString)
		}
	}
}
