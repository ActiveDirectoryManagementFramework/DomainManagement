function Invoke-DMGPOwner {
	<#
	.SYNOPSIS
		Brings all group ownerships into the desired state.
	
	.DESCRIPTION
		Brings all group ownerships into the desired state.
		Use Register-DMGPOwner to define a desired state.
		Use Test-DMGPOwner to test/preview changes.
	
	.PARAMETER InputObject
		Test results provided by the associated test command.
		Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
	
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
		PS C:\> Invoke-DMGPOwner -Server corp.contoso.com
		
		Bringsgs the domain corp.contoso.com into the desired state where group policy ownership is concerned
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
		$parameters = Resolve-GPTargetServer -Server $Server -Credential $Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type GroupPolicyOwners -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		# Test All GPO Ownerships if no specific test result was specified
		if (-not $InputObject) {
			$InputObject = Test-DMGPOwner @parameters -EnableException:$EnableException
		}

		#region Process Test results
		foreach ($testResult in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testResult.PSObject.TypeNames -notcontains 'DomainManagement.GPOwner.TestResult') {
				Stop-PSFFunction -String 'Invoke-DMGPOwner.Invalid.Input' -StringValues $testResult -Target $testResult -Continue -EnableException $EnableException
			}

			switch ($testResult.Type) {
				'Update' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPOwner.Update.Owner' -ActionStringValues $testResult.Changed.Old, $testResult.Changed.New, $testResult.Identity -ScriptBlock {
						Set-AdsOwner @parameters -Path $testResult.ADObject -Identity $testResult.Changed.NewObject.ObjectSID -EnableException -Confirm:$false
					} -Target $testResult.Identity -PSCmdlet $PSCmdlet -EnableException $EnableException
				}
			}
		}
		#endregion Process Test results
	}
}
