function Invoke-DMGroupPolicy
{
	<#
	.SYNOPSIS
		Brings the group policy settings into compliance with the desired state.
	
	.DESCRIPTION
		Brings the group policy settings into compliance with the desired state.
		Define the desired state by using Register-DMGroupPolicy.
		Note: The original export will need to be carefully crafted to fit this system.
		TODO: Add definition on how to provide the GPO export,
	
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
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param (
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
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Invoke-DMGroupPolicy.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}
		$testResult = Test-DMGroupPolicy @parameters
		Set-DMDomainContext @parameters

		if (-not $testResult) { return }

		try { $gpoRemotePath = New-GpoWorkingDirectory -Session $session -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Invoke-DMGroupPolicy.Remote.WorkingDirectory.Failed' -StringValues $computerName -Target $computerName -ErrorRecord $_ -EnableException $EnableException
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		foreach ($testItem in $testResult) {
			switch ($testItem.Type) {
				'Delete' {
					if (-not $Delete) { continue }
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Delete' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Remove-GroupPolicy -Session $session -ADObject $testItem.ADObject -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'ConfigError' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnConfigError' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'CriticalError' {
					Write-PSFMessage -Level Warning -String 'Invoke-DMGroupPolicy.Skipping.InCriticalState' -StringValues $testItem.Identity -Target $testItem
				}
				'Update' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnUpdate' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Modified' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnModify' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Manage' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnManage' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Create' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupPolicy.Install.OnNew' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
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
	}
}
