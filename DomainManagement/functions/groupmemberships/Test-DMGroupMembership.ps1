function Test-DMGroupMembership
{
	<#
	.SYNOPSIS
		Tests, whether the target domain is compliant with the desired group membership assignments.
	
	.DESCRIPTION
		Tests, whether the target domain is compliant with the desired group membership assignments.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Test-DMGroupMembership -Server contoso.com

		Tests, whether the "contoso.com" domain is in compliance with the desired group membership assignments.
	#>
	[CmdletBinding()]
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
		Assert-Configuration -Type GroupMemberShips -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		:main foreach ($groupMembershipNames in $script:groupMemberShips.Keys) {
			$resolvedGroupName = Resolve-String -Text $groupMembershipNames

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'GroupMembership'
			}

			#region Resolve Assignments
			$failedResolveAssignment = $false
			$assignments = foreach ($assignment in $script:groupMemberShips[$groupMembershipNames].Values) {
				try { $adResult = Get-Principal @parameters -Domain (Resolve-String -Text $assignment.Domain) -Name (Resolve-String -Text $assignment.Name) -ObjectClass $assignment.ItemType }
				catch {
					Write-PSFMessage -Level Warning -String 'Test-DMGroupMembership.Assignment.Resolve.Connect' -StringValues (Resolve-String -Text $assignment.Domain), (Resolve-String -Text $assignment.Name), $assignment.ItemType -ErrorRecord $_ -Target $assignment
					$failedResolveAssignment = $true
					[PSCustomObject]@{
						Assignment = $assignment
						ADObject = $null
					}
					continue
				}
				if (-not $adResult) {
					Write-PSFMessage -Level Warning -String 'Test-DMGroupMembership.Assignment.Resolve.NotFound' -StringValues (Resolve-String -Text $assignment.Domain), (Resolve-String -Text $assignment.Name), $assignment.ItemType -Target $assignment
					$failedResolveAssignment = $true
					[PSCustomObject]@{
						Assignment = $assignment
						ADObject = $null
					}
					continue
				}
				[PSCustomObject]@{
					Assignment = $assignment
					ADObject = $adResult
				}
			}
			#endregion Resolve Assignments

			try {
				$adObject = Get-ADGroup @parameters -Identity $resolvedGroupName -Properties Members -ErrorAction Stop
				$adMembers = $adObject.Members | ForEach-Object {
					$distinguishedName = $_
					try { Get-ADObject @parameters -Identity $_ -ErrorAction Stop -Properties SamAccountName, objectSid }
					catch {
						$objectDomainName = $distinguishedName.Split(",").Where{$_ -like "DC=*"} -replace '^DC=' -join "."
						$cred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
						Get-ADObject -Server $objectDomainName @cred -Identity $distinguishedName -ErrorAction Stop -Properties SamAccountName, objectSid
					}
				}
			}
			catch { Stop-PSFFunction -String 'Test-DMGroupMembership.Group.Access.Failed' -StringValues $resolvedGroupName -ErrorRecord $_ -EnableException $EnableException -Continue }

			foreach ($assignment in $assignments) {
				if (-not $assignment.ADObject) {
					# Principal that should be member could not be found
					New-TestResult @resultDefaults -Type Unresolved -Identity "$(Resolve-String -Text $assignment.Assignment.Group)þ$($assignment.Assignment.ItemType)þ$(Resolve-String -Text $assignment.Assignment.Name)" -Configuration $assignment -ADObject $adObject
					continue
				}
				if ($adMembers | Where-Object ObjectSID -eq $assignment.ADObject.objectSID) {
					continue
				}
				New-TestResult @resultDefaults -Type Add -Identity "$(Resolve-String -Text $assignment.Assignment.Group)þ$($assignment.Assignment.ItemType)þ$(Resolve-String -Text $assignment.Assignment.Name)" -Configuration $assignment -ADObject $adObject
			}

			foreach ($adMember in $adMembers) {
				if ($adMember.ObjectSID -in $assignments.ADObject.ObjectSID) {
					continue
				}
				$configObject = [PSCustomObject]@{
					Assignment = $null
					ADObject = $adMember
				}

				if ($failedResolveAssignment -and ($adMember.ObjectClass -eq 'foreignSecurityPrincipal')) {
					# Currently a member, is foreignSecurityPrincipal and we cannot be sure we resolved everything that should be member
					New-TestResult @resultDefaults -Type Unidentified -Identity "$($adObject.Name)þ$($adMember.ObjectClass)þ$($adMember.SamAccountName)" -Configuration $configObject -ADObject $adObject
				}
				else {
					New-TestResult @resultDefaults -Type Remove -Identity "$($adObject.Name)þ$($adMember.ObjectClass)þ$($adMember.SamAccountName)" -Configuration $configObject -ADObject $adObject
				}
			}
		}
	}
}