function Resolve-DMObjectCategory
{
	<#
	.SYNOPSIS
		Resolves what object categories apply to a given AD Object.
	
	.DESCRIPTION
		Resolves what object categories apply to a given AD Object.
	
	.PARAMETER ADObject
		The AD Object for which to resolve the object categories.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Resolve-DMObjectCategory @parameters -ADObject $adobject

		Resolves the object categories that apply to $adobject
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$ADObject,

		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
	}
	process
	{
		if ($script:objectCategories.Values.ObjectClass -notcontains $ADObject.ObjectClass) {
			return
		}

		$filteredObjectCategories = $script:objectCategories.Values | Where-Object ObjectClass -eq $ADobject.ObjectClass
		$propertyNames = $filteredObjectCategories.Property | Select-Object -Unique
		$adObjectReloaded = Get-Adobject @parameters -Identity $ADObject.DistinguishedName -Properties $propertyNames
		foreach ($filteredObjectCategory in $filteredObjectCategories) {
			if ($filteredObjectCategory.Testscript.Invoke($adObjectReloaded)) {
				$filteredObjectCategory
			}
		}
	}
}
