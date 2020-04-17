function Unregister-DMDomainData {
	<#
	.SYNOPSIS
		Removes registered domain data gathering scripts.
	
	.DESCRIPTION
		Removes registered domain data gathering scripts.
		Also deletes all associated cached data.
	
	.PARAMETER Name
		Name of the domain data gathering script to remove.
	
	.EXAMPLE
		PS C:\> Get-DMDomainData | Unregister-DMDomainData

		Clears all domain data gathering scripts.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process {
		foreach ($nameString in $Name) {
			$script:domainDataScripts.Remove($nameString)
			foreach ($domainDataHash in $script:cache_DomainData.Values) {
				$domainDataHash.Remove($nameString)
			}
		}
	}
}
