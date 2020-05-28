function Compare-Identity {
	<#
	.SYNOPSIS
		Compares two sets of identity references, similar to Compare-Object.
	
	.DESCRIPTION
		Compares two sets of identity references, similar to Compare-Object.
		Only real difference: Performs identity resolution and compares at the SID level.
	
	.PARAMETER ReferenceIdentity
		One set of identities to compare.
	
	.PARAMETER DifferenceIdentity
		The other set of identities to compare.
	
	.PARAMETER Parameters
		AD connection parameters.
		Offer a hashtable containing server or credentials in any combination.
	
	.PARAMETER IncludeEqual
		Return identities that occur in both sets.
	
	.PARAMETER ExcludeDifferent
		Do not return identities that only occur in one set
	
	.EXAMPLE
		PS C:\> $relevantADRule.IdentityReference | Compare-Identity -Parameters $parameters -ReferenceIdentity $ConfiguredRules.IdentityReference -IncludeEqual -ExcludeDifferent

		Compares all identities between the accessrule already existing on the AD object and the ones defined for it.
		Only returns existing Active Directory-existing rules if there also is at least one configured rule for its identity.
	#>
	[CmdletBinding()]
	param (
		$ReferenceIdentity,

		[Parameter(ValueFromPipeline = $true)]
		$DifferenceIdentity,

		[Hashtable]
		$Parameters = @{ },

		[switch]
		$IncludeEqual,

		[switch]
		$ExcludeDifferent
	)

	begin {
		#region Utility Functions
		function ConvertTo-SID {
			[CmdletBinding()]
			param (
				$IdentityReference,

				[Hashtable]
				$Parameters
			)

			$resolved = Convert-BuiltInToSID -Identity $IdentityReference
			if ($resolved -is [System.Security.Principal.SecurityIdentifier]) { return $resolved }
			
			# NTAccount
			try { Convert-Principal -Name $resolved -OutputType SID @Parameters }
			catch { $resolved }
		}
		#endregion Utility Functions

		$referenceItems = foreach ($identity in $ReferenceIdentity) {
			$sid = ConvertTo-SID -IdentityReference $identity -Parameters $Parameters
			[PSCustomObject]@{
				Type = "Reference"
				Original = $identity
				SID = $sid
				SIDString = "$sid"
			}
		}

		[System.Collections.ArrayList]$differenceItems = @()
	}
	process {
		foreach ($item in $DifferenceIdentity) {
			$sid = ConvertTo-SID -IdentityReference $item -Parameters $Parameters
			$result = [PSCustomObject]@{
				Type = "Reference"
				Original = $identity
				SID = $sid
				SIDString = "$sid"
			}
			$null = $differenceItems.Add($result)
		}
	}
	end {
		if (-not $ExcludeDifferent) {
			foreach ($differenceItem in $differenceItems) {
				if ($differenceItem.SIDString -in $referenceItems.SIDString) { continue }

				[PSCustomObject]@{
					Identity = $differenceItem.Original
					SID = $differenceItem.SID
					Direction = '<='
				}
			}
			foreach ($referenceItem in $referenceItems) {
				if ($referenceItem.SIDString -in $differenceItems.SIDString) { continue }

				[PSCustomObject]@{
					Identity = $referenceItem.Original
					SID = $referenceItem.SID
					Direction = '=>'
				}
			}
		}
		if ($IncludeEqual) {
			foreach ($differenceItem in $differenceItems) {
				if ($differenceItem.SIDString -notin $referenceItems.SIDString) { continue }

				[PSCustomObject]@{
					Identity = $differenceItem.Original
					SID = $differenceItem.SID
					Direction = '=='
				}
			}
		}
	}
}