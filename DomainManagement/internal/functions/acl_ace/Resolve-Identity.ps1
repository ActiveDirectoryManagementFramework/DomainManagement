function Resolve-Identity {
	<#
	.SYNOPSIS
		Resolve an Identity Reference with special rules.
	
	.DESCRIPTION
		Resolve an Identity Reference with special rules.
		Resolves to a SID (preferred) or NT Account (Fallback).
		
		Special Rules:
		<Parent> resolves to the parent object in AD

		This is a helper tool to resolve Identities on Access Rules applied to (or ointended for) AD objects only.
	
	.PARAMETER IdentityReference
		The Identity to resolve.
	
	.PARAMETER ADObject
		The AD Object from which the access rules has been read where the Identity is being resolved.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Resolve-Identity -Identity $name -ADObject %adObject @parameters

		Resolve the Identity in $name
	#>
	[CmdletBinding()]
	param (
		[string]
		$IdentityReference,

		$ADObject,

		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)

	#region Parent Resolution
	if ($IdentityReference -eq '<Parent>') {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$domainObject = Get-Domain2 @parameters
		$parentPath = ($ADObject.DistinguishedName -split ",",2)[1]
		$parentObject = Get-ADObject @parameters -Identity $parentPath -Properties SamAccountName, Name, ObjectSID
		if (-not $parentObject.ObjectSID) {
			Stop-PSFFunction -String 'Resolve-Identity.ParentObject.NoSecurityPrincipal' -StringValues $ADObject, $parentObject.Name, $parentObject.ObjectClass -EnableException $true -Cmdlet $PSCmdlet
		}
		if ($parentObject.SamAccountName) { return [System.Security.Principal.NTAccount]('{0}\{1}' -f $domainObject.Name, $parentObject.SamAccountName) }
		else { return [System.Security.Principal.NTAccount]('{0}\{1}' -f $domainObject.Name, $parentObject.Name) }
	}
	#endregion Parent Resolution

	#region Default Resolution
	$identity = Resolve-String -Text $IdentityReference
	if ($identity -as [System.Security.Principal.SecurityIdentifier]) {
		$identity = $identity -as [System.Security.Principal.SecurityIdentifier]
	}
	else {
		$identity = $identity -as [System.Security.Principal.NTAccount]
	}
	if ($null -eq $identity) { $identity = (Resolve-String -Text $IdentityReference) -as [System.Security.Principal.NTAccount] }

	$identity
	#endregion Default Resolution
}