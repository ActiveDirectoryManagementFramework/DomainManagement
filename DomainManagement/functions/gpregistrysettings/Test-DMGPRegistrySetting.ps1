function Test-DMGPRegistrySetting {
	<#
	.SYNOPSIS
		Validates, whether a GPO's defined registry settings have been applied.
	
	.DESCRIPTION
		Validates, whether a GPO's defined registry settings have been applied.
		To define a GPO, use Register-DMGroupPolicy
		To define a GPO's associated registry settings, use Register-DMGPRegistrySetting

		Note: While it is theoretically possible to define a GPO registry setting without defining the GPO it is attached to, these settings will not be applied anyway, as processing is directly tied into the Group Policy invocation process.
	
	.PARAMETER PolicyName
		Name of the GPO to scan for compliance.
		Subject to advanced string insertion.

	.PARAMETER PassThru
		Returns result objects, rather than boolean values.
		Useful for better reporting and integration into the test-* workflow.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMGPRegistrySetting @parameters -PolicyName $policy

		Tests, whether the specified GPO has all the desired registry keys configured.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$PolicyName,

		[switch]
		$PassThru,
		
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false

		#region Utility Functions
		function Write-Result {
			[CmdletBinding()]
			param (
				[bool]
				$Success,

				[string]
				$Status,

				[AllowEmptyCollection()]
				[object]
				$Changes,

				[bool]
				$PassThru
			)

			if (-not $PassThru) { return $Success }

			[PSCustomObject]@{
				Success = $Success
				Status  = $Status
				Changes = $Changes	
			}
		}
		#endregion Utility Functions

		#region WinRM Session Handling
		$reUseSession = $false
		if ($Server.Type -eq 'PSSession') {
			$session = $Server.InputObject
			$reUseSession = $true
		}
		elseif (($Server.Type -eq 'Container') -and ($Server.InputObject.Connections.PSSession)) {
			$session = $Server.InputObject.Connections.PSSession
			$reUseSession = $true
		}
		else {
			$pdcParameter = $parameters.Clone()
			$pdcParameter.ComputerName = (Get-Domain2 @parameters).PDCEmulator
			$pdcParameter.Remove('Server')
			try { $session = New-PSSession @pdcParameter -ErrorAction Stop }
			catch {
				Stop-PSFFunction -String 'Test-DMGPRegistrySetting.WinRM.Failed' -StringValues $parameters.Server -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $parameters.Server
				return
			}
		}
		#endregion WinRM Session Handling
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }

		#region Processing the Configuration
		$resolvedName = $PolicyName | Resolve-String @parameters
		$applicableRegistrySettings = Get-DMGPRegistrySetting | Where-Object {
			$resolvedName -eq ($_.PolicyName | Resolve-String @parameters)
		}
		if (-not $applicableRegistrySettings) {
			Write-Result -Success $true -Status 'No Registry Settings Defined' -PassThru $PassThru
			return
		}

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
		#endregion Processing the Configuration

		#region Executing the Query
		$regArgument = @{
			GPO          = $resolvedName
			RegistryData = $registryData
		}

		$result = Invoke-Command -Session $session -ArgumentList $regArgument -ScriptBlock {
			param (
				$RegData
			)

			$result = [PSCustomObject]@{
				PolicyName = $RegData.GPO
				Success    = $false
				Status     = 'NotStarted'
				Changes    = @()
			}

			try {
				if (-not ($gpo = Get-GPO -Server Localhost -Domain (Get-ADDomain -Server localhost).DNSRoot -Name $RegData.GPO -ErrorAction Stop)) {
					$result.Status = "PolicyNotFound"
					return $result
				}
			}
			catch {
				$result.Status = "Error: $_"
				return $result
			}

			$domain = Get-ADDomain -Server localhost
			$changes = foreach ($registryDatum in $RegData.RegistryData) {
				$data = $null
				$data = $gpo | Get-GPRegistryValue -Server localhost -Domain $domain.DNSRoot -Key $registryDatum.Key -ValueName $registryDatum.ValueName -ErrorAction Ignore
				if (-not $data) {
					[PSCustomObject]@{
						PSTypeName  = 'DomainManagement.Change.GPRegistry'
						PolicyName  = $RegData.GPO
						Key         = $registryDatum.Key
						ValueName   = $registryDatum.ValueName
						ShouldValue = $registryDatum.Value
						IsValue     = $null
					}
					continue
				}
				if ($data.Value -ne $registryDatum.Value) {
					[PSCustomObject]@{
						PSTypeName  = 'DomainManagement.Change.GPRegistry'
						PolicyName  = $RegData.GPO
						Key         = $registryDatum.Key
						ValueName   = $registryDatum.ValueName
						ShouldValue = $registryDatum.Value
						IsValue     = $data.Value
					}
				}
			}
			if ($changes) {
				foreach ($change in $changes) {
					$change.PSObject.TypeNames.Clear()
					$change.PSObject.TypeNames.Add("DomainManagement.Change.GPRegistry")
					$change.PSObject.TypeNames.Add("System.Management.Automation.PSCustomObject")
					$change.PSObject.TypeNames.Add("System.Object")
				}
				$result.Changes = $changes
				$result.Status = 'BadSettings'
			}
			else { $result.Success = $true }
			return $result
		}
		$level = 'Verbose'
		if ($result.Status -like 'Error:*') { $level = 'Warning' }
		Write-PSFMessage -Level $level -String 'Test-DMGPRegistrySetting.TestResult' -StringValues $resolvedName, $result.Success, $result.Status -Target $PolicyName
		#endregion Executing the Query

		# Result
		Write-Result -Success $result.Success -Status $result.Status -Changes $result.Changes -PassThru $PassThru
	}
	end {
		if (Test-PSFFunctionInterrupt) { return }
		if (-not $reUseSession) {
			$session | Remove-PSSession
		}
	}
}
