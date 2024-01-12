function Compare-AccessRules {
	<#
	.SYNOPSIS
		Compare actual access rules to the system default and configured rules.
	
	.DESCRIPTION
		Compare actual access rules to the system default and configured rules.
	
	.PARAMETER ADRules
		The Access Rules actually deployed on the AD Object
	
	.PARAMETER ConfiguredRules
		The Access Rules configured for the AD Object
	
	.PARAMETER DefaultRules
		The default Access Rules for objects of this type
	
	.PARAMETER ADObject
		The AD Object for which Access Rules are being compared
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Compare-AccessRules @parameters -ADRules ($adAclObject.Access | Convert-AccessRuleIdentity @parameters) -ConfiguredRules $desiredPermissions -DefaultRules $defaultPermissions -ADObject $adObject
		
		Compare actual access rules on the specified AD Object to the system default and configured rules.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
	[CmdletBinding()]
	param (
		[AllowEmptyCollection()]
		$ADRules,

		[AllowEmptyCollection()]
		$ConfiguredRules,

		[AllowEmptyCollection()]
		$DefaultRules,

		$ADObject,

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)

	$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

	# Resolve the mode under which it will be evaluated. Either 'Additive' or 'Constrained'
	$processingMode = Resolve-DMAccessRuleMode @parameters -ADObject $adObject

	function Write-Result {
		[CmdletBinding()]
		param (
			[ValidateSet('Create', 'Delete', 'FixConfig', 'Restore')]
			[Parameter(Mandatory = $true)]
			$Type,

			$Identity,

			[AllowNull()]
			$ADObject,

			[AllowNull()]
			$Configuration,

			[string]
			$DistinguishedName
		)

		$item = [PSCustomObject]@{
			PSTypeName        = 'DomainManagement.AccessRule.Change'
			Type              = $Type
			ACT               = $ADObject.AccessControlType
			Identity          = $Identity
			Rights            = $ADObject.ActiveDirectoryRights
			DistinguishedName = $DistinguishedName
			ADObject          = $ADObject
			Configuration     = $Configuration
		}
		if (-not $ADObject) {
			$item.ACT = $Configuration.AccessControlType
			$item.Rights = $Configuration.ActiveDirectoryRights
		}
		Add-Member -InputObject $item -MemberType ScriptMethod ToString -Value { '{0}: {1}' -f $this.Type, $this.Identity } -Force -PassThru
	}

	$defaultRulesPresent = [System.Collections.ArrayList]::new()
	$relevantADRules = :outer foreach ($adRule in $ADRules) {
		if ($adRule.OriginalRule.IsInherited) { continue }
		#region Skip OUs' "Protect from Accidential Deletion" ACE
		if (($adRule.AccessControlType -eq 'Deny') -and ($ADObject.ObjectClass -eq 'organizationalUnit')) {
			if ($adRule.IdentityReference -eq 'everyone') { continue }
			$eSid = [System.Security.Principal.SecurityIdentifier]'S-1-1-0'
			$eName = $eSid.Translate([System.Security.Principal.NTAccount])
			if ($adRule.IdentityReference -eq $eName) { continue }
			if ($adRule.IdentityReference -eq $eSid) { continue }
		}
		#endregion Skip OUs' "Protect from Accidential Deletion" ACE

		foreach ($defaultRule in $DefaultRules) {
			if (Test-AccessRuleEquality -Parameters $parameters -Rule1 $adRule -Rule2 $defaultRule) {
				$null = $defaultRulesPresent.Add($defaultRule)
				continue outer
			}
		}
		$adRule
	}

	#region Foreach non-default AD Rule: Check whether configured and delete if not so
	:outer foreach ($relevantADRule in $relevantADRules) {
		foreach ($configuredRule in $ConfiguredRules) {
			if (Test-AccessRuleEquality -Parameters $parameters -Rule1 $relevantADRule -Rule2 $configuredRule) {
				# If explicitly defined for deletion, do so
				if ('False' -eq $configuredRule.Present) {
					Write-Result -Type Delete -Identity $relevantADRule.IdentityReference -ADObject $relevantADRule -DistinguishedName $ADObject
				}
				continue outer
			}
		}

		# Don't generate delete changes
		if ($processingMode -eq 'Additive') { continue }
		# Don't generate delete changes, unless we have configured a permission level for the affected identity
		if ($processingMode -eq 'Defined') {
			if (-not ($relevantADRule.IdentityReference | Compare-Identity -Parameters $parameters -ReferenceIdentity $ConfiguredRules.IdentityReference -IncludeEqual -ExcludeDifferent)) {
				continue
			}
		}

		Write-Result -Type Delete -Identity $relevantADRule.IdentityReference -ADObject $relevantADRule -DistinguishedName $ADObject
	}
	#endregion Foreach non-default AD Rule: Check whether configured and delete if not so

	#region Foreach configured rule: Check whether it exists as defined or make it so
	:outer foreach ($configuredRule in $ConfiguredRules) {
		foreach ($defaultRule in $DefaultRules) {
			if ('True' -ne $configuredRule.Present) { break }
			if ($configuredRule.NoFixConfig) { break }
			if (Test-AccessRuleEquality -Parameters $parameters -Rule1 $defaultRule -Rule2 $configuredRule) {
				Write-Result -Type FixConfig -Identity $defaultRule.IdentityReference -ADObject $defaultRule -Configuration $configuredRule -DistinguishedName $ADObject
				continue outer
			}
		}
		foreach ($relevantADRule in $relevantADRules) {
			if (Test-AccessRuleEquality -Parameters $parameters -Rule1 $relevantADRule -Rule2 $configuredRule) {
				continue outer
			}
		}
		# Do not generate Create rules for any rule not configured for creation
		if ('True' -ne $configuredRule.Present) { continue }
		Write-Result -Type Create -Identity $configuredRule.IdentityReference -Configuration $configuredRule -DistinguishedName $ADObject
	}
	#endregion Foreach configured rule: Check whether it exists as defined or make it so

	#region Foreach non-existent default rule: Create unless configured otherwise
	$domainControllersOUFilter = '*{0}' -f ('OU=Domain Controllers,%DomainDN%' | Resolve-String)
	:outer foreach ($defaultRule in $DefaultRules | Where-Object { $_ -notin $defaultRulesPresent.ToArray() }) {
		# Do not apply restore to Domain Controllers OU, as it is already deployed intentionally diverging from the OU defaults
		if ($ADObject -like $domainControllersOUFilter) { break }

		# Skip 'CREATOR OWNER' Rules, as those should never be restored.
		# When creating an AD object that has this group as default permissions, it will instead
		# Translate those to the identity creating the object
		if ('S-1-3-0' -eq $defaultRule.SID) { continue }

		foreach ($configuredRule in $ConfiguredRules) {
			if (Test-AccessRuleEquality -Parameters $parameters -Rule1 $defaultRule -Rule2 $configuredRule) {
				# If we explicitly don't want the rule: Skip and do NOT create a restoration action
				if ('True' -ne $configuredRule.Present) { continue outer }
			}
		}

		Write-Result -Type Restore -Identity $defaultRule.IdentityReference -Configuration $defaultRule -DistinguishedName $ADObject
	}
	#endregion Foreach non-existent default rule: Create unless configured otherwise
}