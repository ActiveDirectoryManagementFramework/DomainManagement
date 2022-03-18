function Get-Domain2
{
	<#
	.SYNOPSIS
		Returns the direct domain object accessible via the server/credential parameter connection.
	
	.DESCRIPTION
		Returns the direct domain object accessible via the server/credential parameter connection.
		Caches data for subsequent calls.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-Domain2 @parameters

		Returns the domain associated with the specified connection information
	#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		[Alias('ComputerName')]
		$Server = '<Default>',

		[PSCredential]
		$Credential
	)
	
	begin
	{
		# Note: Module Scope variable solely maintained in this file
		#       Scriptscope for data persistence only
		if (-not ($script:directDomainObjectCache)) {
			$script:directDomainObjectCache = @{ }
		}
	}
	process
	{
		if ($script:directDomainObjectCache["$Server"]) {
			return $script:directDomainObjectCache["$Server"]
		}

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$adObject = Get-ADDomain @parameters
		$script:directDomainObjectCache["$Server"] = $adObject
		$adObject
	}
}
