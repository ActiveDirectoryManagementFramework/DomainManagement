function Get-SchemaGuidMapping
{
	<#
	.SYNOPSIS
		Returns a hashtable mapping schema guids to the name of an attribute / class.
	
	.DESCRIPTION
		Returns a hashtable mapping schema guids to the name of an attribute / class.
		This hashtable is being generated (and cached) on a per-Server basis.
	
	.PARAMETER NameToGuid
		Return a hashtable mapping name to guid, rather than one mapping guid to name.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-SchemaGuidMapping @parameters

		Returns a hashtable mapping Guid of attributes or classes to their humanly readable name.
	#>
	[CmdletBinding()]
	Param (
		[switch]
		$NameToGuid,

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	process
	{
		[string]$identity = '<default>'
		if ($Server) { $identity = $Server }

		if (Test-PSFTaskEngineCache -Module DomainManagement -Name "SchemaGuidCache.$Identity") {
			if ($NameToGuid) { return (Get-PSFTaskEngineCache -Module DomainManagement -Name "SchemaGuidCache.$Identity").NameToGuid }
			else { return (Get-PSFTaskEngineCache -Module DomainManagement -Name "SchemaGuidCache.$Identity").GuidToName }
		}

		Write-PSFMessage -Level Host -String 'Get-SchemaGuidMapping.Processing' -StringValues $identity
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false

		$schemaNC = (Get-ADRootDSE @parameters).schemaNamingContext
		$objects = Get-ADObject @parameters -SearchBase $schemaNC -Properties Name,SchemaIDGuid -LDAPFilter '(schemaIDGUID=*)' # Exclude the schema object itself
		$processed = $objects | Select-PSFObject Name, 'SchemaIDGuid to Guid as ID' | Select-PSFObject Name, 'ID to string'

		if (-not $processed) { return }
		$data = [PSCustomObject]@{
			NameToGuid = @{ '<All>' = "$([guid]::Empty)" }
			GuidToName = @{ "$([guid]::Empty)" = '<All>' }
		}
		foreach ($processedItem in $processed) {
			$data.GuidToName[$processedItem.ID] = $processedItem.Name
			$data.NameToGuid[$processedItem.Name] = $processedItem.ID
		}
		Set-PSFTaskEngineCache -Module DomainManagement -Name "SchemaGuidCache.$Identity" -Value $data
		if ($NameToGuid) { return $data.NameToGuid }
		else { return $data.GuidToName }
	}
}
