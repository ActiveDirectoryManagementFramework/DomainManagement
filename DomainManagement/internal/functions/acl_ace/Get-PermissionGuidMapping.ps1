function Get-PermissionGuidMapping
{
	<#
	.SYNOPSIS
		Retrieve a hashtable mapping permission guids to their respective name.
	
	.DESCRIPTION
		Retrieve a hashtable mapping permission guids to their respective name.
		This is retrieved from the target forest on first request, then cached for subsequent calls.
		The cache is specific to the targeted server and maintained as long as the process runs.
	
	.PARAMETER NameToGuid
		Rather than returning a hashtable mapping guid to name, return a hashtable mapping name to guid.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-PermissionGuidMapping -Server contoso.com

		Returns a hashtable mapping guids to rights from the contoso.com forest.
	#>
	[CmdletBinding()]
	Param (
		[switch]
		$NameToGuid,

		[PSFComputer]
		$Server = 'default',
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		# Script scope variables declared and maintained in this file only
		if (-not $script:schemaGuidToRightMapping) {
			$script:schemaGuidToRightMapping = @{ }
		}
		if (-not $script:schemaRightToGuidMapping) {
			$script:schemaRightToGuidMapping = @{ }
		}
	}
	process
	{
		[string]$identity = $Server
		if ($script:schemaGuidToRightMapping[$identity]) {
			if ($NameToGuid) { return $script:schemaRightToGuidMapping[$identity] }
			else { return $script:schemaGuidToRightMapping[$identity] }
		}
		Write-PSFMessage -Level Host -String 'Get-PermissionGuidMapping.Processing' -StringValues $identity
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false

		Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).configurationNamingContext)" -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID

		$configurationNC = (Get-ADRootDSE @parameters).configurationNamingContext
		$objects = Get-ADObject @parameters -SearchBase "CN=Extended-Rights,$configurationNC" -Properties Name,rightsGUID -LDAPFilter '(objectCategory=controlAccessRight)' # Exclude the schema object itself
		$processed = $objects | Select-PSFObject Name, 'rightsGUID to Guid as ID' | Select-PSFObject Name, 'ID to string'

		if (-not $processed) { return }
		$script:schemaGuidToRightMapping[$identity] = @{ "$([guid]::Empty)" = '<All>' }
		$script:schemaRightToGuidMapping[$identity] = @{ '<All>' = "$([guid]::Empty)" }
		
		foreach ($processedItem in $processed) {
			$script:schemaGuidToRightMapping[$identity][$processedItem.ID] = $processedItem.Name
			$script:schemaRightToGuidMapping[$identity][$processedItem.Name] = $processedItem.ID
		}
		if ($NameToGuid) { return $script:schemaRightToGuidMapping[$identity] }
		else { return $script:schemaGuidToRightMapping[$identity] }
	}
}
