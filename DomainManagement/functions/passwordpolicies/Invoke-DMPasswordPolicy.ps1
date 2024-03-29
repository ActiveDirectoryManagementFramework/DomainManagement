﻿function Invoke-DMPasswordPolicy {
	<#
	.SYNOPSIS
		Applies the defined, desired state for finegrained password policies (PSOs)
	
	.DESCRIPTION
		Applies the defined, desired state for finegrained password policies (PSOs)
		Define the desired state using Register-DMPasswordPolicy.
	
	.PARAMETER InputObject
		Test results provided by the associated test command.
		Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.

	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Invoke-DMPasswordPolicy

		Applies the currently defined baseline for password policies to the current domain.
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
		$EnableException
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type PasswordPolicies -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		if (-not $InputObject) {
			$InputObject = Test-DMPasswordPolicy @parameters
		}
		
		foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.PSO.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMPasswordPolicy', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				#region Delete
				'Delete' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMPasswordPolicy.PSO.Delete' -Target $testItem -ScriptBlock {
						Remove-ADFineGrainedPasswordPolicy @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Delete
				
				#region Create
				'Create' {
					
					$parametersNew = $parameters.Clone()
					$parametersNew += @{
						Name = (Resolve-String -Text $testItem.Configuration.Name)
						Precedence = $testItem.Configuration.Precedence
						ComplexityEnabled = $testItem.Configuration.ComplexityEnabled
						LockoutDuration = $testItem.Configuration.LockoutDuration
						LockoutObservationWindow = $testItem.Configuration.LockoutObservationWindow
						LockoutThreshold = $testItem.Configuration.LockoutThreshold
						MaxPasswordAge = $testItem.Configuration.MaxPasswordAge
						MinPasswordAge = $testItem.Configuration.MinPasswordAge
						MinPasswordLength = $testItem.Configuration.MinPasswordLength
						DisplayName = (Resolve-String -Text $testItem.Configuration.DisplayName)
						Description = (Resolve-String -Text $testItem.Configuration.Description)
						PasswordHistoryCount = $testItem.Configuration.PasswordHistoryCount
						ReversibleEncryptionEnabled = $testItem.Configuration.ReversibleEncryptionEnabled
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMPasswordPolicy.PSO.Create' -Target $testItem -ScriptBlock {
						$adObject = New-ADFineGrainedPasswordPolicy @parametersNew -ErrorAction Stop -PassThru
						Add-ADFineGrainedPasswordPolicySubject @parameters -Identity $adObject -Subjects (Resolve-String -Text $testItem.Configuration.SubjectGroup)
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Create
				
				#region Changed
				'Update' {
					$changes = @{ }
					$updateAssignment = $false
					
					foreach ($change in $testItem.Changed) {
						switch ($change.Property) {
							'SubjectGroup' { $updateAssignment = $true }
							default { $changes[$change.Property] = $change.New }
						}
					}
					
					if ($changes.Keys.Count -gt 0) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMPasswordPolicy.PSO.Update' -ActionStringValues ($changes.Keys -join ", ") -Target $testItem -ScriptBlock {
							$parametersUpdate = $parameters.Clone()
							$parametersUpdate += $changes
							$null = Set-ADFineGrainedPasswordPolicy -Identity $testItem.ADObject.ObjectGUID @parametersUpdate -ErrorAction Stop -Confirm:$false
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}
					
					if ($updateAssignment) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMPasswordPolicy.PSO.Update.GroupAssignment' -ActionStringValues (Resolve-String -Text $testItem.Configuration.SubjectGroup) -Target $testItem -ScriptBlock {
							if ($testItem.ADObject.AppliesTo) {
								Remove-ADFineGrainedPasswordPolicySubject @parameters -Identity $testItem.ADObject.ObjectGUID -Subjects $testItem.ADObject.AppliesTo -ErrorAction Stop -Confirm:$false
							}
							$null = Add-ADFineGrainedPasswordPolicySubject @parameters -Identity $testItem.ADObject.ObjectGUID -Subjects (Resolve-String -Text $testItem.Configuration.SubjectGroup) -ErrorAction Stop
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}
				}
				#endregion Changed
			}
		}
	}
}
