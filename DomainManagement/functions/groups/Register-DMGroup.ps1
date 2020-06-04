function Register-DMGroup
{
	<#
	.SYNOPSIS
		Registers an active directory group.
	
	.DESCRIPTION
		Registers an active directory group.
		This group will be maintained as configured during Invoke-DMGroup.
	
	.PARAMETER Name
		The name of the group.
		Subject to string insertion.

	.PARAMETER SamAccountName
		The SamAccountName of the group.
		Defaults to the Name if not otherwise specified.
	
	.PARAMETER Path
		Path (distinguishedName) of the OU to place the group in.
		Subject to string insertion.
	
	.PARAMETER Description
		Description of the group.
		Subject to string insertion.
	
	.PARAMETER Scope
		The scope of the group.
		Use DomainLocal for groups that grrant direct permissions and Global for role groups.

	.PARAMETER Category
		Whether the group should be a security group or a distribution group.
		Defaults to security.

	.PARAMETER OldNames
		Previous names the group used to have.
		By specifying this name, groups will be renamed if still using an old name.
		Conflicts may require resolving.
	
	.PARAMETER Present
		Whether the group should exist.
		Defaults to $true
		Set to $false for explicitly deleting groups, rather than creating them.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\groups.json | ConvertFrom-Json | Write-Output | Register-DMGroup

		Reads a json configuration file containing a list of objects with appropriate properties to import them as group configuration.
	#>
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$SamAccountName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('DomainLocal', 'Global', 'Universal')]
		[string]
		$Scope,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Security', 'Distribution')]
		[string]
		$Category = 'Security',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$OldNames = @(),

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Present = $true,

		[string]
		$ContextName = '<Undefined>'
	)
	
	process
	{
		$script:groups[$Name] = [PSCustomObject]@{
			PSTypeName = 'DomainManagement.Group'
			Name = $Name
			SamAccountName = $(if ($SamAccountName) { $SamAccountName } else { $Name })
			Path = $Path
			Description = $Description
			Scope = $Scope
			Category = $Category
			OldNames = $OldNames
			Present = $Present
			ContextName = $ContextName
		}
	}
}
