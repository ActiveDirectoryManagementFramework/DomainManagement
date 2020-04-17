function Resolve-PolicyRevision
{
	<#
	.SYNOPSIS
		Checks the management state information of the specified policy object.
	
	.DESCRIPTION
		Checks the management state information of the specified policy object.
		It uses PowerShell remoting to read the configuration file with the associated group policy.
		This configuration file is stored when deploying a group policy using Invoke-DMGroupPolicy.

		This process is required to ensure only policies that need updating are thus updated.
	
	.PARAMETER Policy
		The policy object to validate and add the state information to.
	
	.PARAMETER Session
		The PowerShell Session to the PDCEmulator of the domain the GPO is part of.
	
	.EXAMPLE
		PS C:\> Resolve-PolicyRevision -Policy $managedPolicy -Session $session

		Checks the management state information of the specified policy object.
	#>
	[CmdletBinding()]
	Param (
		[psobject]
		$Policy,

		[System.Management.Automation.Runspaces.PSSession]
		$Session
	)
	
	process
	{
		#region Remote Call - Resolve GPO data => $result
		$result = Invoke-Command -Session $Session -ArgumentList $Policy.Path -ScriptBlock {
			param (
				$Path
			)

			$testPath = Join-Path -Path $Path -ChildPath gpt.ini
			$configPath = Join-Path -Path $Path -ChildPath dm_config.xml

			if (-not (Test-Path $testPath)) {
				[pscustomobject]@{
					Success = $false
					Exists = $null
					ExportID = $null
					Timestamp = $null
					Version = -1
					Error = $null
				}
				return
			}
			if (-not (Test-Path $configPath)) {
				[pscustomobject]@{
					Success = $true
					Exists = $false
					ExportID = $null
					Timestamp = $null
					Version   = -1
					Error = $null
				}
				return
			}
			try { $data = Import-Clixml -Path $configPath -ErrorAction Stop }
			catch {
				[pscustomobject]@{
					Success = $false
					Exists = $true
					ExportID = $null
					Timestamp = $null
					Version   = -1
					Error = $_
				}
				return
			}
			[pscustomobject]@{
				Success = $true
				Exists = $true
				ExportID = $data.ExportID
				Timestamp = $data.Timestamp
				Version  = $data.Version
				Error = $null
			}
		}
		#endregion Remote Call - Resolve GPO data => $result

		#region Process results
		$Policy.ExportID = $result.ExportID
		$Policy.ImportTime = $result.Timestamp
		$Policy.Version = $result.Version

		if (-not $result.Success) {
			if ($result.Exists) {
				$Policy.State = 'ConfigError'
				Write-PSFMessage -Level Debug -String 'Resolve-PolicyRevision.Result.ErrorOnConfigImport' -StringValues $Policy.DisplayName, $result.Error.Exception.Message -Target $Policy }
				throw $result.Error
			else {
				$Policy.State = 'CriticalError'
				Write-PSFMessage -Level Debug -String 'Resolve-PolicyRevision.Result.PolicyError' -StringValues $Policy.DisplayName -Target $Policy
				throw "Policy object not found in filesystem. Check existence and permissions!"
			}
		}
		else {
			if ($result.Exists) {
				$Policy.State  = 'Healthy'
				Write-PSFMessage -Level Debug -String 'Resolve-PolicyRevision.Result.Success' -StringValues $Policy.DisplayName, $result.ExportID, $result.Timestamp -Target $Policy }
			else {
				$Policy.State = 'Unmanaged'
				Write-PSFMessage -Level Debug -String 'Resolve-PolicyRevision.Result.Result.SuccessNotYetManaged' -StringValues $Policy.DisplayName -Target $Policy
			}
		}
		#endregion Process results
	}
}
