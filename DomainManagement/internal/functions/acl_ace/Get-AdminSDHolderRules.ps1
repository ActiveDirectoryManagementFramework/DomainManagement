function Get-AdminSDHolderRules {
	<#
	.SYNOPSIS
		Returns the access rules applied to the AdminSDHolder object.
	
	.DESCRIPTION
		Returns the access rules applied to the AdminSDHolder object.
		Used in workflows comparing privileges on the AdminSDHolder object.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-AdminSDHolderRules

		Returns the access rules applied to the AdminSDHolder object of the current domain.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)

	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process {
		$systemContainer = (Get-ADDomain @parameters).SystemsContainer
		(Get-AdsAcl -Path "CN=AdminSDHolder,$systemContainer" @parameters).Access
	}
}