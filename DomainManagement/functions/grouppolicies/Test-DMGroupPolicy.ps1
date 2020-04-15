function Test-DMGroupPolicy {
	<#
	.SYNOPSIS
		Tests whether the current domain has the desired group policy setup.
	
	.DESCRIPTION
		Tests whether the current domain has the desired group policy setup.
		Based on timestamps and IDs it will detect for existing OUs, whether the currently deployed version:
		- Is based on the latest GPO version
		- has been changed since being last deployed (In which case it is configured to restore itself to its intended state)
		Ignores GPOs not linked to managed OUs.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Test-DMGroupPolicy -Server contoso.com

		Validates that the contoso domain's group policies are in the desired state
	#>
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
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type GroupPolicyObjects -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
		$computerName = (Get-ADDomain @parameters).PDCEmulator

		# DomainData retrieval
		$domainDataNames = ((Get-DMGroupPolicy).DisplayName | Get-DMGPRegistrySetting | Where-Object DomainData).DomainData | Select-Object -Unique
		try { $null = $domainDataNames | Invoke-DMDomainData @parameters -EnableException }
		catch {
			Stop-PSFFunction -String 'Test-DMGroupPolicy.DomainData.Failed' -StringValues ($domainDataNames -join ",") -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}

		# PS Remoting
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential -Inherit
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Test-DMGroupPolicy.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }

		$resultDefaults = @{
			Server     = $Server
			ObjectType = 'GroupPolicy'
		}

		#region Gather data
		$desiredPolicies = Get-DMGroupPolicy
		$managedPolicies = Get-LinkedPolicy @parameters
		foreach ($managedPolicy in $managedPolicies) {
			if (-not $managedPolicy.DisplayName) {
				Write-PSFMessage -Level Warning -String 'Test-DMGroupPolicy.ADObjectAccess.Failed' -StringValues $managedPolicy.DistinguishedName -Target $managedPolicy
				New-TestResult @resultDefaults -Type 'ADAccessFailed' -Identity $managedPolicy.DistinguishedName -ADObject $managedPolicy
				continue
			}
			# Resolve-PolicyRevision updates the content of $managedPolicy without producing output
			try { Resolve-PolicyRevision -Policy $managedPolicy -Session $session }
			catch { Write-PSFMessage -Level Warning -String 'Test-DMGroupPolicy.PolicyRevision.Lookup.Failed' -StringValues $managedPolicies.DisplayName -ErrorRecord $_ -EnableException $EnableException.ToBool() }
		}
		$desiredHash = @{ }
		$managedHash = @{ }
		foreach ($desiredPolicy in $desiredPolicies) { $desiredHash[$desiredPolicy.DisplayName] = $desiredPolicy }
		foreach ($managedPolicy in $managedPolicies) {
			if (-not $managedPolicy.DisplayName) { continue }
			$managedHash[$managedPolicy.DisplayName] = $managedPolicy
		}
		#endregion Gather data

		#region Compare configuration to actual state
		foreach ($desiredPolicy in $desiredHash.Values) {
			if (-not $managedHash[$desiredPolicy.DisplayName]) {
				New-TestResult @resultDefaults -Type 'Create' -Identity $desiredPolicy.DisplayName -Configuration $desiredPolicy
				continue
			}

			switch ($managedHash[$desiredPolicy.DisplayName].State) {
				'ConfigError' { New-TestResult @resultDefaults -Type 'ConfigError' -Identity $desiredPolicy.DisplayName -Configuration $desiredPolicy -ADObject $managedHash[$desiredPolicy.DisplayName] }
				'CriticalError' { New-TestResult @resultDefaults -Type 'CriticalError' -Identity $desiredPolicy.DisplayName -Configuration $desiredPolicy -ADObject $managedHash[$desiredPolicy.DisplayName] }
				'Healthy' {
					$policyObject = $managedHash[$desiredPolicy.DisplayName]
					if ($desiredPolicy.ExportID -ne $policyObject.ExportID) {
						New-TestResult @resultDefaults -Type 'Update' -Identity $desiredPolicy.DisplayName -Configuration $desiredPolicy -ADObject $policyObject
						continue
					}
					if ($policyObject.Version -ne $policyObject.ADVersion) {
						New-TestResult @resultDefaults -Type 'Modified' -Identity $desiredPolicy.DisplayName -Configuration $desiredPolicy -ADObject $policyObject
						continue
					}
					$registryTest = Test-DMGPRegistrySetting @parameters -PolicyName $desiredPolicy.DisplayName -PassThru
					if (-not $registryTest.Success) {
						New-TestResult @resultDefaults -Type 'BadRegistryData' -Identity $desiredPolicy.DisplayName -Configuration $desiredPolicy -ADObject $policyObject -Changed $registryTest.Changes
						continue
					}
				}
				'Unmanaged' {
					New-TestResult @resultDefaults -Type 'Manage' -Identity $desiredPolicy.DisplayName -Configuration $desiredPolicy -ADObject $managedHash[$desiredPolicy.DisplayName]
				}
			}
		}
		#endregion Compare configuration to actual state

		#region Compare actual state to configuration
		foreach ($managedPolicy in $managedHash.Values) {
			if ($desiredHash[$managedPolicy.DisplayName]) { continue }
			if ($managedPolicy.IsCritical) { continue }
			New-TestResult @resultDefaults -Type 'Delete' -Identity $managedPolicy.DisplayName -ADObject $managedPolicy
		}
		#endregion Compare actual state to configuration
	}
	end {
		if ($session) { Remove-PSSession $session -WhatIf:$false }
	}
}
