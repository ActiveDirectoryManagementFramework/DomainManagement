function Compare-Array
{
	<#
	.SYNOPSIS
		Compares two arrays.
	
	.DESCRIPTION
		Compares two arrays.
	
	.PARAMETER ReferenceObject
		The first array to compare with the second array.
	
	.PARAMETER DifferenceObject
		The second array to compare with the first array.
	
	.PARAMETER OrderSpecific
		Makes the comparison order specific.
		By default, the command does not care for the order the objects are stored in.
	
	.PARAMETER Quiet
		Rather than returning a delta report object, return a single truth statement:
		- $true if the two arrays are equal
		- $false if the two arrays are NOT equal.
	
	.EXAMPLE
		PS C:\> Compare-Array -ReferenceObject $currentStateSorted.DisplayName -DifferenceObject $desiredStateSorted.PolicyName -Quiet -OrderSpecific

		Compares the two sets of names, and returns ...
		- $true if both sets contains the same names in the same order
		- $false if they do not
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	Param (
		[object[]]
		$ReferenceObject,

		[object[]]
		$DifferenceObject,

		[switch]
		$OrderSpecific,

		[switch]
		$Quiet
	)
	
	process
	{
		# Not as default value to avoid null-bind dilemma
		if (-not $ReferenceObject) { $ReferenceObject = @() }
		if (-not $DifferenceObject) { $DifferenceObject = @() }

		#region Not Order Specific
		if (-not $OrderSpecific) {
			$delta = Compare-Object -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject
			if ($delta) {
				if ($Quiet) { return $false }
				[PSCustomObject]@{
					ReferenceObject = $ReferenceObject
					DifferenceObject = $DifferenceObject
					Delta = $delta
					IsEqual = $false
				}
				return
			}
			else {
				if ($Quiet) { return $true }
				[PSCustomObject]@{
					ReferenceObject = $ReferenceObject
					DifferenceObject = $DifferenceObject
					Delta = $delta
					IsEqual = $true
				}
				return
			}
		}
		#endregion Not Order Specific

		#region Order Specific
		else {
			if ($Quiet -and ($ReferenceObject.Count -ne $DifferenceObject.Count)) { return $false }
			$result = [PSCustomObject]@{
				ReferenceObject = $ReferenceObject
				DifferenceObject = $DifferenceObject
				Delta = @()
				IsEqual = $true
			}
			
			$maxCount = [math]::Max($ReferenceObject.Count, $DifferenceObject.Count)
			[System.Collections.ArrayList]$indexes = @()

			foreach ($number in (0..($maxCount - 1))) {
				if ($number -ge $ReferenceObject.Count) {
					$null = $indexes.Add($number)
					continue
				}
				if ($number -ge $DifferenceObject.Count) {
					$null = $indexes.Add($number)
					continue
				}
				if ($ReferenceObject[$number] -ne $DifferenceObject[$number]) {
					if ($Quiet) { return $false }
					$null = $indexes.Add($number)
					continue
				}
			}

			if ($indexes.Count -gt 0) {
				$result.IsEqual = $false
				$result.Delta = $indexes.ToArray()
			}

			$result
		}
		#endregion Order Specific
	}
}
