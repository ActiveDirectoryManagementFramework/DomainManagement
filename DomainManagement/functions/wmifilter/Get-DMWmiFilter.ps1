function Get-DMWmiFilter {
	<#
	.SYNOPSIS
		Returns all registered WMI filter definitions.
	
	.DESCRIPTION
		Returns all registered WMI filter definitions.
	
	.PARAMETER Name
		Name of the definition to filter by.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-DMWmiFilter

		Returns all registered WMI filter definitions.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name = '*'
	)
	
	process {
		($script:wmifilter.Values | Where-Object Name -Like $Name)
	}
}
