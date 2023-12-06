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
		$allPolicies = Get-GroupPolicyEx @parameters
		foreach ($groupPolicy in $allPolicies) {
			if (-not $groupPolicy.DisplayName) {
				Write-PSFMessage -Level Warning -String 'Test-DMGroupPolicy.ADObjectAccess.Failed' -StringValues $groupPolicy.DistinguishedName -Target $groupPolicy
				New-TestResult @resultDefaults -Type 'ADAccessFailed' -Identity $groupPolicy.DistinguishedName -ADObject $groupPolicy
				continue
			}
			# Resolve-PolicyRevision updates the content of $groupPolicy without producing output
			try { Resolve-PolicyRevision -Policy $groupPolicy -Session $session }
			catch { Write-PSFMessage -Level Warning -String 'Test-DMGroupPolicy.PolicyRevision.Lookup.Failed' -StringValues $allPolicies.DisplayName -ErrorRecord $_ -EnableException $EnableException.ToBool() }
		}
		$desiredHash = @{ }
		$policyHash = @{ }
		foreach ($desiredPolicy in $desiredPolicies) { $desiredHash[$desiredPolicy.DisplayName] = $desiredPolicy }
		foreach ($groupPolicy in $allPolicies) {
			if (-not $groupPolicy.DisplayName) { continue }
			$policyHash[$groupPolicy.DisplayName] = $groupPolicy
		}
		#endregion Gather data

		#region Compare configuration to actual state
		foreach ($desiredPolicy in $desiredHash.Values) {
			$resultUpdateDefaults = $resultDefaults.Clone()
			$resultUpdateDefaults +=  @{
				Identity = $desiredPolicy.DisplayName
				Configuration = $desiredPolicy
			}

			if (-not $policyHash[$desiredPolicy.DisplayName]) {
				New-TestResult @resultUpdateDefaults -Type 'Create'
				continue
			}

			$resultUpdateDefaults.ADObject = $policyHash[$desiredPolicy.DisplayName]

			switch ($policyHash[$desiredPolicy.DisplayName].State) {
				'ConfigError' { New-TestResult @resultUpdateDefaults -Type 'ConfigError' }
				'CriticalError' { New-TestResult @resultUpdateDefaults -Type 'CriticalError' }
				'Healthy' {
					$changes = [System.Collections.ArrayList]@()
					$policyObject = $policyHash[$desiredPolicy.DisplayName]
					if ($policyObject.Version -ne $policyObject.ADVersion) {
						$change = New-Change -Property Modified -OldValue $policyObject.Version -NewValue $policyObject.ADVersion -Identity $desiredPolicy.DisplayName -Type AdmfVersion
						$null = $changes.Add($change)
					}
					if ($desiredPolicy.ExportID -ne $policyObject.ExportID) {
						$change = New-Change -Property Update -OldValue $policyObject.ExportID -NewValue $desiredPolicy.ExportID -Identity $desiredPolicy.DisplayName -Type AdmfVersion
						$null = $changes.Add($change)
					}
					$registryTest = Test-DMGPRegistrySetting -Server $session -PolicyName $desiredPolicy.DisplayName -PassThru
					if (-not $registryTest.Success) {
						foreach ($changeItem in $registryTest.Changes) {
							$change = New-Change -Property RegistryData -OldValue $changeItem.IsValue -NewValue $changeItem.ShouldValue -Identity ('{0}: {1} > {2}' -f $desiredPolicy.DisplayName, $changeItem.Key, $changeItem.ValueName) -Type AdmfVersion
							$null = $changes.Add($change)
						}
					}
					if ("$($desiredPolicy.WmiFilter)" -ne "$($policyHash[$desiredPolicy.DisplayName].WmiFilter)") {
						$change = New-Change -Property WmiFilter -OldValue $policyHash[$desiredPolicy.DisplayName].WmiFilter -NewValue $desiredPolicy.WmiFilter -Identity $desiredPolicy.DisplayName -Type WmiFilterAssignment
						$null = $changes.Add($change)
					}
					if ($changes.Count -gt 0) {
						New-TestResult @resultUpdateDefaults -Type 'Update' -Changed $changes
					}
				}
				'Unmanaged' {
					New-TestResult @resultUpdateDefaults -Type 'Manage'
				}
			}
		}
		#endregion Compare configuration to actual state

		#region Compare actual state to configuration
		foreach ($groupPolicy in $policyHash.Values) {
			if ($desiredHash[$groupPolicy.DisplayName]) { continue }
			if ($groupPolicy.IsCritical) { continue }

			# Don't delete any GPOs that have not been linked under a managed OU while not being desired
			if (-not $groupPolicy.IsManageLinked) { continue }
			New-TestResult @resultDefaults -Type 'Delete' -Identity $groupPolicy.DisplayName -ADObject $groupPolicy
		}
		#endregion Compare actual state to configuration
	}
	end {
		if ($session) { Remove-PSSession $session -WhatIf:$false -Confirm:$false }
	}
}
