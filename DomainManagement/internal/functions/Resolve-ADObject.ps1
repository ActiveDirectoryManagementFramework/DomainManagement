function Resolve-ADObject {
	<#
	.SYNOPSIS
		Resolves AD Objects from wildcard-patterned DNs.
	
	.DESCRIPTION
		Resolves AD Objects from wildcard-patterned Distinguished Names.
	
	.PARAMETER OUFilter
		The wildcard-patterned DN
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER ObjectClass
		Only return objects of the specified object class.
		Default: *
	
	.EXAMPLE
		PS C:\> Resolve-ADObject -OUFilter '*,*,OU=Contoso,DC=contoso,DC=com' -ObjectClass user

		Resolves all user objects two steps under the Contoso OU.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[string]
		$Filter,

		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential,

		[string]
		$ObjectClass = '*'
	)

	begin {
		function Get-AdNextStep {
			[CmdletBinding()]
			param (
				$Parameters,
	
				$Fragments,
	
				$BasePath
			)
	
			$nameFilter = (@($Fragments)[0] -split "=",2)[-1]
			$adObjects = Get-ADObject @Parameters -SearchBase $BasePath -SearchScope OneLevel -LDAPFilter "(name=$nameFilter)"
			if (@($Fragments).Count -eq 1) {
				return $adObjects
			}
	
			foreach ($adObject in $adObjects) {
				Get-AdNextStep -Parameters $Parameters -BasePath $adObject.DistinguishedName -Fragments $Fragments[1..$Fragments.Length]
			}
		}
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	
	process {
		$filterSegments = ($Filter -replace ",DC=.+$" -split "(?<=[^\\],)").TrimEnd(",")
		$basePath = $Filter -replace '^.+?,DC=','DC='
		[array]::Reverse($filterSegments)
	
		Get-AdNextStep -Parameters $parameters -Fragments $filterSegments -BasePath $basePath | Where-Object ObjectClass -Like $ObjectClass
	}
}