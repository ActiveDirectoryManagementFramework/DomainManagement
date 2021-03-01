function Invoke-DMExchange
{
<#
	.SYNOPSIS
		Apply the desired exchange domain content update.
	
	.DESCRIPTION
		Apply the desired exchange domain content update.
		Use Register-DMExchange to define the exchange update.
	
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
		PS C:\> Invoke-DMExchange -Server dc1.emea.contoso.com
	
		Apply the desired exchange domain content update to the emea.contoso.com domain.
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
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
		Assert-Configuration -Type SchemaVersion -Cmdlet $PSCmdlet
		$domainObject = Get-ADDomain @parameters
		
		#region Utility Functions
		function Test-ExchangeIsoPath {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
			[CmdletBinding()]
			param (
				[System.Management.Automation.Runspaces.PSSession]
				$Session,
				
				[string]
				$Path
			)
			
			Invoke-Command -Session $Session -ScriptBlock {
				Test-Path -Path $using:Path
			}
		}
		
		function Invoke-ExchangeDomainUpdate {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
			[CmdletBinding()]
			param (
				[System.Management.Automation.Runspaces.PSSession]
				$Session,
				
				[string]
				$Path
			)
			
			$result = Invoke-Command -Session $Session -ScriptBlock {
				$exchangeIsoPath = Resolve-Path -Path $using:Path
				
				# Mount Volume
				$diskImage = Mount-DiskImage -ImagePath $exchangeIsoPath -PassThru
				$volume = Get-Volume -DiskImage $diskImage
				$installPath = "$($volume.DriveLetter):\setup.exe"
				
				# Perform Installation
				$resultText = & $installPath /IAcceptExchangeServerLicenseTerms /PrepareDomain 2>&1
				$results = [pscustomobject]@{
					Success = $LASTEXITCODE -lt 1
					Message = $resultText -join "`n"
				}
				
				# Dismount Volume
				try { Dismount-DiskImage -ImagePath $exchangeIsoPath }
				catch { }
				
				# Report result
				$results
			}
			if (-not $result.Success) {
				throw "Error applying exchange update: $($result.Message)"
			}
		}
		#endregion Utility Functions
	}
	process
	{
		$testResult = Test-DMExchange @parameters
		
		if (-not $testResult) { return }
		
		#region PS Remoting
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		$psParameter.ComputerName = $Server
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Invoke-DMExchange.WinRM.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $Server
			return
		}
		#endregion PS Remoting
		
		#region Execute
		try {
			switch ($testResult.Type) {
				'Install'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-DMExchange.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMExchange.Installing' -ActionStringValues $testItem.Configuration -Target $domainObject -ScriptBlock {
						Invoke-ExchangeDomainUpdate -Session $session -Path $testItem.Configuration.LocalImagePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'Update'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-DMExchange.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMExchange.Updating' -ActionStringValues $testItem.Configuration -Target $domainObject -ScriptBlock {
						Invoke-ExchangeDomainUpdate -Session $session -Path $testItem.Configuration.LocalImagePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
			}
		}
		#endregion Execute
		finally {
			if ($session) { Remove-PSSession -Session $session -ErrorAction Ignore -Confirm:$false -WhatIf:$false }
		}
	}
}
