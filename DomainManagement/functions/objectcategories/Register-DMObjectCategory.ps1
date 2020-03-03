function Register-DMObjectCategory
{
	<#
	.SYNOPSIS
		Registers a new object category.
	
	.DESCRIPTION
		Registers a new object category.
		Object categories are a way to apply settings to a type of object based on a ruleset / filterset.
		For example, by registering an object category "Domain Controllers" (with appropriate filters / conditions),
		it becomes possible to define access rules that apply to all domain controllers, but not all computers.

		Note: Not all setting types support categories yet.
	
	.PARAMETER Name
		The name of the category. Must be unique.
		Will NOT be resolved.
	
	.PARAMETER ObjectClass
		The ObjectClass of the object.
		This is the AD attribute of the object.
		Each object category can only apply to one class of object, in order to protect system performance.
	
	.PARAMETER Property
		The properties needed for this category.
		This attribute is used to optimize object reetrieval in case of multiple categories applying to the same class of object.
	
	.PARAMETER TestScript
		Scriptblock used to determine, whether the input object is part of the category.
		Receives the AD object with the requested attributes as input object / argument.
	
	.PARAMETER Filter
		A filter used to find all objects in AD that match this category.
	
	.PARAMETER LdapFilter
		An LDAP filter used to find all objects in AD that match this category.
	
	.EXAMPLE
		PS C:\> Register-DMObjectCategory -Name DomainController -ObjectClass computer -Property PrimaryGroupID -TestScript { $args[0].PrimaryGroupID -eq 516 } -LDAPFilter '(&(objectCategory=computer)(primaryGroupID=516))'

		Registers an object category applying to all domain controller's computer object in AD.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Filter')]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ObjectClass,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Property,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[scriptblock]
		$TestScript,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[string]
		$Filter,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'LdapFilter')]
		[string]
		$LdapFilter
	)
	
	process
	{
		$script:objectCategories[$Name] = [PSCustomObject]@{
			Name = $Name
			ObjectClass = $ObjectClass
			Property = $Property
			TestScript = $TestScript
			Filter = $Filter
			LdapFilter = $LdapFilter
		}
	}
}
