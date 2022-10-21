function Test-DMGroupMembership {
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
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type GroupMemberShips -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		:main foreach ($groupMembershipName in $script:groupMemberShips.Keys) {
			$resolvedGroupName = Resolve-String -Text $groupMembershipName
			$processingMode = 'Constrained'
			if ($script:groupMemberShips[$groupMembershipName].__Configuration.ProcessingMode) {
				$processingMode = $script:groupMemberShips[$groupMembershipName].__Configuration.ProcessingMode
			}

			$resultDefaults = @{
				Server     = $Server
				ObjectType = 'GroupMembership'
			}

			#region Resolve Assignments
			$failedResolveAssignment = $false
			$assignments = foreach ($assignment in $script:groupMemberShips[$groupMembershipName].Values) {
				if ($assignment.PSObject.TypeNames -contains 'DomainManagement.GroupMembership.Configuration') { continue }
				
				#region Explicit Entity
				if ($assignment.Name) {
					$param = @{
						Domain = Resolve-String -Text $assignment.Domain
					} + $parameters
					if ((Resolve-String -Text $assignment.Name) -as [System.Security.Principal.SecurityIdentifier]) { $param['Sid'] = Resolve-String -Text $assignment.Name }
					else {
						$param['Name'] = Resolve-String -Text $assignment.Name
						$param['ObjectClass'] = $assignment.ItemType
					}
					try { $adResult = Get-Principal @param }
					catch {
						# If it's a member that is allowed to NOT exist, simply skip the entry
						if ($assignment.Mode -in 'MemberIfExists', 'MayBeMemberIfExists') { continue }
						Write-PSFMessage -Level Warning -String 'Test-DMGroupMembership.Assignment.Resolve.Connect' -StringValues (Resolve-String -Text $assignment.Domain), (Resolve-String -Text $assignment.Name), $assignment.ItemType -ErrorRecord $_ -Target $assignment
						$failedResolveAssignment = $true
						[PSCustomObject]@{
							Assignment = $assignment
							ADMember   = $null
							Type       = 'Explicit'
						}
						continue
					}
					if (-not $adResult) {
						# If it's a member that is allowed to NOT exist, simply skip the entry
						if ($assignment.Mode -in 'MemberIfExists', 'MayBeMemberIfExists') { continue }
						Write-PSFMessage -Level Warning -String 'Test-DMGroupMembership.Assignment.Resolve.NotFound' -StringValues (Resolve-String -Text $assignment.Domain), (Resolve-String -Text $assignment.Name), $assignment.ItemType -Target $assignment
						$failedResolveAssignment = $true
						[PSCustomObject]@{
							Assignment = $assignment
							ADMember   = $null
							Type       = 'Explicit'
						}
						continue
					}
					[PSCustomObject]@{
						Assignment = $assignment
						ADMember   = $adResult
						Type       = 'Explicit'
					}
				}
				#endregion Explicit Entity

				#region Object Category
				elseif ($assignment.Category) {
					try { $adObjects = Find-DMObjectCategoryItem @parameters -Name $assignment.Category -Property ObjectSID, SamAccountName -EnableException }
					catch {
						Stop-PSFFunction -String 'Test-DMGroupMembership.Category.Error' -StringValues $assignment.Category, $assignment.Group -ErrorRecord $_ -Continue -ContinueLabel main -EnableException $EnableException -Target $assignment
					}

					foreach ($adObject in $adObjects) {
						[PSCustomObject]@{
							Assignment = $assignment
							ADMember   = $adObject
							Type       = 'Category'
						}
					}
				}
				#endregion Object Category
			}
			#endregion Resolve Assignments

			#region Check Current AD State
			try {
				$adObject = Get-ADGroup @parameters -Identity $resolvedGroupName -Properties Members -ErrorAction Stop
				$adMembers = $adObject.Members | ForEach-Object {
					$distinguishedName = $_
					try { Get-ADObject @parameters -Identity $_ -ErrorAction Stop -Properties SamAccountName, objectSid }
					catch {
						$objectDomainName = $distinguishedName.Split(",").Where{ $_ -like "DC=*" } -replace '^DC=' -join "."
						$cred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
						Get-ADObject -Server $objectDomainName @cred -Identity $distinguishedName -ErrorAction Stop -Properties SamAccountName, objectSid
					}
				}
			}
			catch { Stop-PSFFunction -String 'Test-DMGroupMembership.Group.Access.Failed' -StringValues $resolvedGroupName -ErrorRecord $_ -EnableException $EnableException -Continue }
			#endregion Check Current AD State

			#region Compare Assignments to existing state
			foreach ($assignment in $assignments) {
				if (-not $assignment.ADMember) {
					# Principal that should be member could not be found
					New-TestResult @resultDefaults -Type Unresolved -Identity "$(Resolve-String -Text $assignment.Assignment.Group) þ $($assignment.Assignment.ItemType) þ $(Resolve-String -Text $assignment.Assignment.Name)" -Configuration $assignment -ADObject $adObject
					continue
				}

				# Skip if membership is optional
				if ($assignment.Assignment.Mode -in 'MayBeMember', 'MayBeMemberIfExists') { continue }

				if ($adMembers | Where-Object ObjectSID -EQ $assignment.ADMember.objectSID) {
					continue
				}
				$change = [PSCustomObject]@{
					PSTypeName = 'DomainManagement.GroupMember.Change'
					Action     = 'Add'
					Group      = Resolve-String -Text $assignment.Assignment.Group
					Member     = Resolve-String -Text $assignment.ADMember.SamAccountName
					Type       = $assignment.ADMember.ObjectClass
				}
				Add-Member -InputObject $change -MemberType ScriptMethod -Name ToString -Value { 'Add: {0} -> {1}' -f $this.Member, $this.Group } -Force
				New-TestResult @resultDefaults -Type Add -Identity "$(Resolve-String -Text $assignment.Assignment.Group) þ $($assignment.ADMember.ObjectClass) þ $(Resolve-String -Text $assignment.ADMember.SamAccountName)" -Configuration $assignment -ADObject $adObject -Changed $change
			}
			#endregion Compare Assignments to existing state
			
			if ($processingMode -eq 'Additive') { continue }
			
			#region Compare existing state to assignments
			foreach ($adMember in $adMembers) {
				if ("$($adMember.ObjectSID)" -in ($assignments.ADMember.ObjectSID | ForEach-Object { "$_" })) {
					continue
				}
				$configObject = [PSCustomObject]@{
					Assignment = $null
					ADMember   = $adMember
				}

				$identifier = $adMember.SamAccountName
				if (-not $identifier) {
					try { $identifier = Resolve-Principal -Name $adMember.ObjectSid -OutputType SamAccountName -ErrorAction Stop }
					catch { $identifier = $adMember.ObjectSid }
				}
				if (-not $identifier) { $identifier = $adMember.ObjectSid }
				if ($failedResolveAssignment -and ($adMember.ObjectClass -eq 'foreignSecurityPrincipal')) {
					# Currently a member, is foreignSecurityPrincipal and we cannot be sure we resolved everything that should be member
					New-TestResult @resultDefaults -Type Unidentified -Identity "$($adObject.Name) þ $($adMember.ObjectClass) þ $($identifier)" -Configuration $configObject -ADObject $adObject
				}
				else {
					$change = [PSCustomObject]@{
						PSTypeName = 'DomainManagement.GroupMember.Change'
						Action     = 'Remove'
						Group      = $adObject.Name
						Member     = $identifier
						Type       = $adMember.ObjectClass
					}
					Add-Member -InputObject $change -MemberType ScriptMethod -Name ToString -Value { 'Remove: {0} -> {1}' -f $this.Member, $this.Group } -Force
					New-TestResult @resultDefaults -Type Delete -Identity "$($adObject.Name) þ $($adMember.ObjectClass) þ $($identifier)" -Configuration $configObject -ADObject $adObject -Changed $change
				}
			}
			#endregion Compare existing state to assignments
		}
	}
}