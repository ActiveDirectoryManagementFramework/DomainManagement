function Test-DMAccessRule {
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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type accessRules -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters

		try { $null = Get-AdcObjectDefaultPermission -ObjectClass top @parameters }
		catch {
			Stop-PSFFunction -String 'Test-DMAccessRule.DefaultPermission.Failed' -StringValues $Server -Target $Server -EnableException $false -ErrorRecord $_
			return
		}

		$systemContainer = (Get-ADDomain @parameters).SystemsContainer
		$adminSDHolderRules = (Get-AdsAcl -Path "CN=AdminSDHolder,$systemContainer" @parameters).Access
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }

		#region Process Configured Objects
		foreach ($key in $script:accessRules.Keys) {
			$resolvedPath = Resolve-String -Text $key

			$resultDefaults = @{
				Server        = $Server
				ObjectType    = 'AccessRule'
				Identity      = $resolvedPath
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
				Write-PSFMessage -String 'Test-DMAccessRule.NoAccess' -StringValues $resolvedPath -Tag 'panic', 'failed' -Target $script:accessRules[$key] -ErrorRecord $_
				New-TestResult @resultDefaults -Type 'NoAccess'
				Continue
			}

			$adObject = Get-ADObject @parameters -Identity $resolvedPath -Properties adminCount
			
			if ($adObject.adminCount) {
				$defaultPermissions = @()
				$desiredPermissions = $adminSDHolderRules
			}
			else {
				$defaultPermissions = Get-AdcObjectDefaultPermission @parameters -ObjectClass $adObject.ObjectClass
				$desiredPermissions = $script:accessRules[$key] | ConvertFrom-AdcAccessRuleConfiguration @parameters -ADObject $adObject -IncludeCategory -CategoryRules $script:accessCategoryRules
			}

			$delta = Compare-AdcAccessRules @parameters -ADRules ($adAclObject.Access | Convert-AdcAccessRuleIdentity @parameters -Target $adAclObject.DistinguishedName) -ConfiguredRules $desiredPermissions -DefaultRules $defaultPermissions -ADObject $adObject

			if ($delta) {
				New-TestResult @resultDefaults -Type Update -Changed $delta -ADObject $adAclObject
				continue
			}
		}
		#endregion Process Configured Objects

		if ($script:contentMode.ExcludeComponents.AccessRules) { return }

		$doParallelize = Get-PSFConfigValue -FullName 'DomainManagement.AccessRules.Parallelize'
		#region Process Non-Configured AD Objects - Serial
		if (-not $doParallelize) {
			$resolvedConfiguredObjects = $script:accessRules.Keys | Resolve-String
	
			$foundADObjects = foreach ($searchBase in (Resolve-ContentSearchBase @parameters -NoContainer)) {
				Get-ADObject @parameters -LDAPFilter '(objectCategory=*)' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope -Properties adminCount
			}
	
			$resultDefaults = @{
				Server     = $Server
				ObjectType = 'AccessRule'
			}
	
			$convertCmdName = { Convert-AdcSchemaGuid @parameters -OutType Name }.GetSteppablePipeline()
			$convertCmdName.Begin($true)
			$convertCmdGuid = { Convert-AdcSchemaGuid @parameters -OutType Guid }.GetSteppablePipeline()
			$convertCmdGuid.Begin($true)
	
			$processed = @{ }
			foreach ($foundADObject in $foundADObjects) {
				# Prevent duplicate processing
				if ($processed[$foundADObject.DistinguishedName]) { continue }
				$processed[$foundADObject.DistinguishedName] = $true

				# Skip GPOs, as those are handled within the GP Permissions Component
				if ($foundADObject.DistinguishedName -match 'CN={[^,]+},CN=Policies,CN=System,') { continue }
	
				# Skip items that were defined in configuration, they were already processed
				if ($foundADObject.DistinguishedName -in $resolvedConfiguredObjects) { continue }
	
				$adAclObject = Get-AdsAcl @parameters -Path $foundADObject.DistinguishedName
				$compareParam = @{
					ADRules         = $adAclObject.Access | Convert-AdcAccessRuleIdentity @parameters
					DefaultRules    = Get-AdcObjectDefaultPermission @parameters -ObjectClass $foundADObject.ObjectClass
					ConfiguredRules = Get-AdcCategoryBasedRules -ADObject $foundADObject @parameters -ConvertNameCommand $convertCmdName -ConvertGuidCommand $convertCmdGuid -CategoryRules $script:accessCategoryRules
					ADObject        = $foundADObject
				}
	
				# Protected Objects
				if ($foundADObject.AdminCount) {
					$compareParam.DefaultRules = @()
					$compareParam.ConfiguredRules = $adminSDHolderRules
				}
	
				$compareParam += $parameters
				$delta = Compare-AdcAccessRules @compareParam
	
				if ($delta) {
					New-TestResult @resultDefaults -Type Update -Changed $delta -ADObject $adAclObject -Identity $foundADObject.DistinguishedName
					continue
				}
			}
	
			$convertCmdName.End()
			$convertCmdGuid.End()

			return
		}
		#endregion Process Non-Configured AD Objects - Serial

		#region Process Non-Configured AD Objects - Parallel
		#region Prepare Runspace Environment
		$variables = @{
			resultDefaults           = @{
				Server     = $Server
				ObjectType = 'AccessRule'
			}
			parameters               = $parameters
			adminSDHolderRules       = $adminSDHolderRules
			schemaDefaultPermissions = $script:schemaObjectDefaultPermission["$Server"]
			accessRuleConfiguration  = @{
				accessRules         = $script:accessRules
				accessCategoryRules = $script:accessCategoryRules
			}
			objectCategorySettings   = $script:objectCategories
			stringTable              = $script:nameReplacementTable
		}
		$modules = @(
			(Get-Module ADMF.Core).ModuleBase
			(Get-Module DomainManagement).ModuleBase
			(Get-Module ADSec).ModuleBase
		)
		$functions = @{
			'New-TestResult' = [ScriptBlock]::Create((Get-Command -Name New-TestResult).Definition)
		}

		$begin = {
			$null = Get-Acl -Path .
			& (Get-Module DomainManagement) {
				$script:schemaObjectDefaultPermission["$($global:parameters.Server)"] = $global:schemaDefaultPermissions.Clone()
				$script:accessRules = $global:accessRuleConfiguration.accessRules.Clone()
				$script:accessCategoryRules = $global:accessRuleConfiguration.accessCategoryRules.Clone()
				$script:nameReplacementTable = $global:stringTable.Clone()
				$script:objectCategories = $global:objectCategorySettings.Clone()
				foreach ($__category in $script:objectCategories.Values) {
					if ($__category.TestScript -is [scriptblock]) {
						$__category.TestScript = ([PsfScriptBlock]$__category.TestScript).ToGlobal()
					}
				}
			}

			$global:convertCmdName = { Convert-AdcSchemaGuid @parameters -OutType Name }.GetSteppablePipeline()
			$global:convertCmdName.Begin($true)
			$global:convertCmdGuid = { Convert-AdcSchemaGuid @parameters -OutType Guid }.GetSteppablePipeline()
			$global:convertCmdGuid.Begin($true)

			$global:cmdCompareAccessRules = Get-Command Compare-AdcAccessRules
			$global:cmdConvertAccessRuleIdentity = Get-Command Convert-AdcAccessRuleIdentity
			$global:cmdGetCategoryBasedRules = Get-Command Get-AdcCategoryBasedRules
		}
		$process = {
			$count = 0
			do {
				try {
					$foundADObject = $_
					$adAclObject = Get-AdsAcl @parameters -Path $foundADObject.DistinguishedName
					$compareParam = @{
						ADRules         = & $global:cmdConvertAccessRuleIdentity -InputObject $adAclObject.Access @parameters
						DefaultRules    = Get-AdcObjectDefaultPermission @parameters -ObjectClass $foundADObject.ObjectClass
						ConfiguredRules = & $global:cmdGetCategoryBasedRules -ADObject $foundADObject @parameters -ConvertNameCommand $convertCmdName -ConvertGuidCommand $convertCmdGuid
						ADObject        = $foundADObject
					}

					# Protected Objects
					if ($foundADObject.AdminCount) {
						$compareParam.DefaultRules = @()
						$compareParam.ConfiguredRules = $adminSDHolderRules
					}

					$compareParam += $parameters
					$delta = & $global:cmdCompareAccessRules @compareParam
				}
				catch {
					$count++
					if ($count -lt 10) { continue }

					$fail = [PSCustomObject]@{
						ADObject = $foundADObject
						Acl      = $adAclObject
						Error    = $_
					}
					Write-PSFRunspaceQueue -Name fails -Value $fail
					break
				}

				if ($delta) {
					New-TestResult @resultDefaults -Type Update -Changed $delta -ADObject $adAclObject -Identity $foundADObject.DistinguishedName
				}

				break
			}
			while ($true)
		}
		$end = {
			$global:convertCmdName.End()
			$global:convertCmdGuid.End()
		}

		$param = @{
			Name          = 'AccessRuleProcessor'
			Count         = (Get-PSFConfigValue -FullName 'DomainManagement.AccessRules.Threads' -Fallback 4)
			InQueue       = 'input'
			OutQueue      = 'results'
			Functions     = $functions
			Modules       = $modules
			Variables     = $variables

			Begin         = $begin
			Process       = $process
			End           = $end

			CloseOutQueue = $true
		}
		#endregion Prepare Runspace Environment

		$workflow = New-PSFRunspaceWorkflow -Name 'DomainManagement.AccessRules' -Force
		$null = $workflow | Add-PSFRunspaceWorker @param

		$resolvedConfiguredObjects = $script:accessRules.Keys | Resolve-String
	
		$foundADObjects = foreach ($searchBase in (Resolve-ContentSearchBase @parameters -NoContainer)) {
			Get-ADObject @parameters -LDAPFilter '(objectCategory=*)' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope -Properties adminCount
		}

		$processed = @{ }
		foreach ($foundADObject in $foundADObjects) {
			# Prevent duplicate processing
			if ($processed[$foundADObject.DistinguishedName]) { continue }
			$processed[$foundADObject.DistinguishedName] = $true

			# Skip items that were defined in configuration, they were already processed
			if ($foundADObject.DistinguishedName -in $resolvedConfiguredObjects) { continue }

			Write-PSFRunspaceQueue -Name input -InputObject $workflow -Value $foundADObject
		}
		$workflow.Queues.input.Closed = $true

		try {
			$workflow | Start-PSFRunspaceWorkflow
			$workflow | Wait-PSFRunspaceWorkflow -WorkerName AccessRuleProcessor -Closed -PassThru | Stop-PSFRunspaceWorkflow
			$fails = Read-PSFRunspaceQueue -InputObject $workflow -Name fails -All
			foreach ($fail in $fails) {
				Write-PSFMessage -Level Warning -String 'Test-DMAccessRule.Parallel.Error' -StringValues $fail.ADObject -ErrorRecord $fail.Error -Target $fail
			}
			
			$results = Read-PSFRunspaceQueue -InputObject $workflow -Name results -All
			# Fix String Presentation for objects from a background runspace
			$results | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Identity } -Force
			$results.Changed | Add-Member -MemberType ScriptMethod ToString -Value { '{0}: {1}' -f $this.Type, $this.Identity } -Force
			$results
		}
		finally {
			$workflow | Remove-PSFRunspaceWorkflow
		}
		#endregion Process Non-Configured AD Objects - Parallel
	}
}
