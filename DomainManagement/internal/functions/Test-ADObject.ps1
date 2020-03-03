function Test-ADObject
{
	<#
	.SYNOPSIS
		Tests, whether a given AD object already exists.
	
	.DESCRIPTION
		Tests, whether a given AD object already exists.
	
	.PARAMETER Identity
		Identity of the object to test.
		Must be a unique identifier accepted by Get-ADObject.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-ADObject -Identity $distinguishedName

		Tests whether the object referenced in $distinguishedName exists in the current domain.
	#>
	[OutputType([bool])]
	[CmdletBinding()]
    Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Identity,

        [string]
        $Server,

        [pscredential]
        $Credential
    )
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
	}
	process
	{
		try {
			$null = Get-ADObject -Identity $Identity @parameters -ErrorAction Stop
			return $true
		}
		catch {
			return $false
		}
	}
}
