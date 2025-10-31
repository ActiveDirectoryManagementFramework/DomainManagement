function Convert-AccessRuleIdentity {
	<#
	.SYNOPSIS
		Converts the identity on the specified access rule to NT Account.
	
	.DESCRIPTION
		Converts the identity on the specified access rule to NT Account.
	
	.PARAMETER InputObject
		The Access Rules for which to convert the Identity.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.

	.PARAMETER Target
		The target AD object this access rule applies to.
		Used for logging only.
	
	.EXAMPLE
		PS C:\> $adAclObject.Access | Convert-AccessRuleIdentity @parameters

		Converts the identity on all Access Rules in $adAclObject to NT Account.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[System.DirectoryServices.ActiveDirectoryAccessRule[]]
		$InputObject,

		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential,

		[string]
		$Target
	)
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$domainObject = Get-Domain2 @parameters
	}
	process {
		:main foreach ($accessRule in $InputObject) {
			if ($accessRule.IdentityReference -is [System.Security.Principal.NTAccount]) {
				Add-Member -InputObject $accessRule -MemberType NoteProperty -Name OriginalRule -Value $accessRule -PassThru
				continue main
			}
			
			if (-not $accessRule.IdentityReference.AccountDomainSid) {
				try { $identity = Get-Principal @parameters -Sid $accessRule.IdentityReference -Domain $domainObject.DNSRoot -OutputType NTAccount -Target $Target }
				catch {
					# Empty Catch is OK here, warning happens in command
				}
			}
			else {
				try { $identity = Get-Principal @parameters -Sid $accessRule.IdentityReference -Domain $accessRule.IdentityReference -OutputType NTAccount -Target $Target}
				catch {
					# Empty Catch is OK here, warning happens in command
				}
			}
			if (-not $identity) {
				$identity = $accessRule.IdentityReference
			}

			$newRule = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($identity, $accessRule.ActiveDirectoryRights, $accessRule.AccessControlType, $accessRule.ObjectType, $accessRule.InheritanceType, $accessRule.InheritedObjectType)
			# Include original object as property in order to facilitate removal if needed.
			Add-Member -InputObject $newRule -MemberType NoteProperty -Name OriginalRule -Value $accessRule -PassThru
		}
	}
}