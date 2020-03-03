function Convert-DMSchemaGuid
{
	<#
	.SYNOPSIS
		Converts names to guid and guids to name as defined in the active directory schema.
	
	.DESCRIPTION
		Converts names to guid and guids to name as defined in the active directory schema.
		Can handle both attributes as well as rights.
		Uses mapping data generated from active directory.
	
	.PARAMETER Name
		The name to convert. Can be both string or guid.
	
	.PARAMETER OutType
		The data tape to emit:
		- Name: Humanly readable name
		- Guid: Guid object
		- GuidString: Guid as a string
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Convert-DMSchemaGuid -Name Public-Information -OutType GuidString

		Converts the right "Public-Information" into its guid representation (guid returned as a string type)
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[Alias('Guid')]
		[string[]]
		$Name,

		[ValidateSet('Name', 'Guid', 'GuidString')]
		[string]
		$OutType = 'Guid',

		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false

		$guidToName = Get-SchemaGuidMapping @parameters
		$nameToGuid = Get-SchemaGuidMapping @parameters -NameToGuid
		$guidToRight = Get-PermissionGuidMapping @parameters
		$rightToGuid = Get-PermissionGuidMapping @parameters -NameToGuid
	}
	process
	{
		:main foreach ($nameString in $Name) {
			switch ($OutType) {
				'Name'
				{
					if ($nameString -as [Guid]) {
						if ($guidToName[$nameString]) {
							$guidToName[$nameString]
							continue main
						}
						if ($guidToRight[$nameString]) {
							$guidToRight[$nameString]
							continue main
						}
					}
					else { $nameString }
				}
				'Guid'
				{
					if ($nameString -as [Guid]) {
						$nameString -as [Guid]
						continue main
					}
					if ($nameToGuid[$nameString]) {
						$nameToGuid[$nameString] -as [guid]
						continue main
					}
					if ($rightToGuid[$nameString]) {
						$rightToGuid[$nameString] -as [guid]
						continue main
					}
				}
				'GuidString'
				{
					if ($nameString -as [Guid]) {
						$nameString
						continue main
					}
					if ($nameToGuid[$nameString]) {
						$nameToGuid[$nameString]
						continue main
					}
					if ($rightToGuid[$nameString]) {
						$rightToGuid[$nameString]
						continue main
					}
				}
			}
		}
	}
}
