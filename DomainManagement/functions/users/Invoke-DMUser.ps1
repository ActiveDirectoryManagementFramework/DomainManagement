function Invoke-DMUser
{
	<#
		.SYNOPSIS
			Updates the user configuration of a domain to conform to the configured state.
		
		.DESCRIPTION
			Updates the user configuration of a domain to conform to the configured state.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.

		.PARAMETER EnableException
			This parameters disables user-friendly warnings and enables the throwing of exceptions.
			This is less user friendly, but allows catching exceptions in calling scripts.

		.PARAMETER Confirm
			If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
		
		.PARAMETER WhatIf
			If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
		
		.EXAMPLE
			PS C:\> Innvoke-DMUser -Server contoso.com

			Updates the users in the domain contoso.com to conform to configuration
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Users -Cmdlet $PSCmdlet
		$testResult = Test-DMUser @parameters
		Set-DMDomainContext @parameters
	}
	process
	{
		:main foreach ($testItem in $testResult) {
			switch ($testItem.Type) {
				'ShouldDelete' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMUser.User.Delete' -Target $testItem -ScriptBlock {
						Remove-ADUser @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'ConfigurationOnly' {
					$targetOU = Resolve-String -Text $testItem.Configuration.Path
					try { $null = Get-ADObject @parameters -Identity $targetOU -ErrorAction Stop }
					catch { Stop-PSFFunction -String 'Invoke-DMUser.User.Create.OUExistsNot' -StringValues $targetOU, $testItem.Identity -Target $testItem -EnableException $EnableException -Continue -ContinueLabel main }
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMUser.User.Create' -Target $testItem -ScriptBlock {
						$newParameters = $parameters.Clone()
						$newParameters += @{
							Name = (Resolve-String -Text $testItem.Configuration.SamAccountName)
							SamAccountName = (Resolve-String -Text $testItem.Configuration.SamAccountName)
							UserPrincipalName = (Resolve-String -Text $testItem.Configuration.UserPrincipalName)
							PasswordNeverExpires = $testItem.Configuration.PasswordNeverExpires
							Path = $targetOU
							AccountPassword = (New-Password -Length 128 -AsSecureString)
							Enabled = $testItem.Configuration.Enabled # Both True and Undefined will result in $true
						}
						if ($testItem.Configuration.Description) { $newParameters['Description'] = Resolve-String -Text $testItem.Configuration.Description }
						if ($testItem.Configuration.GivenName) { $newParameters['GivenName'] = Resolve-String -Text $testItem.Configuration.GivenName }
						if ($testItem.Configuration.Surname) { $newParameters['Surname'] = Resolve-String -Text $testItem.Configuration.Surname }
						New-ADUser @newParameters
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'MultipleOldUsers' {
					Stop-PSFFunction -String 'Invoke-DMUser.User.MultipleOldUsers' -StringValues $testItem.Identity, ($testItem.ADObject.Name -join ', ') -Target $testItem -EnableException $EnableException -Continue -Tag 'user','critical','panic'
				}
				'Rename' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMUser.User.Rename' -ActionStringValues (Resolve-String -Text $testItem.Configuration.SamAccountName) -Target $testItem -ScriptBlock {
						Set-ADUser @parameters -Identity $testItem.ADObject.ObjectGUID -SamAccountName $testItem.Configuration.SamAccountName -ErrorAction Stop
						if ($testItem.ADObject.Name -ne (Resolve-String -Text $testItem.Configuration.Name)) {
							Rename-ADObject @parameters -Identity $testItem.ADObject.ObjectGUID -NewName (Resolve-String -Text $testItem.Configuration.Name) -ErrorAction Stop
						}
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Changed' {
					if ($testItem.Changed -contains 'Path') {
						$targetOU = Resolve-String -Text $testItem.Configuration.Path
						try { $null = Get-ADObject @parameters -Identity $targetOU -ErrorAction Stop }
						catch { Stop-PSFFunction -String 'Invoke-DMUser.User.Update.OUExistsNot' -StringValues $testItem.Identity, $targetOU -Target $testItem -EnableException $EnableException -Continue -ContinueLabel main }

						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMUser.User.Move' -ActionStringValues $targetOU -Target $testItem -ScriptBlock {
							$null = Move-ADObject @parameters -Identity $testItem.ADObject.ObjectGUID -TargetPath $targetOU -ErrorAction Stop
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}
					$changes = @{ }
					if ($testItem.Changed -contains 'GivenName') { $changes['GivenName'] = (Resolve-String -Text $testItem.Configuration.GivenName) }
					if ($testItem.Changed -contains 'Surname') { $changes['sn'] = (Resolve-String -Text $testItem.Configuration.Surname) }
					if ($testItem.Changed -contains 'Description') { $changes['Description'] = (Resolve-String -Text $testItem.Configuration.Description) }
					if ($testItem.Changed -contains 'UserPrincipalName') { $changes['UserPrincipalName'] = (Resolve-String -Text $testItem.Configuration.UserPrincipalName) }
					
					if ($changes.Keys.Count -gt 0)
					{
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMUser.User.Update' -ActionStringValues ($changes.Keys -join ", ") -Target $testItem -ScriptBlock {
							$null = Set-ADObject @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -Replace $changes
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}

					if ($testItem.Changed -contains 'Enabled') {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMUser.User.Update.EnableDisable' -ActionStringValues $testItem.Configuration.Enabled -Target $testItem -ScriptBlock {
							$null = Set-ADUser @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -Enabled $testItem.Configuration.Enabled
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}
					if ($testItem.Changed -contains 'PasswordNeverExpires') {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMUser.User.Update.PasswordNeverExpires' -ActionStringValues $testItem.Configuration.PasswordNeverExpires -Target $testItem -ScriptBlock {
							$null = Set-ADUser @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -PasswordNeverExpires $testItem.Configuration.PasswordNeverExpires
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}
				}
			}
		}
	}
}
