function Register-DMBuiltInSID
{
	<#
	.SYNOPSIS
		Register a name that points at a well-known SID.
	
	.DESCRIPTION
		Register a name that points at a well-known SID.
		This is used to reliably be able to compare access rules where built-in SIDs fail (e.g. for Sub-Domains).
		This functionality is exposed, in order to be able to resolve these identities, irrespective of name resolution and localization.
	
	.PARAMETER Name
		The name of the builtin entity to map.
	
	.PARAMETER SID
		The SID associated with the builtin entity.
	
	.EXAMPLE
		PS C:\> Register-DMBuiltInSID -Name 'BUILTIN\Incoming Forest Trust Builders' -SID 'S-1-5-32-557'

		Maps the group 'BUILTIN\Incoming Forest Trust Builders' to the SID 'S-1-5-32-557'
		Note: This mapping is pre-defined in the module and needs not be applied
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, Position =1, ValueFromPipelineByPropertyName = $true)]
		[System.Security.Principal.SecurityIdentifier]
		$SID
	)
	
	process
	{
		$script:builtInSidMapping[$Name] = $SID
	}
}
