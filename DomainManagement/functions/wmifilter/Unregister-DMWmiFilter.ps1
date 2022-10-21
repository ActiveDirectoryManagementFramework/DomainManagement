function Unregister-DMWmiFilter {
	<#
	.SYNOPSIS
		Removes a WMI filter definition from the desired state.
	
	.DESCRIPTION
		Removes a WMI filter definition from the desired state.
	
	.PARAMETER Name
		Name of the WMI filter definition to remove.
	
	.EXAMPLE
		PS c:\> Get-DMWmiFilter | Unregister-DMWmiFilter

		Clears all WMI filter definitions from the desired state.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process {
		foreach ($entry in $Name) {
			$script:wmifilter.Remove($entry)
		}
	}
}
