function Invoke-DMAcl
{
	<#
	.SYNOPSIS
		Applies the desired ACL configuration.
	
	.DESCRIPTION
		Applies the desired ACL configuration.
		To define the desired acl state, use Register-DMAcl.
		
		Note: The ACL suite of commands only manages the ACL itself, not the rules assigned to it!
		Explicitly, this makes this suite the tool to manage inheritance and ownership over an object.
		To manage AccessRules, look at the *-DMAccessRule commands.
	
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
		PS C:\> Invoke-DMAcl -Server contoso.com

		Applies the configured, desired state of object Acl to all managed objects in contoso.com
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
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
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Acls, AclByCategory, AclDefaultOwner -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process{
		if (-not $InputObject) {
			$InputObject = Test-DMAcl @parameters
		}
		
		foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.Acl.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMAcl', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				'MissingADObject'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-DMAcl.MissingADObject' -StringValues $testItem.Identity -Target $testItem
					continue
				}
				'NoAccess'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-DMAcl.NoAccess' -StringValues $testItem.Identity -Target $testItem
					continue
				}
				'OwnerNotResolved'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-DMAcl.OwnerNotResolved' -StringValues $testItem.Identity, $testItem.ADObject.GetOwner([System.Security.Principal.SecurityIdentifier]) -Target $testItem
					continue
				}
				'Changed'
				{
					if ($testItem.Changed -contains 'Owner') {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMAcl.UpdatingOwner' -ActionStringValues ($testItem.Configuration.Owner | Resolve-String) -Target $testItem -ScriptBlock {
							Set-AdsOwner @parameters -Path $testItem.Identity -Identity (Convert-Principal @parameters -Name ($testItem.Configuration.Owner | Resolve-String)) -EnableException -Confirm:$false
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}
					if ($testItem.Changed -contains 'NoInheritance') {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMAcl.UpdatingInheritance' -ActionStringValues $testItem.Configuration.NoInheritance -Target $testItem -ScriptBlock {
							if ($testItem.Configuration.NoInheritance) {
								Disable-AdsInheritance @parameters -Path $testItem.Identity -EnableException -Confirm:$false
							}
							else { Enable-AdsInheritance @parameters -Path $testItem.Identity -EnableException -Confirm:$false }
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}
				}
				'ShouldManage'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-DMAcl.ShouldManage' -StringValues $testItem.Identity -Target $testItem
					continue
				}
			}
		}
	}
}