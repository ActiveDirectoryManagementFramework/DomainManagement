function Set-DMRedForestContext
{
	<#
	.SYNOPSIS
		Sets the basic information of the red forest.
	
	.DESCRIPTION
		Sets the basic information of the red forest.
		This is used to provide for replacement variables usable on all properties of all domain objects supporting string resolution.

		There are two ways to gather this information:
		- Collect it from a forest (default; Collects from the current user's forest by default)
		- Explicitly provide the values.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER FQDN
		FQDN of the forest.
	
	.PARAMETER Name
		Name of the forest (usually the same as the FQDN)

	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Set-DMRedForestContext

		Configures the current forest as red forest.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(DefaultParameterSetName = 'Access')]
	Param (
		[Parameter(ParameterSetName = 'Access')]
		[string]
		$Server,

		[Parameter(ParameterSetName = 'Access')]
		[pscredential]
		$Credential,

		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$FQDN,

		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$Name,

		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
	}
	process
	{
		switch ($PSCmdlet.ParameterSetName) {
			'Access'
			{
				try { $forest = Get-ADForest @parameters -ErrorAction Stop }
				catch {
					Stop-PSFFunction -String 'Set-DMRedForestContext.Connection.Failed' -StringValues $Server -Target $Server -EnableException $EnableException -ErrorRecord $_
					return
				}
				$script:redForestContext.Name = $forest.Name
				$script:redForestContext.Fqdn = $forest.Name
				$script:redForestContext.RootDomainName = ($forest.RootDomain -split "\.")[0]
				$script:redForestContext.RootDomainFqdn = $forest.RootDomain

				Register-DMNameMapping -Name '%RedForestName%' -Value $forest.Name
				Register-DMNameMapping -Name '%RedForestFqdn%' -Value $forest.Name
				Register-DMNameMapping -Name '%RedForestRootDomainName%' -Value ($forest.RootDomain -split "\.")[0]
				Register-DMNameMapping -Name '%RedForestRootDomainFqdn%' -Value $forest.RootDomain
			}
			'Name'
			{
				$script:redForestContext.Name = $Name
				$script:redForestContext.Fqdn = $FQDN
				$script:redForestContext.RootDomainName = ($FQDN -split "\.")[0]
				$script:redForestContext.RootDomainFqdn = $FQDN

				Register-DMNameMapping -Name '%RedForestName%' -Value $Name
				Register-DMNameMapping -Name '%RedForestFqdn%' -Value $FQDN
				Register-DMNameMapping -Name '%RedForestRootDomainName%' -Value ($FQDN -split "\.")[0]
				Register-DMNameMapping -Name '%RedForestRootDomainFqdn%' -Value $FQDN
			}
		}
	}
}
