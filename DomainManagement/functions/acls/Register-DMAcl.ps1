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

	.PARAMETER DefaultOwner
		Whether to make this the default owner for objects not specified under either a path or an object category.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\groups.json | ConvertFrom-Json | Write-Output | Register-DMAcl

		Reads a json configuration file containing a list of objects with appropriate properties to import them as acl configuration.
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'path')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'path')]
		[string]
		$Path,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'category')]
		[string]
		$ObjectCategory,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Owner,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'path')]
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'category')]
		[bool]
		$NoInheritance = $false,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'path')]
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'category')]
		[bool]
		$Optional = $false,

		[Parameter(ParameterSetName = 'DefaultOwner')]
		[switch]
		$DefaultOwner,

		[string]
		$ContextName = '<Undefined>'
	)
	process
	{
		switch ($PSCmdlet.ParameterSetName) {
			'path'
			{
				$script:acls[$Path] = [PSCustomObject]@{
					PSTypeName = 'DomainManagement.Acl'
					Path = $Path
					Owner = $Owner
					NoInheritance = $NoInheritance
					Optional = $Optional
					ContextName = $ContextName
				}
			}
			'category'
			{
				$script:aclByCategory[$ObjectCategory] = [PSCustomObject]@{
					PSTypeName = 'DomainManagement.Acl'
					Category = $ObjectCategory
					Owner = $Owner
					NoInheritance = $NoInheritance
					Optional = $Optional
					ContextName = $ContextName
				}
			}
			'DefaultOwner'
			{
				# Array to appease Assert-Configuration
				$script:aclDefaultOwner = @([PSCustomObject]@{
					PSTypeName = 'DomainManagement.Acl'
					Path = '<default>'
					Owner = $Owner
					NoInheritance = $false
					Optional = $null
					ContextName = $ContextName
				})
			}
		}
	}
}