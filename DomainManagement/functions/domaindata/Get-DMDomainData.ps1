function Get-DMDomainData {
	<#
	.SYNOPSIS
		Returns registered domain data gathering scripts.
	
	.DESCRIPTION
		Returns registered domain data gathering scripts.
	
	.PARAMETER Name
		The name to filter by, accepts wildcards.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-DomainData

		Returns all registered domain data gathering scripts
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
		[string]
		$Name = '*'
	)
	
	process {
		$script:domainDataScripts.Values | Where-Object Name -like $Name
	}
}
