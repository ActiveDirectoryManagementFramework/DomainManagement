function Invoke-DMOrganizationalUnit
{
	<#
	.SYNOPSIS
		Updates the organizational units of a domain to be compliant with the desired state.
	
	.DESCRIPTION
		Updates the organizational units of a domain to be compliant with the desired state.
		Use Register-DMOrganizationalUnit to define a desired state before using this command.
		Use Test-DMorganizationalUnit to receive details about the changes it will perform.
	
	.PARAMETER Delete
		Implement deletion commands.
		By default, when updating an existing deployment you would need to creaate missing OUs first, then move other objects and only delete OUs as the final step.
		In order to prevent accidents, by default NO OUs will be deleted.
		To enable OU deletion, you must specify this parameter.
		This parameter allows you to call it twice in your workflow: Once to prepare it for other objects, and another time to do the cleanup.
	
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
		PS C:\> Invoke-DMOrganizationalUnit -Server contoso.com

		Brings the domain contoso.com into OU compliance.
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[switch]
		$Delete,

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
		Assert-Configuration -Type OrganizationalUnits -Cmdlet $PSCmdlet
		$everyone = ([System.Security.Principal.SecurityIdentifier]'S-1-1-0').Translate([System.Security.Principal.NTAccount])
		Set-DMDomainContext @parameters
	}
	process
	{
		#region Sort Script
		$sortScript = {
			if ($_.Type -eq 'ShouldDelete') { $_.ADObject.DistinguishedName.Split(",").Count }
			else { 1000 - $_.Identity.Split(",").Count }
		}
		#endregion Sort Script
		if (-not $InputObject) {
			$InputObject = Test-DMOrganizationalUnit @parameters | Sort-Object $sortScript -Descending
		}
		
		:main foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.OrganizationalUnit.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMOrganizationalUnit', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				'Delete' {
					if (-not $Delete) {
						Write-PSFMessage -String 'Invoke-DMOrganizationalUnit.OU.Delete.NoAction' -StringValues $testItem.Identity -Target $testItem
						continue main
					}
					$childObjects = Get-ADObject @parameters -SearchBase $testItem.ADObject.DistinguishedName -LDAPFilter '(!(objectCategory=OrganizationalUnit))'
					if ($childObjects) {
						Write-PSFMessage -Level Warning -String 'Invoke-DMOrganizationalUnit.OU.Delete.HasChildren' -StringValues $testItem.ADObject.DistinguishedName, ($childObjects | Measure-Object).Count -Target $testItem -Tag 'ou','critical','panic'
						continue main
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMOrganizationalUnit.OU.Delete' -Target $testItem -ScriptBlock {
						# Remove "Protect from accidental deletion" if neccessary
						if ($accidentProtectionRule = ($testItem.ADObject.nTSecurityDescriptor.Access | Where-Object { ($_.IdentityReference -eq $everyone) -and ($_.AccessControlType -eq 'Deny') }))
						{
							$null = $testItem.ADObject.nTSecurityDescriptor.RemoveAccessRule($accidentProtectionRule)
							Set-ADObject @parameters -Identity $testItem.ADObject.DistinguishedName -Replace @{ nTSecurityDescriptor = $testItem.ADObject.nTSecurityDescriptor } -ErrorAction Stop -Confirm:$false
						}
						Remove-ADOrganizationalUnit @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Create' {
					$targetOU = Resolve-String -Text $testItem.Configuration.Path
					try { $null = Get-ADObject @parameters -Identity $targetOU -ErrorAction Stop }
					catch { Stop-PSFFunction -String 'Invoke-DMOrganizationalUnit.OU.Create.OUExistsNot' -StringValues $targetOU, $testItem.Identity -Target $testItem -EnableException $EnableException -Continue -ContinueLabel main }
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMOrganizationalUnit.OU.Create' -Target $testItem -ScriptBlock {
						$newParameters = $parameters.Clone()
						$newParameters += @{
							Name = (Resolve-String -Text $testItem.Configuration.Name)
							Description = (Resolve-String -Text $testItem.Configuration.Description)
							Path = $targetOU
							Confirm = $false
						}
						New-ADOrganizationalUnit @newParameters -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'MultipleOldOUs' {
					Stop-PSFFunction -String 'Invoke-DMOrganizationalUnit.OU.MultipleOldOUs' -StringValues $testItem.Identity, ($testItem.ADObject.Name -join ', ') -Target $testItem -EnableException $EnableException -Continue -Tag 'ou','critical','panic'
				}
				'Rename' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMOrganizationalUnit.OU.Rename' -ActionStringValues (Resolve-String -Text $testItem.Configuration.Name) -Target $testItem -ScriptBlock {
						Rename-ADObject @parameters -Identity $testItem.ADObject.ObjectGUID -NewName (Resolve-String -Text $testItem.Configuration.Name) -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Update' {
					$changes = @{ }
					if ($change = $testItem.Changed | Where-Object Property -eq 'Description') {
						$changes['Description'] = $change.New
					}
					
					if ($changes.Keys.Count -gt 0)
					{
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMOrganizationalUnit.OU.Update' -ActionStringValues ($changes.Keys -join ", ") -Target $testItem -ScriptBlock {
							$null = Set-ADObject @parameters -Identity $testItem.ADObject.ObjectGUID -ErrorAction Stop -Replace $changes -Confirm:$false
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}
				}
			}
		}
	}
	end
	{
		# Reset Content Searchbases
		$script:contentSearchBases = [PSCustomObject]@{
			Include = @()
			Exclude = @()
			Bases   = @()
			Server = ''
		}
	}
}
