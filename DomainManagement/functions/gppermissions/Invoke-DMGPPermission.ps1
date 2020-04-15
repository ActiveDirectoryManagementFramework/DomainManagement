function Invoke-DMGPPermission
{
	<#
	.SYNOPSIS
		Brings the current Group Policy Permissions into compliance with the desired state defined in configuration.
	
	.DESCRIPTION
		Brings the current Group Policy Permissions into compliance with the desired state defined in configuration.
		- Use Register-DMGPPermission and Register-DMGPPermissionFilter to define the desired state
		- Use Test-DMGPPermission to preview the changes it would apply
		
		This command accepts the output objects of Test-DMGPPermission as input, allowing you to precisely define, which changes to actually apply.
		If you do not do so, ALL deviations from the desired state will be corrected.
	
	.PARAMETER InputObject
		Test results provided by Test-DMGPPermission.
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
		PS C:\> Invoke-DMGPPermission -Server corp.contoso.com

		Brings the group policy object permissions of the domain corp.contoso.com into compliance with the desired state.
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
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
		Assert-Configuration -Type GroupPolicyPermissions -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
		$computerName = (Get-ADDomain @parameters).PDCEmulator
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential -Inherit
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Invoke-DMGPPermission.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}

		#region Utility Functions
		function ConvertTo-ADAccessRule {
			[OutputType([System.DirectoryServices.ActiveDirectoryAccessRule])]
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$ChangeEntry
			)

			begin {
				$guidEmpty = [System.Guid]::Empty
				$guidApplyGpoRight = [System.Guid]'edacfd8f-ffb3-11d1-b41d-00a0c968f939'
				$inheritanceType = 'All'

				$rightsMap = @{
					'GpoRead' = ([System.DirectoryServices.ActiveDirectoryRights]'GenericRead')
					'GpoApply' = ([System.DirectoryServices.ActiveDirectoryRights]'GenericRead')
					'GpoEdit' = ([System.DirectoryServices.ActiveDirectoryRights]' CreateChild, DeleteChild, ReadProperty, WriteProperty, GenericExecute')
					'GpoEditDeleteModifySecurity' = ([System.DirectoryServices.ActiveDirectoryRights]'CreateChild, DeleteChild, Self, WriteProperty, DeleteTree, Delete, GenericRead, WriteDacl, WriteOwner')
					'GpoCustom' = ([System.DirectoryServices.ActiveDirectoryRights]'CreateChild, Self, WriteProperty, GenericRead, WriteDacl, WriteOwner')
				}

				<#
				System.Security.Principal.IdentityReference identity
				System.DirectoryServices.ActiveDirectoryRights adRights
				System.Security.AccessControl.AccessControlType type
				guid objectType
				System.DirectoryServices.ActiveDirectorySecurityInheritance inheritanceType
				guid inheritedObjectType
				#>
			}
			process {
				foreach ($change in $ChangeEntry) {
					# Identity property might be 'deserialized'
					$identityReference = $change.Identity -as [string] -as [System.Security.Principal.SecurityIdentifier]
					[System.Security.AccessControl.AccessControlType]$type = 'Allow'
					if (-not $change.Allow) { $type = 'Deny' }
					[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
						$identityReference,
						$rightsMap[$change.Permission],
						$type,
						$guidEmpty,
						$inheritanceType,
						$guidEmpty
					)
					if ($change.Permission -eq 'GpoApply') {
						[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
							$identityReference,
							([System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight),
							$type,
							$guidApplyGpoRight,
							$inheritanceType,
							$guidEmpty
						)
					}
				}
			}
		}
		#endregion Utility Functions
	}
	process
	{
		try {
			# Test All GPO permissions if no specific test result was specified
			if (-not $InputObject) {
				$InputObject = Test-DMGPPermission @parameters -EnableException:$EnableException
			}

			#region Process Test results
			foreach ($testResult in $InputObject) {
				# Catch invalid input - can only process test results
				if ($testResult.PSObject.TypeNames -notcontains 'DomainManagement.GPPermission.TestResult') {
					Stop-PSFFunction -String 'Invoke-DMGPPermission.Invalid.Input' -StringValues $testResult -Target $testResult -Continue -EnableException $EnableException
				}

				if ($testResult.Type -eq 'AccessError') {
					Write-PSFMessage -Level Warning -String 'Invoke-DMGPPermission.Result.Access.Error' -StringValues $testResult.Identity -Target $testResult
					continue
				}

				try { $acl = Get-AdsAcl -Path $testResult.AdObject.DistinguishedName @parameters -ErrorAction Stop }
				catch { Stop-PSFFunction -String 'Invoke-DMGPPermission.AD.Access.Error' -StringValues $testResult, $testResult.ADObject.DistinguishedName -ErrorRecord $_ -Continue -EnableException $EnableException }
				
				[string[]]$applicableIdentities = $acl.Access.Identity | Remove-PSFNull | Resolve-String | Convert-Principal @parameters
				
				# Process Remove actions first, as they might interfere when processed last and replacing permissions.
				foreach ($change in ($testResult.Changed | Sort-Object Action -Descending)) {
					#region Remove
					if ($change.Action -eq 'Remove') {
						if (($change.Permission -eq 'GpoCustom') -or ($applicableIdentities -notcontains $change.Identity)) {
							$rulesToRemove = $acl.Access | Where-Object {
								$_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).ToString() -eq $change.Identity
							}
						}
						else {
							$accessRulesToRemove = ConvertTo-ADAccessRule -ChangeEntry $change
							$rulesToRemove = $acl.Access | Compare-ObjectProperty -ReferenceObject $accessRulesToRemove -PropertyName ActiveDirectoryRights, AccessControlType, 'IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]) to String as IdentityReference'
						}
						foreach ($rule in $rulesToRemove) { $null = $acl.RemoveAccessRule($rule) }
					}
					#endregion Remove

					#region Add
					else {
						if ($change.Permission -eq 'GpoCustom') {
							$acl.Access | Where-Object {
								$_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).ToString() -eq $change.Identity
							} | ForEach-Object { $null = $acl.RemoveAccessRule($_) }
						}
						$accessRulesToAdd = ConvertTo-ADAccessRule -ChangeEntry $change
						foreach ($rule in $accessRulesToAdd) { $null = $acl.AddAccessRule($rule) }
					}
					#endregion Add
				}

				Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPPermission.AD.UpdatingPermission' -ActionStringValues $testResult.Changed.Count -ScriptBlock {
					$acl | Set-AdsAcl @parameters -Confirm:$false -EnableException
				} -Continue -EnableException $true -PSCmdlet $PSCmdlet -Target $testResult
				Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGPPermission.Gpo.SyncingPermission' -ActionStringValues $testResult.Changed.Count -ScriptBlock {
					$domainObject = Get-Domain2 @parameters
					Invoke-Command -Session $session -ScriptBlock {
						$gpoObject = Get-Gpo -Server localhost -DisplayName $using:testResult.Identity -Domain $using:domainObject.DNSRoot -ErrorAction Stop
						$gpoObject.MakeAclConsistent()
					} -ErrorAction Stop
				} -Continue -EnableException $true -PSCmdlet $PSCmdlet -Target $testResult
			}
			#endregion Process Test results
		}
		
		finally {
			if ($session) { $session | Remove-PSSession -WhatIf:$false -Confirm:$false }
		}
	}
}
