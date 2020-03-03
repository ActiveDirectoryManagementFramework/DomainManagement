function Compare-ObjectProperty {
	<#
		.SYNOPSIS
			Compares whether the input item is contained in the list of reference items.

		.DESCRIPTION
			Compares whether the input item is contained in the list of reference items.
			For this comparison, we use the defined propertynames.
			The input object is only returned, if there is at least one object with the same values for the specified properties.

		.PARAMETER ReferenceObject
			The list of objects the input is compared to.

		.PARAMETER PropertyName
			The list of properties used to establish the equality comparison.

		.PARAMETER DifferenceObject
			The input objects that are compared to the list in -ReferenceObject and only returned if at least one match exists.

		.EXAMPLE
			PS C:\> $_ | Compare-ObjectProperty -ReferenceObject $ADRules -PropertyName Identity, Permission, Allow

			Compares the current item ($_) with the content of $ADRules whether a match exists that shares all of Identity, Permission and Allow.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[PSObject[]]
		$ReferenceObject,
		
		[Parameter(Position = 1)]
		[PSFramework.Parameter.SelectParameter[]]
		$PropertyName,

		[Parameter(ValueFromPipeline = $true)]
		[PSObject[]]
		$DifferenceObject
	)
	begin {
		$comparer = $ReferenceObject | Select-PSFObject $PropertyName
		$select = { Select-PSFObject $PropertyName }.GetSteppablePipeline()
		$select.Begin($true)
		$properties = $PropertyName | ForEach-Object {
			if ($_.Value -is [string]) { return $_.Value }
			else { $_.Value.Name }
		} | Remove-PSFNull
	}
	process {
		:dif foreach ($inputObject in $DifferenceObject) {
			$inputConverted = $select.Process($inputObject)
			:ref foreach ($reference in $comparer) {
				foreach ($property in $properties) {
					if ($reference.$property -ne $inputConverted.$property) { continue ref }
				}
				$inputObject
				continue dif
			}
		}
	}
	end {
		$select.End()
	}
}