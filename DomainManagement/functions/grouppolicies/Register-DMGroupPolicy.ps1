function Register-DMGroupPolicy
{
	<#
	.SYNOPSIS
		Adds a group policy object to the list of desired GPOs.
	
	.DESCRIPTION
		Adds a group policy object to the list of desired GPOs.
		These are then tested for using Test-DMGroupPolicy and applied by using Invoke-DMGroupPolicy.
	
	.PARAMETER DisplayName
		Name of the GPO to add.
		
	.PARAMETER Description
		Description of the GPO in question,.
	
	.PARAMETER ID
		The GPO Id GUID.
	
	.PARAMETER Path
		Path to where the GPO export can be found.
	
	.PARAMETER ExportID
		The tracking ID assigned to the GPO in order to detect its revision.
		#TODO: Migrate export command and add documentation.
	
	.EXAMPLE
		PS C:\> Get-Content gpos.json | ConvertFrom-Json | Write-Output | Register-DMGroupPolicy

		Reads all gpos defined in gpos.json and registers each as a GPO object.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$DisplayName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[string]
		$Description,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ID,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ExportID
	)
	
	process
	{
		$script:groupPolicyObjects[$DisplayName] = [PSCustomObject]@{
			PSTypeName = 'DomainManagement.GroupPolicyObject'
			DisplayName = $DisplayName
			Description = $Description
			ID = $ID
			Path = $Path
			ExportID = $ExportID
		}
	}
}
