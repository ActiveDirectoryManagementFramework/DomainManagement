function Invoke-DMPasswordPolicy
{
	<#
	.SYNOPSIS
		Applies the defined, desired state for finegrained password policies (PSOs)
	
	.DESCRIPTION
		Applies the defined, desired state for finegrained password policies (PSOs)
		Define the desired state using Register-DMPasswordPolicy.
	
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
		Assert-Configuration -Type PasswordPolicies -Cmdlet $PSCmdlet
		$testResult = Test-DMPasswordPolicy @parameters
		Set-DMDomainContext @parameters
	}
	process
	{
		foreach ($testItem in $testResult) {
			switch ($testItem.Type) {
				#region Delete
				'ShouldDelete' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMPasswordPolicy.PSO.Delete' -Target $testItem -ScriptBlock {
						Remove-ADFineGrainedPasswordPolicy @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Delete

				#region Create
				'ConfigurationOnly' {

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
				'Changed' {
					$changes = @{ }
					$updateAssignment = $false

					switch ($testItem.Changed) {
						'SubjectGroup' { $updateAssignment = $true; continue }
						'DisplayName' { $changes['DisplayName'] = Resolve-String -Text $testItem.Configuration.DisplayName; continue }
						'Description' { $changes['Description'] = Resolve-String -Text $testItem.Configuration.Description; continue }
						default { $changes[$_] = $testItem.Configuration.$_; continue }
					}
					
					if ($changes.Keys.Count -gt 0)
					{
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMPasswordPolicy.PSO.Update' -ActionStringValues ($changes.Keys -join ", ") -Target $testItem -ScriptBlock {
							$parametersUpdate = $parameters.Clone()
							$parametersUpdate += $changes
							$null = Set-ADFineGrainedPasswordPolicy -Identity $testItem.ADObject.ObjectGUID @parametersUpdate -ErrorAction Stop
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}

					if ($updateAssignment) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMPasswordPolicy.PSO.Update.GroupAssignment' -ActionStringValues (Resolve-String -Text $testItem.Configuration.SubjectGroup) -Target $testItem -ScriptBlock {
							if ($testItem.ADObject.AppliesTo) {
								Remove-ADFineGrainedPasswordPolicySubject @parameters -Identity $testItem.ADObject.ObjectGUID -Subjects $testItem.ADObject.AppliesTo -ErrorAction Stop
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
