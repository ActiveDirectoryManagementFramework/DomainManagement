function New-TestResult
{
	<#
	.SYNOPSIS
		Generates a new test result object.
	
	.DESCRIPTION
		Generates a new test result object.
		Helper function that slims down the Test- commands.
	
	.PARAMETER ObjectType
		What kind of object is being processed (e.g.: User, OrganizationalUnit, Group, ...)
	
	.PARAMETER Type
		What kind of change needs to be performed
	
	.PARAMETER Identity
		Identity of the change item
	
	.PARAMETER Changed
		What properties - if any - need to be changed
	
	.PARAMETER Server
		The server the test was performed against
	
	.PARAMETER Configuration
		The configuration object containing the desired state.
	
	.PARAMETER ADObject
		The AD Object(s) containing the actual state.
	
	.EXAMPLE
		PS C:\> New-TestResult -ObjectType User -Type Changed -Identity $resolvedDN -Changed Description -Server $Server -Configuration $userDefinition -ADObject $adObject

		Creates a new test result object using the specified information.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$ObjectType,

		[Parameter(Mandatory = $true)]
		[string]
		$Type,

		[Parameter(Mandatory = $true)]
		[string]
		$Identity,

		[object[]]
		$Changed,

		[Parameter(Mandatory = $true)]
		[AllowNull()]
		[PSFComputer]
		$Server,

		$Configuration,

		$ADObject
	)
	
	process
	{
		$object = [PSCustomObject]@{
			PSTypeName = "DomainManagement.$ObjectType.TestResult"
			Type = $Type
			ObjectType = $ObjectType
			Identity = $Identity
			Changed = $Changed
			Server = $Server
			Configuration = $Configuration
			ADObject = $ADObject
		}
		Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value { $this.Identity } -Force
		$object
	}
}