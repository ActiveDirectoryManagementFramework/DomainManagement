function Find-DMObjectCategoryItem {
<#
	.SYNOPSIS
		Searches for items that are part of an object category.
	
	.DESCRIPTION
		Searches for items that are part of an object category.
		Caution: A combination of inefficient filters and large scope can lead to significant performance delays in large environments!
	
	.PARAMETER Name
		The name of the object category to search items for.
	
	.PARAMETER Property
		Properties to include when retrieving matching items.
		Ensure the property is legal for all potential matches.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Find-DMObjectCategoryItem -Name 'CAServer'
	
		Find all objects that are part of the CAServer category.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string[]]
		$Property,
		
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
	}
	process {
		$category = $script:objectCategories[$Name]
		if (-not $category) {
			Stop-PSFFunction -String 'Find-DMObjectCategoryItem.Category.NotFound' -StringValues $Name -EnableException $EnableException -Cmdlet $PSCmdlet
			return
		}
		
		$searchBase = Resolve-String -Text $category.SearchBase @parameters
		if ($category.LdapFilter) {
			$filter = '(&(objectClass={0})({1}))' -f $category.ObjectClass, (Resolve-String -Text $category.LdapFilter @parameters)
			if ($Property) { $parameters.Properties = $Property }
			try { Get-ADObject @parameters -LDAPFilter $filter -SearchBase $searchBase -SearchScope $category.SearchScope -ErrorAction Stop }
			catch {
				Stop-PSFFunction -String 'Find-DMObjectCategoryItem.ADError' -StringValues $Name -EnableException $EnableException -Cmdlet $PSCmdlet
				return
			}
		}
		else {
			if ($Property) { $parameters.Properties = $Property }
			try { Get-ADObject @parameters -Filter $category.Filter -SearchBase $searchBase -SearchScope $category.SearchScope -ErrorAction Stop }
			catch {
				Stop-PSFFunction -String 'Find-DMObjectCategoryItem.ADError' -StringValues $Name -EnableException $EnableException -Cmdlet $PSCmdlet
				return
			}
		}
	}
}