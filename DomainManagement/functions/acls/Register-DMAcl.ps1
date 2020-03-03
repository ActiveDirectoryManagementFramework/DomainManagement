function Register-DMAcl
{
	<#
	.SYNOPSIS
		Registers an active directory acl.
	
	.DESCRIPTION
		Registers an active directory acl.
		This acl will be maintained as configured during Invoke-DMAcl.
	
	.PARAMETER Path
		Path (distinguishedName) of the ADObject the acl is assigned to.
		Subject to string insertion.
	
	.PARAMETER Owner
		Owner of the ADObject.
		Subject to string insertion.
	
	.PARAMETER NoInheritance
		Whether inheritance should be disabled on the ADObject.
		Defaults to $false

	.PARAMETER Optional
		The path this acl object is assigned to is optional and need not exist.
		This makes the rule apply only if the object exists, without triggering errors if it doesn't.
		It will also ignore access errors on the object.
	
	.EXAMPLE
		PS C:\> Get-Content .\groups.json | ConvertFrom-Json | Write-Output | Register-DMAcl

		Reads a json configuration file containing a list of objects with appropriate properties to import them as acl configuration.
	#>
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Owner,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$NoInheritance = $false,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Optional = $false
	)
	process
	{
		$script:acls[$Path] = [PSCustomObject]@{
			PSTypeName = 'DomainManagement.Acl'
			Path = $Path
			Owner = $Owner
			NoInheritance = $NoInheritance
			Optional = $Optional
		}
	}
}