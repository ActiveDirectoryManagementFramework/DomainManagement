function Invoke-FMExchangeSchema
{
<#
	.SYNOPSIS
		Applies the desired Exchange version to the tareted Forest.
	
	.DESCRIPTION
		Applies the desired Exchange version to the tareted Forest.
		Requires Schema Admin & Enterprise Admin privileges.
	
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
		PS C:\> Invoke-FMExchangeSchema -Server contoso.com
	
		Applies the desired Exchange version to the contoso.com Forest.
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param (
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
		Assert-Configuration -Type Schema -Cmdlet $PSCmdlet
		$forestObject = Get-ADForest @parameters
		
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		$psParameter.ComputerName = $Server
		
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -String 'Invoke-FMExchangeSchema.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}
		
		#region Functions
		function Test-ExchangeIsoPath
		{
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
		
		function Invoke-ExchangeSchemaUpdate
		{
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
				$diskImage = Mount-DiskImage -ImagePath $exchangeIsoPath
				$volume = Get-Volume -DiskImage $diskImage
				$installPath = "$($volume.DriveLetter):\setup.exe"
				
				# Perform Installation
				$resultText = & $installPath /IAcceptExchangeServerLicenseTerms /PrepareAD 2>&1
				$results = [pscustomobject]@{
					Success = $LASTEXITCODE -lt 1
					Message = $resultText -join "`n"
				}
				
				# Dismount Volume
				Dismount-DiskImage -DevicePath $diskImage.DevicePath
				
				# Report result
				$results
			}
			if (-not $result.Success)
			{
				throw "Error applying exchange update: $($result.Message)"
			}
		}
		#endregion Functions
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		foreach ($testItem in Test-FMExchangeSchema @parameters)
		{
			#region Apply Updates if needed
			switch ($testItem.Type)
			{
				#region Install Exchange Schema
				'Create'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath))
					{
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.Installing' -ActionStringValues $testItem.Configuration -Target $forestObject -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Path $testItem.Configuration.LocalImagePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Install Exchange Schema
				#region Update Exchange Schema
				'Update'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath))
					{
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.Updating' -ActionStringValues $testItem.ADObject, $testItem.Configuration -Target $forestObject -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Path $testItem.Configuration.LocalImagePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Update Exchange Schema
			}
			#endregion Apply Updates if needed
		}
	}
	end
	{
		if ($session) { Remove-PSSession -Session $session -ErrorAction Ignore -Confirm:$false -WhatIf:$false }
	}
}
