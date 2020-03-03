function Invoke-DMGPLink
{
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
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

		[switch]
		$Disable,

		[switch]
		$EnableException
	)
	
	begin
	{
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
			Set-ADObject @parameters -Identity $ADObject -Replace @{ gPLink = ($ADObject.gPLink -replace ";\d\]",";1]") } -ErrorAction Stop
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

			$gpLinkString = ($Configuration | Sort-Object -Property Precedence -Descending | ForEach-Object {
				$gpoDN = $GpoNameMapping[(Resolve-String -Text $_.PolicyName)]
				if (-not $gpoDN) {
					Write-PSFMessage -Level Warning -String 'Invoke-DMGPLink.New.GpoNotFound' -StringValues (Resolve-String -Text $_.PolicyName) -Target $ADObject -FunctionName Invoke-DMGPLink
					return
				}
				"[LDAP://$gpoDN;0]"
			}) -Join ""
			Write-PSFMessage -Level Debug -String 'Invoke-DMGPLink.New.NewGPLinkString' -StringValues $ADObject.DistinguishedName, $gpLinkString -Target $ADObject -FunctionName Invoke-DMGPLink
			Set-ADObject @parameters -Identity $ADObject -Replace @{ gPLink = $gpLinkString } -ErrorAction Stop
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
				$GpoNameMapping
			)
			$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

			$gpLinkString = ''
			if ($Disable) {
				$desiredDNs = $Configuration.PolicyName | Resolve-String | ForEach-Object { $GpoNameMapping[$_] }
				$gpLinkString += ($ADobject.LinkedGroupPolicyObjects | Where-Object DistinguishedName -NotIn $desiredDNs | Sort-Object -Property Precedence -Descending | ForEach-Object {
					"[LDAP://$($_.DistinguishedName);1]"
				}) -join ""
			}
			
			$gpLinkString += ($Configuration | Sort-Object -Property Precedence -Descending | ForEach-Object {
				$gpoDN = $GpoNameMapping[(Resolve-String -Text $_.PolicyName)]
				if (-not $gpoDN) {
					Write-PSFMessage -Level Warning -String 'Invoke-DMGPLink.Update.GpoNotFound' -StringValues (Resolve-String -Text $_.PolicyName) -Target $ADObject -FunctionName Invoke-DMGPLink
					return
				}
				"[LDAP://$gpoDN;0]"
			}) -Join ""
			Write-PSFMessage -Level Debug -String 'Invoke-DMGPLink.Update.NewGPLinkString' -StringValues $ADObject.DistinguishedName, $gpLinkString -Target $ADObject -FunctionName Invoke-DMGPLink
			Set-ADObject @parameters -Identity $ADObject -Replace @{ gPLink = $gpLinkString } -ErrorAction Stop
		}
		#endregion Utility Functions

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type GroupPolicyLinks -Cmdlet $PSCmdlet
		$testResult = Test-DMGPLink @parameters

		$gpoDisplayToDN = @{ }
		$gpoDNToDisplay = @{ }
		foreach ($adPolicyObject in (Get-ADObject @parameters -LDAPFilter '(objectCategory=groupPolicyContainer)' -Properties DisplayName, DistinguishedName)) {
			$gpoDisplayToDN[$adPolicyObject.DisplayName] = $adPolicyObject.DistinguishedName
			$gpoDNToDisplay[$adPolicyObject.DistinguishedName] = $adPolicyObject.DisplayName
		}
	}
	process
	{
		#region Executing Test-Results
		foreach ($testItem in $testResult) {
			$countConfigured = ($testItem.Configuration | Measure-Object).Count
			$countActual = ($testItem.ADObject.LinkedGroupPolicyObjects | Measure-Object).Count
			$countNotInConfig = ($testItem.ADObject.LinkedGroupPolicyObjects | Where-Object DistinguishedName -notin ($testItem.Configuration.PolicyName | Remove-PSFNull| Resolve-String | ForEach-Object { $gpoDisplayToDN[$_] }) | Measure-Object).Count

			switch ($testItem.Type) {
				'Delete' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Delete.AllEnabled' -ActionStringValues $countActual -Target $testItem -ScriptBlock {
						Clear-Link @parameters -ADObject $testItem.ADObject -Disable $Disable -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'DeleteDisabledOnly' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Delete.AllDisabled' -ActionStringValues $countActual -Target $testItem -ScriptBlock {
						Clear-Link @parameters -ADObject $testItem.ADObject -Disable $Disable -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'DeleteSomeDisabled' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Delete.SomeDisabled' -ActionStringValues $countActual -Target $testItem -ScriptBlock {
						Clear-Link @parameters -ADObject $testItem.ADObject -Disable $Disable -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'New' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.New' -ActionStringValues $countConfigured -Target $testItem -ScriptBlock {
						New-Link @parameters -ADObject $testItem.ADObject -Configuration $testItem.Configuration -GpoNameMapping $gpoDisplayToDN -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Update' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Update.AllEnabled' -ActionStringValues $countConfigured, $countActual, $countNotInConfig -Target $testItem -ScriptBlock {
						Update-Link @parameters -ADObject $testItem.ADObject -Configuration $testItem.Configuration -Disable $Disable -GpoNameMapping $gpoDisplayToDN -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'UpdateDisabledOnly' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Update.AllDisabled' -ActionStringValues $countConfigured, $countActual, $countNotInConfig -Target $testItem -ScriptBlock {
						Update-Link @parameters -ADObject $testItem.ADObject -Configuration $testItem.Configuration -Disable $Disable -GpoNameMapping $gpoDisplayToDN -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'UpdateSomeDisabled' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPLink.Update.SomeDisabled' -ActionStringValues $countConfigured, $countActual, $countNotInConfig -Target $testItem -ScriptBlock {
						Update-Link @parameters -ADObject $testItem.ADObject -Configuration $testItem.Configuration -Disable $Disable -GpoNameMapping $gpoDisplayToDN -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
			}
		}
		#endregion Executing Test-Results
	}
}
