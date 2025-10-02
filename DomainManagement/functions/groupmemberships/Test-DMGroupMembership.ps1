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

		$resultDefaults = @{
			Server     = $Server
			ObjectType = 'GroupMembership'
		}

		#region Functions
		function Get-GroupMember {
			[CmdletBinding()]
			param (
				$ADObject,

				[hashtable]
				$Parameters
			)

			$ADObject.Members | ForEach-Object {
				$distinguishedName = $_
				try { Get-ADObject @parameters -Identity $_ -ErrorAction Stop -Properties SamAccountName, objectSid }
				catch {
					$objectDomainName = $distinguishedName.Split(",").Where{ $_ -like "DC=*" } -replace '^DC=' -join "."
					$cred = $Parameters | ConvertTo-PSFHashtable -Include Credential
					Get-ADObject -Server $objectDomainName @cred -Identity $distinguishedName -ErrorAction Stop -Properties SamAccountName, objectSid
				}
			}
		}

		function New-MemberRemovalResult {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$ADObject,

				$ADMember,

				[switch]
				$AssignmentsUnresolved,

				$ResultDefaults
			)

			$configObject = [PSCustomObject]@{
				Assignment = $null
				ADMember   = $adMember
			}

			$identifier = $ADMember.SamAccountName
			if (-not $identifier) {
				try { $identifier = Resolve-Principal -Name $ADMember.ObjectSid -OutputType SamAccountName -ErrorAction Stop }
				catch { $identifier = $ADMember.ObjectSid }
			}
			if (-not $identifier) { $identifier = $ADMember.ObjectSid }
			if ($AssignmentsUnresolved -and ($ADMember.ObjectClass -eq 'foreignSecurityPrincipal')) {
				# Currently a member, is foreignSecurityPrincipal and we cannot be sure we resolved everything that should be member
				New-TestResult @resultDefaults -Type Unidentified -Identity "$($ADObject.Name) þ $($ADMember.ObjectClass) þ $($identifier)" -Configuration $configObject -ADObject $ADObject
			}
			else {
				$change = [PSCustomObject]@{
					PSTypeName = 'DomainManagement.GroupMember.Change'
					Action     = 'Remove'
					Group      = $ADObject.Name
					Member     = $identifier
					Type       = $ADMember.ObjectClass
				}
				Add-Member -InputObject $change -MemberType ScriptMethod -Name ToString -Value { 'Remove: {0} -> {1}' -f $this.Member, $this.Group } -Force
				New-TestResult @resultDefaults -Type Delete -Identity "$($ADObject.Name) þ $($ADMember.ObjectClass) þ $($identifier)" -Configuration $configObject -ADObject $ADObject -Changed $change
			}
		}
		#endregion Functions
	}
	process {
		#region Configured Memberships
		$groupsProcessed = [System.Collections.ArrayList]@()

		:main foreach ($groupMembershipName in $script:groupMemberShips.Keys) {
			$resolvedGroupName = Resolve-String -Text $groupMembershipName
			$processingMode = 'Constrained'
			if ($script:groupMemberShips[$groupMembershipName].__Configuration.ProcessingMode) {
				$processingMode = $script:groupMemberShips[$groupMembershipName].__Configuration.ProcessingMode
			}

			#region Resolve Assignments
			$failedResolveAssignment = $false
			$groupNeedsNotExist = $true
			$assignments = foreach ($assignment in $script:groupMemberShips[$groupMembershipName].Values) {
				if ($assignment.PSObject.TypeNames -contains 'DomainManagement.GroupMembership.Configuration') { continue }
				if (-not $assignment.GroupOptional) { $groupNeedsNotExist = $false }
				
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
				$null = $groupsProcessed.Add($adObject.SamAccountName)
				$adMembers = Get-GroupMember -ADObject $adObject -Parameters $parameters
			}
			catch {
				if ($groupNeedsNotExist) {
					Write-PSFMessage -Level Debug -String 'Test-DMGroupMembership.Group.Access.Failed' -StringValues $resolvedGroupName -ErrorRecord $_
					continue
				}
				Stop-PSFFunction -String 'Test-DMGroupMembership.Group.Access.Failed' -StringValues $resolvedGroupName -ErrorRecord $_ -EnableException $EnableException -Continue
			}
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
				[PSFramework.Object.ObjectHost]::AddScriptMethod($change, 'ToString', { 'Add: {0} -> {1}' -f $this.Member, $this.Group })
				New-TestResult @resultDefaults -Type Add -Identity "$(Resolve-String -Text $assignment.Assignment.Group) þ $($assignment.ADMember.ObjectClass) þ $(Resolve-String -Text $assignment.ADMember.SamAccountName)" -Configuration $assignment -ADObject $adObject -Changed $change
			}
			#endregion Compare Assignments to existing state
			
			if ($processingMode -eq 'Additive') { continue }
			
			#region Compare existing state to assignments
			foreach ($adMember in $adMembers) {
				if ("$($adMember.ObjectSID)" -in ($assignments.ADMember.ObjectSID | ForEach-Object { "$_" })) {
					continue
				}
				New-MemberRemovalResult -ADObject $adObject -ADMember $adMember -AssignmentsUnresolved:$failedResolveAssignment -ResultDefaults $resultDefaults
			}
			#endregion Compare existing state to assignments
		}
		#endregion Configured Memberships
	
		#region Groups without configured Memberships
		if ($script:contentMode.ExcludeComponents.GroupMembership) { return }

		$foundGroups = foreach ($searchBase in (Resolve-ContentSearchBase @parameters)) {
			Get-ADGroup @parameters -LDAPFilter '(name=*)' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope -Properties Members | Where-Object {
				$_.SamAccountName -NotIn $groupsProcessed -and
				@($_.Members).Count -gt 0
			}
		}

		foreach ($adObject in $foundGroups) {
			$adMembers = Get-GroupMember -ADObject $adObject -Parameters $parameters

			foreach ($adMember in $adMembers) {
				New-MemberRemovalResult -ADObject $adObject -ADMember $adMember -ResultDefaults $resultDefaults
			}
		}
		#endregion Groups without configured Memberships
	}
}