function Convert-BuiltInToSID
{
	<#
	.SYNOPSIS
		Converts pre-configured built in accounts into SID form.
	
	.DESCRIPTION
		Converts pre-configured built in accounts into SID form.
		These must be registered using Register-DMBuiltInSID.
		Returns all identity references that are not a BuiltIn account that was registered.
	
	.PARAMETER Identity
		The identity reference to translate.
	
	.EXAMPLE
		Convert-BuiltInToSID -Identity $Rule1.IdentityReference
		
		Converts to IdentityReference of $Rule1 if necessary
	#>
	[CmdletBinding()]
	Param (
		$Identity
	)
	
	process
	{
		if ($Identity -as [System.Security.Principal.SecurityIdentifier]) { return ($Identity -as [System.Security.Principal.SecurityIdentifier]) }
		if ($script:builtInSidMapping["$Identity"]) { return $script:builtInSidMapping["$Identity"] }
		$Identity
	}
}