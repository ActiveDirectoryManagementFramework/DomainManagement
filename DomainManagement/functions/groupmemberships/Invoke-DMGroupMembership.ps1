function Invoke-DMGroupMembership {
	<#
	.SYNOPSIS
		Applies the desired group memberships to the target domain.
	
	.DESCRIPTION
		Applies the desired group memberships to the target domain.
		Use Register-DMGroupMembership to configure just what is considered desired.
		Use Set-DMDomainCredential to prepare authentication as needed for remote domains, when principals from that domain must be resolved.
	
	.PARAMETER InputObject
		Test results provided by the associated test command.
		Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
	
	.PARAMETER RemoveUnidentified
		By default, existing permissions for foreign security principals that cannot be resolved will only be deleted, if every single configured membership was resolveable.
		In cases where that is not possible, these memberships are flagged as "Unidentified"
		Using this parameter you can enforce deleting them anyway.
	
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
		PS C:\> Invoke-DMGroupMembership -Server contoso.com

		Applies the desired group membership configuration to the contoso.com domain
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[switch]
		$RemoveUnidentified,

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
		Assert-Configuration -Type GroupMemberShips -Cmdlet $PSCmdlet
		$testResult = Test-DMGroupMembership @parameters
		Set-DMDomainContext @parameters

		#region Utility Functions
		function Add-GroupMember {
			[CmdletBinding()]
			param (
				[string]
				$GroupDN,
				[string]
				$SID,
				[string]
				$Server,
				[PSCredential]
				$Credential
			)

			if ($Server) { $path = "LDAP://$Server/$GroupDN" }
			else { $path = "LDAP://$GroupDN" }
			if ($Credential) {
				$group = New-Object DirectoryServices.DirectoryEntry($path, $Credential.UserName, $Credential.GetNetworkCredential().Password)
			}
			else {
				$group = New-Object DirectoryServices.DirectoryEntry($path)
			}
			[void]$group.member.Add("<SID=$SID>")
			$group.CommitChanges()
			$group.Close()
		}

		function Remove-GroupMember {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				[string]
				$GroupDN,
				[string]
				$SID,
				[string]
				$TargetDN,
				[string]
				$Server,
				[PSCredential]
				$Credential
			)

			if ($Server) { $path = "LDAP://$Server/$GroupDN" }
			else { $path = "LDAP://$GroupDN" }
			if ($Credential) {
				$group = New-Object DirectoryServices.DirectoryEntry($path, $Credential.UserName, $Credential.GetNetworkCredential().Password)
			}
			else {
				$group = New-Object DirectoryServices.DirectoryEntry($path)
			}
			$group.member.Remove("<SID=$SID>")
			$group.member.Remove($TargetDN)
			try {
				$group.CommitChanges()
			}
			catch {
				$group.Close()

				if ($Credential) {
					$group = New-Object DirectoryServices.DirectoryEntry($path, $Credential.UserName, $Credential.GetNetworkCredential().Password)
				}
				else {
					$group = New-Object DirectoryServices.DirectoryEntry($path)
				}
				$group.member.Remove($TargetDN)
				$group.CommitChanges()
			}
			finally {
				$group.Close()
			}
		}
		#endregion Utility Functions
	}
	process {
		if (-not $InputObject) {
			$InputObject = Test-DMGroupMembership @parameters
		}
		
		foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.GroupMembership.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMGroupMembership', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				'Add' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupMembership.GroupMember.Add' -ActionStringValues $testItem.ADObject.Name -Target $testItem -ScriptBlock {
						Add-GroupMember @parameters -SID $testItem.Configuration.ADObject.ObjectSID -GroupDN $testItem.ADObject.DistinguishedName
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Remove' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupMembership.GroupMember.Remove' -ActionStringValues $testItem.ADObject.Name -Target $testItem -ScriptBlock {
						Remove-GroupMember @parameters -SID $testItem.Configuration.ADObject.ObjectSID -TargetDN $testItem.Configuration.ADObject.DistinguishedName -GroupDN $testItem.ADObject.DistinguishedName
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
				}
				'Unresolved' {
					Write-PSFMessage -Level Warning -String 'Invoke-DMGroupMembership.Unresolved' -StringValues $testItem.Identity -Target $testItem
				}
				'Unidentified' {
					if ($RemoveUnidentified) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DMGroupMembership.GroupMember.RemoveUnidentified' -ActionStringValues $testItem.ADObject.Name -Target $testItem -ScriptBlock {
							Remove-GroupMember @parameters -SID $testItem.Configuration.ADObject.ObjectSID -GroupDN $testItem.ADObject.DistinguishedName
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}
					else {
						Write-PSFMessage -Level Warning -String 'Invoke-DMGroupMembership.Unidentified' -StringValues $testItem.Identity -Target $testItem
					}
				}
			}
		}
	}
}