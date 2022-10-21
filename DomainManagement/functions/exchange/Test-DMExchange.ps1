function Test-DMExchange
{
<#
	.SYNOPSIS
		Check whether the targeted domain has the desired exchange object update version.
	
	.DESCRIPTION
		Check whether the targeted domain has the desired exchange object update version.
		Use Register-DMExchange to define the desired version.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMExchange
	
		Check whether the current domain has the desired exchange object update version.
#>
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type ExchangeVersion -Cmdlet $PSCmdlet
	}
	process
	{
		$desiredState = Get-DMExchange
		$adObject = Get-ADObject @parameters -LDAPFilter '(objectClass=msExchSystemObjectsContainer)' -Properties objectVersion
		
		$resultDefaults = @{
			ObjectType = 'ExchangeVersion'
			Server	   = $parameters.Server
			Configuration = $desiredState
		}
		
		if (-not $adObject) {
			New-TestResult @resultDefaults -Type Install -Identity 'Exchange Domain Objects'
			return
		}
		
		if (($adObject.objectVersion -as [int]) -lt $desiredState.ObjectVersion) {
			New-TestResult @resultDefaults -Type Update -Identity 'Exchange Domain Objects' -ADObject $adObject
		}
	}
}