function Register-DMOrganizationalUnit
{
	<#
	.SYNOPSIS
		Registers an organizational unit, defining it as a desired state.
	
	.DESCRIPTION
		Registers an organizational unit, defining it as a desired state.
	
	.PARAMETER Name
		Name of the OU to register.
		Subject to string insertion.
	
	.PARAMETER Description
		Description for the OU to register.
		Subject to string insertion.
	
	.PARAMETER Path
		The path to where the OU should be.
		Subject to string insertion.
	
	.PARAMETER OldNames
		Previous names the OU had.
		During invocation, if it is not found but an OU in the same path with a listed old name IS, it will be renamed.
		Subject to string insertion.
	
	.PARAMETER Present
		Whether the OU should be present.
		Defaults to $true
	
	.EXAMPLE
		PS C:\> Get-Content .\organizationalUnits.json | ConvertFrom-Json | Write-Output | Register-DMOrganizationalUnit

		Reads a json configuration file containing a list of objects with appropriate properties to import them as organizational unit configuration.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[string[]]
		$OldNames = @(),

		[bool]
		$Present = $true
	)
	
	process
	{
		$distinguishedName = 'OU={0},{1}' -f $Name, $Path
		$script:organizationalUnits[$distinguishedName] = [PSCustomObject]@{
			PSTypeName = 'DomainManagement.OrganizationalUnit'
			DistinguishedName = $distinguishedName
			Name = $Name
			Description = $Description
			Path = $Path
			OldNames = $OldNames
			Present = $Present
		}
	}
}
