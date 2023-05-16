function Invoke-DMGPLink {
	<#
	.SYNOPSIS
		Applies the desired group policy linking configuration.
	
	.DESCRIPTION
		Applies the desired group policy linking configuration.
		Use Register-DMGPLink to define the desired state.
		
		Note: Invoke-DMGroupPolicy uses links to safely determine GPOs it can delete!
		It will look for GPOs that have been linked to managed folders in order to avoid fragile name lookups.
		Removing the old links before cleaning up the associated GPOs might leave orphaned GPOs in your domain.
		To avoid deleting old links, use the -Disable parameter.

		Recommended execution order:
		- Invoke GPOs (without deletion)
		- Invoke GPLinks (with -Disable)
		- Invoke GPOs (with deletion)
		- Invoke GPLinks (without -Disable)
	
	.PARAMETER InputObject
		Test results provided by the associated test command.
		Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER Disable
		By default, undesired links are removed.
		With this parameter set it will instead disable undesired links.
		Use this in order to not lose track of previously linked GPOs.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.

	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Invoke-DMGPLink

		Configures the current domain's group policy links as desired.
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

		[switch]
		$Disable,

		[switch]
		$EnableException
	)
	
	begin {
		#region Utility Functions
		function Clear-Link {
			[CmdletBinding()]
			param (
				[PSFComputer]
				$Server,
				
				[PSCredential]
				$Credential,

				$ADObject,

				[bool]
				$Disable
			)
			$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

			if (-not $Disable) {
				Set-ADObject @parameters -Identity $ADObject -Clear gPLink -ErrorAction Stop
				return
			}
			Set-ADObject @parameters -Identity $ADObject -Replace @{ gPLink = ($ADObject.gPLink -replace ";\d\]", ";1]") } -ErrorAction Stop -Confirm:$false
		}

		function New-Link {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				[PSFComputer]
				$Server,
				
				[PSCredential]
				$Credential,

				$ADObject,

				$Configuration,

				[Hashtable]
				$GpoNameMapping
			)
			$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

			$gpLinkString = ($Configuration.Include | Sort-Object -Property @{ Expression = { $_.Tier }; Descending = $false }, Precedence -Descending | ForEach-Object {
					$gpoDN = $GpoNameMapping[(Resolve-String -Text $_.PolicyName)]
					if (-not $gpoDN) {
						Write-PSFMessage -Level Warning -String 'Invoke-DMGPLink.New.GpoNotFound' -StringValues (Resolve-String -Text $_.PolicyName) -Target $ADObject -FunctionName Invoke-DMGPLink
						return
					}
					$stateID = "0"
					if ($_.State -eq 'Enforced') { $stateID = "2" }
					if ($_.State -eq 'Disabled') { $stateID = "1" }
					"[LDAP://$gpoDN;$stateID]"
				}) -Join ""
			Write-PSFMessage -Level Debug -String 'Invoke-DMGPLink.New.NewGPLinkString' -StringValues $ADObject.DistinguishedName, $gpLinkString -Target $ADObject -FunctionName Invoke-DMGPLink
			Set-ADObject @parameters -Identity $ADObject -Replace @{ gPLink = $gpLinkString } -ErrorAction Stop -Confirm:$false
		}

		function Update-Link {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				[PSFComputer]
				$Server,
				
				[PSCredential]
				$Credential,

				$ADObject,

				$Configuration,

				[bool]
				$Disable,

				[Hashtable]
				$GpoNameMapping,

				$Changes
			)
			$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

			$gpLinkString = ''
			if ($Disable) {
				$desiredDNs = $Configuration.ExtendedInclude.PolicyName | Resolve-String | ForEach-Object { $GpoNameMapping[$_] }
				$gpLinkString += ($ADobject.LinkedGroupPolicyObjects | Where-Object DistinguishedName -NotIn $desiredDNs | Sort-Object -Property Precedence -Descending | ForEach-Object {
						"[LDAP://$($_.DistinguishedName);1]"
					}) -join ""
			}
			
			$gpLinkString += ($Configuration.ExtendedInclude | Where-Object DistinguishedName | Sort-Object -Property @{ Expression = { $_.Tier }; Descending = $false }, Precedence -Descending | ForEach-Object {
					$_.ToLink()
				}) -Join ""
			$msgParam = @{
				Level        = 'SomewhatVerbose'
				Tag          = 'change'
				Target       = $ADObject
				FunctionName = 'Invoke-DMGPLink'
			}
			Write-PSFMessage @msgParam -String 'Invoke-DMGPLink.Update.OldGPLinkString' -StringValues $ADObject.DistinguishedName, $ADObject.gPLink
			foreach ($change in $Changes) {
				Write-PSFMessage @msgParam -String 'Invoke-DMGPLink.Update.Change' -StringValues $change.Action, $change.Policy, $ADObject.DistinguishedName
			}
			Write-PSFMessage @msgParam -String 'Invoke-DMGPLink.Update.NewGPLinkString' -StringValues $ADObject.DistinguishedName, $gpLinkString
			Set-ADObject @parameters -Identity $ADObject -Replace @{ gPLink = $gpLinkString } -ErrorAction Stop -Confirm:$false
		}
		#endregion Utility Functions

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type GroupPolicyLinks, GroupPolicyLinksDynamic -Cmdlet $PSCmdlet
		
		$gpoDisplayToDN = @{ }
		$gpoDNToDisplay = @{ }
		foreach ($adPolicyObject in (Get-ADObject @parameters -LDAPFilter '(objectCategory=groupPolicyContainer)' -Properties DisplayName, DistinguishedName)) {
			$gpoDisplayToDN[$adPolicyObject.DisplayName] = $adPolicyObject.DistinguishedName
			$gpoDNToDisplay[$adPolicyObject.DistinguishedName] = $adPolicyObject.DisplayName
		}
	}
	process {
		if (-not $InputObject) {
			$InputObject = Test-DMGPLink @parameters
		}
		
		#region Executing Test-Results
		foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.GPLink.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMGPLink', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			$countConfigured = ($testItem.Configuration | Measure-Object).Count
			$countActual = ($testItem.ADObject.LinkedGroupPolicyObjects | Measure-Object).Count
			$countNotInConfig = ($testItem.ADObject.LinkedGroupPolicyObjects | Where-Object DistinguishedName -NotIn ($testItem.Configuration.PolicyName | Remove-PSFNull | Resolve-String | ForEach-Object { $gpoDisplayToDN[$_] }) | Measure-Object).Count

			switch ($testItem.Type) {
				'Delete' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Delete.AllEnabled' -ActionStringValues $countActual -Target $testItem -ScriptBlock {
						Clear-Link @parameters -ADObject $testItem.ADObject -Disable $Disable -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Create' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.New' -ActionStringValues $countConfigured -Target $testItem -ScriptBlock {
						New-Link @parameters -ADObject $testItem.ADObject -Configuration $testItem.Configuration -GpoNameMapping $gpoDisplayToDN -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Update' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Update.AllEnabled' -ActionStringValues $countConfigured, $countActual, $countNotInConfig -Target $testItem -ScriptBlock {
						Update-Link @parameters -ADObject $testItem.ADObject -Configuration $testItem.Configuration -Disable $Disable -GpoNameMapping $gpoDisplayToDN -Changes $testItem.Changed -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'GpoMissing' {
					Write-PSFMessage -Level Warning -String 'Invoke-DMGPLink.GpoMissing' -StringValues $testItem.ADObject, (($testItem.Changed | Where-Object Action -EQ 'GpoMissing').Policy -join ", ")
				}
			}
		}
		#endregion Executing Test-Results
	}
}
