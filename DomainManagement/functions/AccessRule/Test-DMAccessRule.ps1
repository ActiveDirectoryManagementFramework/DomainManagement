function Test-DMAccessRule
{
	<#
	.SYNOPSIS
		Validates the targeted domain's Access Rule configuration.
	
	.DESCRIPTION
		Validates the targeted domain's Access Rule configuration.
		This is done by comparing each relevant object's non-inherited permissions with the Schema-given default permissions for its object type.
		Then the remaining explicit permissions that are not part of the schema default are compared with the configured desired state.

		The desired state can be defined using Register-DMAccessRule.
		Basically, two kinds of rules are supported:
		- Path based access rules - point at a DN and tell the system what permissions should be applied.
		- Rule based access rules - All objects matching defined conditions will be affected by the defined rules.
		To define rules - also known as Object Categories - use Register-DMObjectCategory.
		Example rules could be "All Domain Controllers" or "All Service Connection Points with the name 'Virtual Machine'"

		This command will test all objects that ...
		- Have at least one path based rule.
		- Are considered as "under management", as defined using Set-DMContentMode
		It uses a definitive approach - any access rule not defined will be flagged for deletion!
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMAccessRule -Server fabrikam.com

		Tests, whether the fabrikam.com domain conforms to the configured, desired state.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		#region Utility Functions
		function Compare-AccessRules {
			[CmdletBinding()]
			param (
				$ADRules,
				$ConfiguredRules,
				$DefaultRules,
				$ADObject
			)

			function Write-Result {
				[CmdletBinding()]
				param (
					[ValidateSet('Create', 'Delete', 'FixConfig')]
					[Parameter(Mandatory = $true)]
					$Type,

					$Identity,

					[AllowNull()]
					$ADObject,

					[AllowNull()]
					$Configuration
				)

				$item = [PSCustomObject]@{
					Type = $Type
					Identity = $Identity
					ADObject = $ADObject
					Configuration = $Configuration
				}
				Add-Member -InputObject $item -MemberType ScriptMethod ToString -Value { '{0}: {1}' -f $this.Type, $this.Identity } -Force -PassThru
			}

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
					if (Test-AccessRuleEquality -Rule1 $adRule -Rule2 $defaultRule) { continue outer }
				}
				$adRule
			}

			:outer foreach ($relevantADRule in $relevantADRules) {
				foreach ($configuredRule in $ConfiguredRules) {
					if (Test-AccessRuleEquality -Rule1 $relevantADRule -Rule2 $configuredRule) { continue outer }
				}
				Write-Result -Type Delete -Identity $relevantADRule.IdentityReference -ADObject $relevantADRule
			}

			:outer foreach ($configuredRule in $ConfiguredRules) {
				foreach ($defaultRules in $DefaultRules) {
					if (Test-AccessRuleEquality -Rule1 $defaultRules -Rule2 $configuredRule) {
						Write-Result -Type FixConfig -Identity $defaultRule.IdentityReference -ADObject $defaultRule -Configuration $configuredRule
						continue outer
					}
				}
				foreach ($relevantADRule in $relevantADRules) {
					if (Test-AccessRuleEquality -Rule1 $relevantADRule -Rule2 $configuredRule) { continue outer }
				}
				Write-Result -Type Create -Identity $configuredRule.IdentityReference -Configuration $configuredRule
			}
		}

		function Convert-AccessRule {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$Rule,

				[Parameter(Mandatory = $true)]
				$ADObject,

				[PSFComputer]
				$Server,

				[PSCredential]
				$Credential
			)
			begin {
				$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
				$convertCmdName = { Convert-DMSchemaGuid @parameters -OutType Name }.GetSteppablePipeline()
				$convertCmdName.Begin($true)
				$convertCmdGuid = { Convert-DMSchemaGuid @parameters -OutType Guid }.GetSteppablePipeline()
				$convertCmdGuid.Begin($true)
			}
			process {
				foreach ($ruleObject in $Rule) {
					$objectTypeGuid = $convertCmdGuid.Process($ruleObject.ObjectType)[0]
					$objectTypeName = $convertCmdName.Process($ruleObject.ObjectType)[0]
					$inheritedObjectTypeGuid = $convertCmdGuid.Process($ruleObject.InheritedObjectType)[0]
					$inheritedObjectTypeName = $convertCmdName.Process($ruleObject.InheritedObjectType)[0]

					try { $identity = Resolve-Identity @parameters -IdentityReference $ruleObject.IdentityReference -ADObject $ADObject }
					catch { Stop-PSFFunction -String 'Convert-AccessRule.Identity.ResolutionError' -Target $ruleObject -ErrorRecord $_ -Continue }

					[PSCustomObject]@{
						PSTypeName = 'DomainManagement.AccessRule.Converted'
						IdentityReference = $identity
						AccessControlType = $ruleObject.AccessControlType
						ActiveDirectoryRights = $ruleObject.ActiveDirectoryRights
						InheritanceFlags = $ruleObject.InheritanceFlags
						InheritanceType = $ruleObject.InheritanceType
						InheritedObjectType = $inheritedObjectTypeGuid
						InheritedObjectTypeName = $inheritedObjectTypeName
						ObjectFlags = $ruleObject.ObjectFlags
						ObjectType = $objectTypeGuid
						ObjectTypeName = $objectTypeName
						PropagationFlags = $ruleObject.PropagationFlags
					}
				}
			}
			end {
				#region Inject Category-Based rules
				Get-CategoryBasedRules -ADObject $ADObject @parameters -ConvertNameCommand $convertCmdName -ConvertGuidCommand $convertCmdGuid
				#endregion Inject Category-Based rules

				$convertCmdName.End()
				$convertCmdGuid.End()
			}
		}

		function Convert-AccessRuleIdentity {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				[System.DirectoryServices.ActiveDirectoryAccessRule[]]
				$InputObject,

				[PSFComputer]
				$Server,

				[PSCredential]
				$Credential
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
						$identity = Get-Principal @parameters -Sid $accessRule.IdentityReference -Domain $domainObject.DNSRoot -OutputType NTAccount
					}
					else {
						$identity = Get-Principal @parameters -Sid $accessRule.IdentityReference -Domain $accessRule.IdentityReference -OutputType NTAccount
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

		function Resolve-Identity {
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

		function Get-CategoryBasedRules {
			[CmdletBinding()]
			param (
				[Parameter(Mandatory = $true)]
				$ADObject,

				[PSFComputer]
				$Server,

				[PSCredential]
				$Credential,

				$ConvertNameCommand,

				$ConvertGuidCommand
			)

			$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ADObject, Server, Credential

			$resolvedCategories = Resolve-DMObjectCategory @parameters
			foreach ($resolvedCategory in $resolvedCategories) {
				foreach ($ruleObject in $script:accessCategoryRules[$resolvedCategory.Name]) {
					$objectTypeGuid = $ConvertGuidCommand.Process($ruleObject.ObjectType)[0]
					$objectTypeName = $ConvertNameCommand.Process($ruleObject.ObjectType)[0]
					$inheritedObjectTypeGuid = $ConvertGuidCommand.Process($ruleObject.InheritedObjectType)[0]
					$inheritedObjectTypeName = $ConvertNameCommand.Process($ruleObject.InheritedObjectType)[0]

					try { $identity = Resolve-Identity @parameters -IdentityReference $ruleObject.IdentityReference }
					catch { Stop-PSFFunction -String 'Convert-AccessRule.Identity.ResolutionError' -Target $ruleObject -ErrorRecord $_ -Continue }

					[PSCustomObject]@{
						PSTypeName = 'DomainManagement.AccessRule.Converted'
						IdentityReference = $identity
						AccessControlType = $ruleObject.AccessControlType
						ActiveDirectoryRights = $ruleObject.ActiveDirectoryRights
						InheritanceFlags = $ruleObject.InheritanceFlags
						InheritanceType = $ruleObject.InheritanceType
						InheritedObjectType = $inheritedObjectTypeGuid
						InheritedObjectTypeName = $inheritedObjectTypeName
						ObjectFlags = $ruleObject.ObjectFlags
						ObjectType = $objectTypeGuid
						ObjectTypeName = $objectTypeName
						PropagationFlags = $ruleObject.PropagationFlags
					}
				}
			}
		}
		#endregion Utility Functions

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type accessRules -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters

		try { $null = Get-DMObjectDefaultPermission -ObjectClass top @parameters }
		catch {
			Stop-PSFFunction -String 'Test-DMAccessRule.DefaultPermission.Failed' -StringValues $Server -Target $Server -EnableException $false -ErrorRecord $_
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		#region Process Configured Objects
		foreach ($key in $script:accessRules.Keys) {
			$resolvedPath = Resolve-String -Text $key

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'AccessRule'
				Identity = $resolvedPath
				Configuration = $script:accessRules[$key]
			}

			if (-not (Test-ADObject @parameters -Identity $resolvedPath)) {
				if ($script:accessRules[$key].Optional -notcontains $false) { continue }
				New-TestResult @resultDefaults -Type 'MissingADObject'
				continue
			}
			try { $adAclObject = Get-AdsAcl @parameters -Path $resolvedPath -EnableException }
			catch {
				if ($script:accessRules[$key].Optional -notcontains $false) { continue }
				Write-PSFMessage -String 'Test-DMAccessRule.NoAccess' -StringValues $resolvedPath -Tag 'panic','failed' -Target $script:accessRules[$key] -ErrorRecord $_
				New-TestResult @resultDefaults -Type 'NoAccess'
				Continue
			}

			$adObject = Get-ADObject @parameters -Identity $resolvedPath
			
			$defaultPermissions = Get-DMObjectDefaultPermission @parameters -ObjectClass $adObject.ObjectClass
			$delta = Compare-AccessRules -ADRules ($adAclObject.Access | Convert-AccessRuleIdentity @parameters) -ConfiguredRules ($script:accessRules[$key] | Convert-AccessRule @parameters -ADObject $adObject) -DefaultRules $defaultPermissions -ADObject $adObject

			if ($delta) {
				New-TestResult @resultDefaults -Type Update -Changed $delta -ADObject $adAclObject
				continue
			}
		}
		#endregion Process Configured Objects

		#region Process Non-Configured AD Objects
		$resolvedConfiguredObjects = $script:accessRules.Keys | Resolve-String

		$foundADObjects = foreach ($searchBase in (Resolve-ContentSearchBase @parameters -NoContainer)) {
			Get-ADObject @parameters -LDAPFilter '(objectCategory=*)' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope
		}

		$resultDefaults = @{
			Server = $Server
			ObjectType = 'AccessRule'
		}

		$convertCmdName = { Convert-DMSchemaGuid @parameters -OutType Name }.GetSteppablePipeline()
		$convertCmdName.Begin($true)
		$convertCmdGuid = { Convert-DMSchemaGuid @parameters -OutType Guid }.GetSteppablePipeline()
		$convertCmdGuid.Begin($true)

		foreach ($foundADObject in $foundADObjects) {
			# Skip items that were defined in configuration, they were already processed
			if ($foundADObject.DistinguishedName -in $resolvedConfiguredObjects) { continue }

			$compareParam = @{
				ADRules = ((Get-AdsAcl @parameters -Path $foundADObject.DistinguishedName).Access | Convert-AccessRuleIdentity @parameters)
				DefaultRules = Get-DMObjectDefaultPermission @parameters -ObjectClass $foundADObject.ObjectClass
				ConfiguredRules = Get-CategoryBasedRules -ADObject $foundADObject @parameters -ConvertNameCommand $convertCmdName -ConvertGuidCommand $convertCmdGuid
				ADObject = $foundADObject
			}
			$delta = Compare-AccessRules @compareParam

			if ($delta) {
				New-TestResult @resultDefaults -Type Update -Changed $delta -ADObject $adAclObject -Identity $foundADObject.DistinguishedName
				continue
			}
		}

		$convertCmdName.End()
		$convertCmdGuid.End()
		#endregion Process Non-Configured AD Objects
	}
}
