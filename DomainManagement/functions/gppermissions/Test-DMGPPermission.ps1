function Test-DMGPPermission {
	<#
	.SYNOPSIS
		Tests whether the existing Group Policy permissions reflect the desired state.

	.DESCRIPTION
		Tests whether the existing Group Policy permissions reflect the desired state.
		Use Register-DMGPPermission and Register-DMGPPermissionFilter to define the desired state.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Test-DMGPPermission -Server corp.contoso.com

		Tests whether the domain of corp.contoso.com has the desired GP Permission configuration.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

		[switch]
		$EnableException
	)
	
	begin {
		$parameters = Resolve-GPTargetServer -Server $Server -Credential $Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type GroupPolicyPermissions -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
		$psParameter = Resolve-GPTargetServer -Server $Server -Credential $Credential -ForRemoting
		try { $session = New-AdcPSSession @psParameter -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Test-DMGPPermission.WinRM.Failed' -StringValues $parameters.Server -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $parameters.Server
			return
		}

		#region Utility Functions
		function Compare-GPAccessRules {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
			[CmdletBinding()]
			param (
				[AllowNull()]
				[AllowEmptyCollection()]
				$ADRules,

				[AllowNull()]
				[AllowEmptyCollection()]
				$ConfiguredRules,

				[bool]
				$Managed
			)
			if (-not $Managed -and -not $ConfiguredRules) { return }
			
			$configuredRules | Where-Object {
				$_ -and
				-not ($_ | Compare-ObjectProperty -ReferenceObject $ADRules -PropertyName 'Identity to String', Permission, Allow)
			} | ForEach-Object {
				$_.Action = 'Add'
				$_
			}
			if (-not $Managed) { return }
			$ADRules | Where-Object {
				$_ -and
				-not ($_ | Compare-ObjectProperty -ReferenceObject $ConfiguredRules -PropertyName 'Identity to String', Permission, Allow)
			} | ForEach-Object {
				$_.Action = 'Remove'
				$_
			}
		}
		function Convert-GPAccessRuleIdentity {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$InputObject,

				$ADObject,

				[PSFComputer]
				$Server,
				
				[PSCredential]
				$Credential
			)

			begin {
				$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
				$parameters['Debug'] = $false
			}
			process {
				foreach ($inputItem in $InputObject) {
					#region Case: Input from AD
					if ($inputItem.PSObject.TypeNames -like "*Microsoft.GroupPolicy.GPPermission") {
						$result = [PSCustomObject]@{
							PSTypeName = 'DomainManagement.Result.GPPermission.Action'
							Identity = $inputItem.Trustee.Sid
							DisplayName = '{0}\{1}' -f $inputItem.Trustee.Domain, $inputItem.Trustee.Name
							Permission = $inputItem.Permission -as [string]
							Allow = -not $inputItem.Denied
							Action = $null
							ADObject = $ADObject
						}
						if ($result.DisplayName -eq '\') { $result.DisplayName = $inputItem.Trustee.Sid -as [string] }
						$result | Add-Member -MemberType ScriptMethod -Name ToString -Force -PassThru -Value {
							'{0}: {1}' -f $this.Action, $this.DisplayName
						}
					}
					#endregion Case: Input from AD

					#region Case: Input from Configuration
					else {
						# Convert to SecurityIdentifier (preferred) or NT Account
						$identity = Resolve-Identity -IdentityReference $inputItem.Identity
						if ($identity -is [System.Security.Principal.NTAccount]) {
							$domainName, $identityName = $identity -replace '^(.+)@(.+)$','$2\$1' -split "\\"
							try { $principal = Get-Principal @parameters -Name $identityName -Domain $domainName -ObjectClass $inputItem.ObjectClass }
							catch { throw }
							$identity = $principal.ObjectSID
						}
						$result = [PSCustomObject]@{
							PSTypeName = 'DomainManagement.Result.GPPermission.Action'
							Identity = $identity
							DisplayName = $inputItem.Identity | Resolve-String
							Permission = $inputItem.Permission
							Allow = -not $inputItem.Deny
							Action = $null
							ADObject = $ADObject
						}
						$result | Add-Member -MemberType ScriptMethod -Name ToString -Force -PassThru -Value {
							'{0}: {1}' -f $this.Action, $this.DisplayName
						}
					}
					#endregion Case: Input from Configuration
				}
			}
		}
		function Resolve-Identity {
			[CmdletBinding()]
			param (
				[string]
				$IdentityReference
			)

			#region Default Resolution
			$identity = Resolve-String -Text $IdentityReference
			if ($identity -as [System.Security.Principal.SecurityIdentifier]) {
				$identity = $identity -as [System.Security.Principal.SecurityIdentifier]
			}
			else {
				$identity = $identity -as [System.Security.Principal.NTAccount]
				try { $identity = $identity.Translate([System.Security.Principal.SecurityIdentifier])  }
				catch { $null = $null } # Do nothing intentionally, but shut up PSSA anyway
			}
			if ($null -eq $identity) { $identity = (Resolve-String -Text $IdentityReference) -as [System.Security.Principal.NTAccount] }

			$identity
			#endregion Default Resolution
		}
		#endregion Utility Functions
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }
		
		try {
			#region Data Preparation
			$allFilters = @{ }
			foreach ($filterObject in (Get-DMGPPermissionFilter)) {
				$allFilters[$filterObject.Name] = $filterObject
			}

			$allPermissions = Get-DMGPPermission
			$allConditions = $allPermissions | Where-Object FilterConditions | Select-Object -ExpandProperty FilterConditions | Write-Output | Select-Object -Unique
			$missingConditions = $allConditions | Where-Object { $_ -notin $allFilters.Keys }
			if ($missingConditions) {
				Stop-PSFFunction -String 'Test-DMGPPermission.Validate.MissingFilterConditions' -StringValues ($missingConditions -join ", ") -EnableException $EnableException -Cmdlet $PSCmdlet -Tag Error, Panic
				return
			}
			if ($allConditions) { $relevantFilters = $allFilters | ConvertTo-PSFHashtable -Include $allConditions }
			else { $relevantFilters = @() }

			$allGpos = Get-ADObject @parameters -LDAPFilter '(objectCategory=groupPolicyContainer)' -Properties DisplayName

			#region Process relevant filters
			$filterToGPOMapping = @{ }
			$managedGPONames = (Get-DMGroupPolicy).DisplayName | Resolve-String
			:conditions foreach ($condition in $relevantFilters.Values) {
				switch ($condition.Type) {
					#region Managed - Do we define the policy using the GroupPolicy Component?
					'Managed' {
						if ($condition.Reverse -xor (-not $condition.Managed)) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -notin $managedGPONames }
						else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -in $managedGPONames }
					}
					#endregion Managed - Do we define the policy using the GroupPolicy Component?

					#region Path - Resolve by where GPOs are linked
					'Path' {
						$searchBase = Resolve-String -Text $condition.Path
						if (-not (Test-ADObject @parameters -Identity $searchBase)) {
							if ($condition.Optional) {
								Write-PSFMessage -String 'Test-DMGPPermission.Filter.Path.DoesNotExist.SilentlyContinue' -StringValues $Condition.Name, $searchBase -Target $condition
								continue conditions
							}
							Stop-PSFFunction -String 'Test-DMGPPermission.Filter.Path.DoesNotExist.Stop' -StringValues $searchBase -Target $Condition.Name, $condition -EnableException $EnableException -Tag Panic, Error
							return
						}

						$objects = Get-ADObject @parameters -SearchBase $searchBase -SearchScope $condition.Scope -LDAPFilter '(|(objectCategory=OrganizationalUnit)(objectCategory=domainDNS))' -Properties gPLink
						$allLinkedGpoDNs = $objects | ConvertTo-GPLink | Select-Object -ExpandProperty DistinguishedName -Unique
						if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DistinguishedName -notin $allLinkedGpoDNs }
						else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DistinguishedName -in $allLinkedGpoDNs }
					}
					#endregion Path - Resolve by where GPOs are linked

					#region GPName - Match by name, using either direct comparison, wildcard or regex
					'GPName' {
						$resolvedGpoName = Resolve-String -Text $condition.GPName
						switch ($condition.Mode) {
							'Explicit' {
								if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -ne $resolvedGpoName }
								else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -eq $resolvedGpoName }
							}
							'Wildcard' {
								if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -notlike $resolvedGpoName }
								else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -like $resolvedGpoName }
							}
							'Regex' {
								if ($condition.Reverse) { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -notmatch $resolvedGpoName }
								else { $filterToGPOMapping[$condition.Name] = $allGpos | Where-Object DisplayName -match $resolvedGpoName }
							}
						}
					}
					#endregion GPName - Match by name, using either direct comparison, wildcard or regex
				}
			}
			foreach ($key in $filterToGPOMapping.Keys) {
				Write-PSFMessage -Level Debug -String 'Test-DMGPPermission.Filter.Result' -StringValues $key, ($filterToGPOMapping[$key].DisplayName -join ', ')
			}
			#endregion Process relevant filters

			#endregion Data Preparation

			#region Process GPO Permissions
			$domainObject = Get-Domain2 @parameters
			$permissionObjects = Invoke-Command -Session $session -ScriptBlock {
				Update-TypeData -TypeName Microsoft.GroupPolicy.GPPermission -SerializationDepth 4
				foreach ($policyObject in $using:allGpos) {
					$resultObject = [PSCustomObject]@{
						Name        = $policyObject.DisplayName
						Permissions = @()
						Error       = $null
					}

					try { $resultObject.Permissions = Get-GPPermission -All -Name $resultObject.Name -Server localhost -Domain $using:domainObject.DNSRoot -ErrorAction Stop }
					catch { $resultObject.Error = $_ }
					$resultObject
				}
			}

			$resultDefaults = @{
				Server = $parameters.Server
				ObjectType = 'GPPermission'
			}

			foreach ($permissionObject in $permissionObjects) {
				$applicableSettings = $allPermissions | Where-Object {
					$_.All -or
					(Resolve-String -Text $_.GpoName) -eq $permissionObject.Name -or
					($_.Filter -and (Test-GPPermissionFilter -GpoName $permissionObject.Name -Filter $_.Filter -Conditions $_.FilterConditions -FilterHash $filterToGPOMapping))
				}
				$adObject = $allGpos | Where-Object DisplayName -eq $permissionObject.Name
				Add-Member -InputObject $permissionObject -MemberType ScriptMethod -Name ToString -Value { $this.Name } -Force

				if ($permissionObject.Error) {
					New-TestResult @resultDefaults -Type AccessError -Identity $permissionObject -Configuration $applicableSettings -ADObject $adObject -Changed $permissionObject
					continue
				}

				$shouldManage = $applicableSettings.Managed -contains $true
				try {
					$compareParameter = @{
						ADRules = ($permissionObject.Permissions | Convert-GPAccessRuleIdentity @parameters -ADObject $adObject)
						ConfiguredRules = ($applicableSettings | Where-Object Identity | Convert-GPAccessRuleIdentity @parameters -ADObject $adObject)
						Managed = $shouldManage
					}
				}
				catch {
					Stop-PSFFunction -String 'Test-DMGPPermission.Identity.Resolution.Error' -StringValues $adObject.DisplayName -Target $permissionObject -Continue -EnableException $EnableException -Tag Panic, Error
				}
				$delta = Compare-GPAccessRules @compareParameter

				if ($delta) {
					New-TestResult @resultDefaults -Type Update -Identity $permissionObject -Changed $delta -Configuration $applicableSettings -ADObject $adObject
					continue
				}
			}
			#endregion Process GPO Permissions
		}
		finally {
			if ($session) { $session | Remove-PSSession -WhatIf:$false -Confirm:$false}
		}
	}
}