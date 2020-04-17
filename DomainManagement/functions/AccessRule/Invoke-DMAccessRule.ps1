function Invoke-DMAccessRule
{
	<#
	.SYNOPSIS
		Applies the desired state of accessrule configuration.
	
	.DESCRIPTION
		Applies the desired state of accessrule configuration.
		Define the desired state with Register-DMAccessRule.
		Test the desired state with Test-DMAccessRule.
	
	.PARAMETER InputObject
		Test results provided by the associated test command.
		Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.

	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Invoke-DMAccessRule -Server contoso.com

		Applies the desired access rule configuration to the contoso.com domain.
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
		Assert-Configuration -Type accessRules -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process{
		if (-not $InputObject) {
			$InputObject = Test-DMAccessRule @parameters
		}
		
		foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testResult.PSObject.TypeNames -notcontains 'DomainManagement.AccessRule.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMAccessRule', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				'Update'
				{
					Write-PSFMessage -Level Debug -String 'Invoke-DMAccessRule.Processing.Rules' -StringValues $testItem.Identity, $testItem.Changed.Count -Target $testItem

					try { $aclObject = Get-AdsAcl @parameters -Path $testItem.Identity -EnableException }
					catch { Stop-PSFFunction -String 'Invoke-DMAccessRule.Access.Failed' -StringValues $testItem.Identity -EnableException $EnableException -Target $testItem -Continue -ErrorRecord $_ }
					foreach ($changeEntry in $testItem.Changed) {
						#region Remove Access Rules
						if ($changeEntry.Type -eq 'Delete') {
							Write-PSFMessage -Level InternalComment -String 'Invoke-DMAccessRule.AccessRule.Remove' -StringValues $changeEntry.ADObject.IdentityReference, $changeEntry.ADObject.ActiveDirectoryRights, $changeEntry.ADObject.AccessControlType -Target $changeEntry
							if (-not $aclObject.RemoveAccessRule($changeEntry.ADObject.OriginalRule)) {
								Remove-RedundantAce -AccessControlList $aclObject -IdentityReference $changeEntry.ADObject.OriginalRule.IdentityReference
								foreach ($rule in $aclObject.GetAccessRules($true, $false, [System.Security.Principal.NTAccount])) {
									if (Test-AccessRuleEquality -Parameters $parameters -Rule1 $rule -Rule2 $changeEntry.ADObject.OriginalRule) {
										Write-PSFMessage -Level Warning -String 'Invoke-DMAccessRule.AccessRule.Remove.Failed' -StringValues $changeEntry.ADObject.IdentityReference, $changeEntry.ADObject.ActiveDirectoryRights, $changeEntry.ADObject.AccessControlType -Target $changeEntry -Debug:$false
										break
									}
								}
							}
							continue
						}
						#endregion Remove Access Rules

						#region Add Access Rules
						if ($changeEntry.Type -eq 'Create') {
							Write-PSFMessage -Level InternalComment -String 'Invoke-DMAccessRule.AccessRule.Create' -StringValues $changeEntry.Configuration.IdentityReference, $changeEntry.Configuration.ActiveDirectoryRights, $changeEntry.Configuration.AccessControlType -Target $changeEntry
							try {
								if (-not $changeEntry.Configuration.ObjectType) { throw "Unknown ObjectType! Unable to translate $($changeEntry.Configuration.ObjectTypeName). Validate the configuration and ensure pending schema updates (e.g. Exchange, Skype, etc.) have been applied." }
								if (-not $changeEntry.Configuration.InheritedObjectType) { throw "Unknown InheritedObjectType! Unable to translate $($changeEntry.Configuration.InheritedObjectTypeName). Validate the configuration and ensure pending schema updates (e.g. Exchange, Skype, etc.) have been applied." }
								$accessRule = [System.DirectoryServices.ActiveDirectoryAccessRule]::new((Convert-Principal @parameters -Name $changeEntry.Configuration.IdentityReference), $changeEntry.Configuration.ActiveDirectoryRights, $changeEntry.Configuration.AccessControlType, $changeEntry.Configuration.ObjectType, $changeEntry.Configuration.InheritanceType, $changeEntry.Configuration.InheritedObjectType)
							}
							catch {
								Stop-PSFFunction -String 'Invoke-DMAccessRule.AccessRule.Creation.Failed' -StringValues $testItem.Identity, $changeEntry.Configuration.IdentityReference -EnableException $EnableException -Target $changeEntry -Continue -ErrorRecord $_
							}
							$null = $aclObject.AddAccessRule($accessRule)
							#TODO: Validation and remediation of success. Adding can succeed but not do anything, when accessrules are redundant. Potentially flag it for full replacement?
							continue
						}
						#endregion Add Access Rules
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMAccessRule.Processing.Execute' -ActionStringValues $testItem.Changed.Count -Target $testItem -ScriptBlock {
						Set-AdsAcl @parameters -Path $testItem.Identity -AclObject $aclObject -EnableException -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'MissingADObject'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-DMAccessRule.ADObject.Missing' -StringValues $testItem.Identity -Target $testItem -Debug:$false
				}
			}
		}
	}
}
