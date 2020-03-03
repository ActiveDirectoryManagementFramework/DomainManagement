function Compare-Property
{
	<#
	.SYNOPSIS
		Helper function simplifying the changes processing.
	
	.DESCRIPTION
		Helper function simplifying the changes processing.
	
	.PARAMETER Property
		The property to use for comparison.
	
	.PARAMETER Configuration
		The object that was used to define the desired state.
	
	.PARAMETER ADObject
		The AD Object containing the actual state.
	
	.PARAMETER Changes
		An arraylist where changes get added to.
		The content of -Property will be added if the comparison fails.
	
	.PARAMETER Resolve
		Whether the value on the configured object's property should be string-resolved.
	
	.PARAMETER ADProperty
		The property on the ad object to use for the comparison.
		If this parameter is not specified, it uses the value from -Property.
	
	.EXAMPLE
		PS C:\> Compare-Property -Property Description -Configuration $ouDefinition -ADObject $adObject -Changes $changes -Resolve

		Compares the description on the configuration object (after resolving it) with the one on the ADObject and adds to $changes if they are inequal.
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Property,

		[Parameter(Mandatory = $true)]
		[object]
		$Configuration,

		[Parameter(Mandatory = $true)]
		[object]
		$ADObject,

		[Parameter(Mandatory = $true)]
		[AllowEmptyCollection()]
		[System.Collections.ArrayList]
		$Changes,

		[switch]
		$Resolve,

		[string]
		$ADProperty
	)
	
	begin
	{
		if (-not $ADProperty) { $ADProperty = $Property }
	}
	process
	{
		$propValue = $Configuration.$Property
		if ($Resolve) { $propValue = $propValue | Resolve-String }

		if (($propValue -is [System.Collections.ICollection]) -and ($ADObject.$ADProperty -is [System.Collections.ICollection])) {
			if (Compare-Object $propValue $ADObject.$ADProperty) {
				$null = $Changes.Add($Property)
			}
		}
		elseif ($propValue -ne $ADObject.$ADProperty) {
			$null = $Changes.Add($Property)
		}
	}
}
