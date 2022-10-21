function Install-GroupPolicy {
	<#
	.SYNOPSIS
		Uses PowerShell remoting to install a GPO into the target domain.
	
	.DESCRIPTION
		Uses PowerShell remoting to install a GPO into the target domain.
		Installation does not support using a Migration Table.
		Overwrites an existing GPO, if one with the same name exists.
		Also includes a tracking file to detect drift and when an update becomes necessary.
	
	.PARAMETER Session
		The PowerShell remoting session to the domain controller on which to import the GPO.
	
	.PARAMETER Configuration
		The configuration object representing the desired state for the GPO
	
	.PARAMETER WorkingDirectory
		The folder on the target machine where GPO-related working files are stored.
		Everything inside this folder is subject to deletion.
	
	.EXAMPLE
		PS C:\> Install-GroupPolicy -Session $session -Configuration $testItem.Configuration -WorkingDirectory $gpoRemotePath -ErrorAction Stop

		Installs the specified group policy on the remote system connected to via $session.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[CmdletBinding()]
	param (
		[System.Management.Automation.Runspaces.PSSession]
		$Session,
		
		[PSObject]
		$Configuration,
		
		[string]
		$WorkingDirectory
	)
	
	begin {
		$timestamp = (Get-Date).AddMinutes(-5)
		
		$stopDefault = @{
			Target          = $Configuration
			Cmdlet          = $PSCmdlet
			EnableException = $true
		}
	}
	process {
		Write-PSFMessage -Level Debug -String 'Install-GroupPolicy.CopyingFiles' -StringValues $Configuration.DisplayName -Target $Configuration
		try { Copy-Item -Path $Configuration.Path -Destination $WorkingDirectory -Recurse -ToSession $Session -ErrorAction Stop -Force -Confirm:$false }
		catch { Stop-PSFFunction @stopDefault -String 'Install-GroupPolicy.CopyingFiles.Failed' -StringValues $Configuration.DisplayName -ErrorRecord $_ }
		
		#region Installing Group Policy Object
		Write-PSFMessage -Level Debug -String 'Install-GroupPolicy.ImportingConfiguration' -StringValues $Configuration.DisplayName -Target $Configuration
		try {
			Invoke-Command -Session $session -ArgumentList $Configuration, $WorkingDirectory -ScriptBlock {
				param (
					$Configuration,
					
					$WorkingDirectory
				)
				try {
					$domain = Get-ADDomain -Server localhost
					$paramImportGPO = @{
						Domain         = $domain.DNSRoot
						Server         = $env:COMPUTERNAME
						BackupGpoName  = $Configuration.DisplayName
						TargetName     = $Configuration.DisplayName
						Path           = $WorkingDirectory
						CreateIfNeeded = $true
						ErrorAction    = 'Stop'
					}
					$null = Import-GPO @paramImportGPO
				}
				catch { throw }
			} -ErrorAction Stop
		}
		catch { Stop-PSFFunction @stopDefault -String 'Install-GroupPolicy.ImportingConfiguration.Failed' -StringValues $Configuration.DisplayName -ErrorRecord $_ }
		#endregion Installing Group Policy Object
		
		#region Applying Registry Settings
		$resolvedName = $Configuration.DisplayName | Resolve-String @parameters
		$applicableRegistrySettings = Get-DMGPRegistrySetting | Where-Object {
			$resolvedName -eq ($_.PolicyName | Resolve-String @parameters)
		}
		if ($applicableRegistrySettings) {
			$registryData = foreach ($applicableRegistrySetting in $applicableRegistrySettings) {
				if ($applicableRegistrySetting.PSObject.Properties.Name -contains 'Value') {
					[PSCustomObject]@{
						GPO       = $resolvedName
						Key       = Resolve-String @parameters -Text $applicableRegistrySetting.Key
						ValueName = Resolve-String @parameters -Text $applicableRegistrySetting.ValueName
						Type      = $applicableRegistrySetting.Type
						Value     = $applicableRegistrySetting.Value
					}
				}
				else {
					[PSCustomObject]@{
						GPO       = $resolvedName
						Key       = Resolve-String @parameters -Text $applicableRegistrySetting.Key
						ValueName = Resolve-String @parameters -Text $applicableRegistrySetting.ValueName
						Type      = $applicableRegistrySetting.Type
						Value     = ((Invoke-DMDomainData @parameters -Name $applicableRegistrySetting.DomainData).Data | Write-Output)
					}
				}
			}
			Write-PSFMessage -Level Debug -String 'Install-GroupPolicy.Importing.RegistryValues' -StringValues $Configuration.DisplayName -Target $Configuration
			foreach ($registryDatum in $registryData) {
				try {
					Invoke-Command -Session $session -ArgumentList $registryDatum -ScriptBlock {
						param ($RegistryDatum)
						$domain = Get-ADDomain -Server localhost
						$null = Get-GPO -Server localhost -Domain $domain.DNSRoot -Name $RegistryDatum.GPO -ErrorAction Stop | Set-GPRegistryValue -Server localhost -Domain $domain.DNSRoot -Key $RegistryDatum.Key -ValueName $RegistryDatum.ValueName -Type $RegistryDatum.Type -Value $RegistryDatum.Value -ErrorAction Stop
					} -ErrorAction Stop
				}
				catch {
					Stop-PSFFunction @stopDefault -String 'Install-GroupPolicy.Importing.RegistryValues.Failed' -StringValues $Configuration.DisplayName, $registryDatum.Key, $registryDatum.ValueName -ErrorRecord $_
				}
			}
		}
		#endregion Applying Registry Settings
		
		Write-PSFMessage -Level Debug -String 'Install-GroupPolicy.ReadingADObject' -StringValues $Configuration.DisplayName -Target $Configuration
		try {
			$policyObject = Invoke-Command -Session $session -ArgumentList $Configuration -ScriptBlock {
				param ($Configuration)
				Get-ADObject -Server localhost -LDAPFilter "(&(objectCategory=groupPolicyContainer)(DisplayName=$($Configuration.DisplayName)))" -Properties Modified, gPCFileSysPath, gPCWQLFilter, versionNumber -ErrorAction Stop
			} -ErrorAction Stop
		}
		catch { Stop-PSFFunction @stopDefault -String 'Install-GroupPolicy.ReadingADObject.Failed.Error' -StringValues $Configuration.DisplayName -ErrorRecord $_ }
		if (-not $policyObject) { Stop-PSFFunction @stopDefault -String 'Install-GroupPolicy.ReadingADObject.Failed.NoObject' -StringValues $Configuration.DisplayName }
		if ($policyObject.Modified -lt $timestamp) { Stop-PSFFunction @stopDefault -String 'Install-GroupPolicy.ReadingADObject.Failed.Timestamp' -StringValues $Configuration.DisplayName, $policyObject.Modified, $timestamp }

		#region Apply WMI Filters
		if ($Configuration.WmiFilter -or $policyObject.gPCWQLFilter) {
			$code = {
				param ($Configuration, $PolicyObject)
				$adParam = @{ Server = 'localhost' }

				if (-not $Configuration.WmiFilter) {
					try {
						Set-ADObject @adParam -Identity $PolicyObject.DistinguishedName -Clear 'gPCWQLFilter' -ErrorAction Stop
						[PSCustomObject]@{
							Success = $true
							Message = ''
						}
					}
					catch {
						[PSCustomObject]@{
							Success = $false
							Message = "Error clearing WMI Filter: $_"
						}
					}
					return
				}

				$wmiFilter = Get-ADObject @adParam -LDAPFilter "(&(objectClass=msWMI-Som)(msWMI-Name=$($Configuration.WmiFilter)))" -Properties msWMI-ID
				if (-not $wmiFilter) {
					[PSCustomObject]@{
						Success = $false
						Message = "WMI Filter does not exist! $($Configuration.WmiFilter)"
					}
					return
				}

				$domain = Get-ADDomain @adParam
				$filterProperty = '[{0};{1};0]' -f $domain.DnsRoot, $wmiFilter.'msWMI-ID'
				try {
					Set-ADObject @adParam -Identity $PolicyObject.DistinguishedName -Replace @{ 'gPCWQLFilter' = $filterProperty } -ErrorAction Stop
					[PSCustomObject]@{
						Success = $true
						Message = ''
					}
				}
				catch {
					[PSCustomObject]@{
						Success = $false
						Message = "Error applying WMI Filter: $_"
					}
				}
			}
			Invoke-PSFProtectedCommand -ActionString 'Install-GroupPolicy.WmiFilter' -ActionStringValues $Configuration.DisplayName, $Configuration.WmiFilter -ScriptBlock {
				$wmiResult = Invoke-Command -Session $session -ArgumentList $Configuration,$policyObject -ScriptBlock $code -ErrorAction Stop
			} -Target $Configuration -EnableException $true -PSCmdlet $PSCmdlet

			if (-not $wmiResult.Success) {
				Write-PSFMessage -Level Warning -String 'Install-GroupPolicy.WmiFilter.Failed' -StringValues $Configuration.DisplayName, $Configuration.WmiFilter, $wmiResult.Message -Target $Configuration
			}
		}
		#endregion Apply WMI Filters
		
		#region Create/Update ADMF Tracking File
		Write-PSFMessage -Level Debug -String 'Install-GroupPolicy.UpdatingConfigurationFile' -StringValues $Configuration.DisplayName -Target $Configuration
		try {
			Invoke-Command -Session $session -ArgumentList $Configuration, $policyObject -ScriptBlock {
				param (
					$Configuration,
					
					$PolicyObject
				)
				$object = [PSCustomObject]@{
					ExportID  = $Configuration.ExportID
					Timestamp = $PolicyObject.Modified
					Version   = $PolicyObject.VersionNumber
				}
				$object | Export-Clixml -Path "$($PolicyObject.gPCFileSysPath)\dm_config.xml" -Force -ErrorAction Stop
			} -ErrorAction Stop
		}
		catch { Stop-PSFFunction @stopDefault -String 'Install-GroupPolicy.UpdatingConfigurationFile.Failed' -StringValues $Configuration.DisplayName -ErrorRecord $_ }
		#endregion Create/Update ADMF Tracking File

		Write-PSFMessage -Level Debug -String 'Install-GroupPolicy.DeletingImportFiles' -StringValues $Configuration.DisplayName -Target $Configuration
		Invoke-Command -Session $session -ArgumentList $WorkingDirectory -ScriptBlock {
			param ($WorkingDirectory)
			Remove-Item -Path "$WorkingDirectory\*" -Recurse -Force -ErrorAction SilentlyContinue
		}
	}
}