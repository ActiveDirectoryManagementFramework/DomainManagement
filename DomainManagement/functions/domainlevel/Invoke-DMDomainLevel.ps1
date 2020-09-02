function Invoke-DMDomainLevel
{
<#
	.SYNOPSIS
		Applies the desired domain level if needed.
	
	.DESCRIPTION
		Applies the desired domain level if needed.
	
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
		PS C:\> Invoke-DMDomainLevel -Server contoso.com
	
		Raises the domain "contoso.com" to the desired level if needed.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
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
		Assert-Configuration -Type DomainLevel -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		foreach ($testItem in Test-DMDomainLevel @parameters)
		{
			switch ($testItem.Type)
			{
				'Raise'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMDomainLevel.Raise.Level' -ActionStringValues $testItem.Configuration.Level -Target $testItem.ADObject -ScriptBlock {
						Set-ADDomainMode -DomainMode $testItem.Configuration.DesiredLevel
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
			}
		}
	}
}
