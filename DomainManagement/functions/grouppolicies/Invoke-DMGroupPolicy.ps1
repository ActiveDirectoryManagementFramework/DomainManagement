function Invoke-DMGroupPolicy
{
	<#
	.SYNOPSIS
		Brings the group policy settings into compliance with the desired state.
	
	.DESCRIPTION
		Brings the group policy settings into compliance with the desired state.
		Define the desired state by using Register-DMGroupPolicy.
		Note: The original export will need to be carefully crafted to fit this system.
		Use the ADMF module's Export-AdmfGpo command to generate the gpo definition from an existing deployment.
	
	.PARAMETER InputObject
		Test results provided by the associated test command.
		Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
	
	.PARAMETER Delete
		By default, this command will NOT delete group policies, in order to avoid accidentally locking yourself out of the system.
		Use this parameter to delete group policies that are no longer needed.
	
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
		PS C:\> Invoke-DMGroupPolicy -Server fabrikam.com

		Brings the group policy settings from the domain fabrikam.com into compliance with the desired state.

	.EXAMPLE
		PS C:\> Invoke-DMGroupPolicy -Server fabrikam.com -Delete

		Brings the group policy settings from the domain fabrikam.com into compliance with the desired state.
		Will also delete all deprecated policies linked to the managed infrastructure.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[switch]
		$Delete,

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
		Assert-Configuration -Type GroupPolicyObjects -Cmdlet $PSCmdlet
		$computerName = (Get-ADDomain @parameters).PDCEmulator
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential -Inherit
		try { $session = New-AdcPSSession @psParameter -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Invoke-DMGroupPolicy.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}
		Set-DMDomainContext @parameters

		try { $gpoRemotePath = New-GpoWorkingDirectory -Session $session -ErrorAction Stop }
		catch {
			Remove-PSSession -Session $session -WhatIf:$false -Confirm:$false -ErrorAction SilentlyContinue
			Stop-PSFFunction -String 'Invoke-DMGroupPolicy.Remote.WorkingDirectory.Failed' -StringValues $computerName -Target $computerName -ErrorRecord $_ -EnableException $EnableException
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $InputObject) {
			$InputObject = Test-DMGroupPolicy @parameters
		}
		
		foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.GroupPolicy.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMGroupPolicy', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				'Delete' {
					if (-not $Delete) { continue }
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Delete' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Remove-GroupPolicy -Session $session -ADObject $testItem.ADObject -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'ConfigError' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnConfigError' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'CriticalError' {
					Write-PSFMessage -Level Warning -String 'Invoke-DMGroupPolicy.Skipping.InCriticalState' -StringValues $testItem.Identity -Target $testItem
				}
				'Update' {
					foreach ($change in $testItem.Changed) {
						Write-PSFMessage -Level Verbose -String 'Invoke-DMGroupPolicy.Update.Detail' -StringValues $change.Property, $change.Old, $change.New, $change.Identity -Target $testItem -Tag gpoUpdateDetail
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnUpdate' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'Manage' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnManage' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'Create' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnNew' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
			}
		}
	}
	end
	{
		if ($gpoRemotePath) {
			Invoke-Command -Session $session -ArgumentList $gpoRemotePath -ScriptBlock {
				param ($GpoRemotePath)
				Remove-Item -Path $GpoRemotePath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue -WhatIf:$false
			}
		}
		if ($session) {
			Remove-PSSession -Session $session -WhatIf:$false -Confirm:$false -ErrorAction SilentlyContinue
		}
	}
}