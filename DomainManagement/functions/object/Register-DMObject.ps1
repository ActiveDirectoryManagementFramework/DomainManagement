function Register-DMObject
{
	<#
	.SYNOPSIS
		Registers a generic object as the desired state for active directory.
	
	.DESCRIPTION
		Registers a generic object as the desired state for active directory.
		This allows defining custom objects not implemented as a commonly supported type.
	
	.PARAMETER Path
		The Path to the OU in which to place the object.
		Subject to string insertion.
	
	.PARAMETER Name
		Name of the object to define.
		Subject to string insertion.
	
	.PARAMETER ObjectClass
		The class of the object to define.
	
	.PARAMETER Attributes
		Attributes to include in the object.
		If you specify a hashtable, keys are mapped to attributes.
		If you specify another arbitrary object type, properties are mapped to attributes.

	.PARAMETER AttributesToResolve
		The names of all attributes in configuration, for which you want to perform string insertion, before comparing with the actual object in AD.
	
	.EXAMPLE
		PS C:\> Get-Content .\objects.json | ConvertFrom-Json | Write-Output | Register-DMObject

		Imports all objects defined in objects.json.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ObjectClass,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		$Attributes,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$AttributesToResolve
	)
	
	process
	{
		$identity = "CN=$Name,$Path"
		if (-not $Name) { $identity = $Path }
		$script:objects["CN=$Name,$Path"] = [PSCustomObject]@{
			PSTypeName = 'DomainManagement.Object'
			Identity = $identity
			Path = $Path
			Name = $Name
			ObjectClass = $ObjectClass
			Attributes = ($Attributes | ConvertTo-PSFHashtable)
			AttributesToResolve = $AttributesToResolve
		}
	}
}