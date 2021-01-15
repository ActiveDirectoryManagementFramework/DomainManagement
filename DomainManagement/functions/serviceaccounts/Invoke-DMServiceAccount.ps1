function Invoke-DMServiceAccount {
<#
	.SYNOPSIS
		Applies the desired state of Service Accounts to the target domain.
	
	.DESCRIPTION
		Applies the desired state of Service Accounts to the target domain.
		Use Register-DMServiceAccount to define the desired state.
	
	.PARAMETER InputObject
		Individual test results to apply.
		Use Test-DMServiceAccount to generate these test result objects.
		If none are specified, it will instead execute its own test and apply all test results.
	
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
		PS C:\> Invoke-DMServiceAccount -Server fabrikam.org
	
		Brings the fabrikam.org domain into compliance with the defined service account configuration.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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
	
	begin {
		#region Utility Functions
		function Get-ObjectCategoryContent {
			[CmdletBinding()]
			param (
				[System.Collections.Hashtable]
				$Categories,
				
				[string]
				$Name,
				
				[System.Collections.Hashtable]
				$Parameters
			)
			
			if (-not $Categories.ContainsKey($Name)) {
				$Categories[$Name] = (Find-DMObjectCategoryItem -Name $Name @parameters -Property SamAccountName).SamAccountName
			}
			$Categories[$Name]
		}
		
		function New-ServiceAccount {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$TestItem,
				
				[System.Collections.Hashtable]
				$Parameters,
				
				[System.Collections.Hashtable]
				$Categories
			)
			
			$resolvedPath = $TestItem.Configuration.Path | Resolve-String @parameters
			
			$newParam = $Parameters.Clone()
			$newParam += @{
				Name = $TestItem.Configuration.Name | Resolve-String @parameters
				DNSHostName = $TestItem.Configuration.DNSHostName | Resolve-String @parameters
				Description = $TestItem.Configuration.Description | Resolve-String @parameters
			}
			if ($TestItem.Configuration.ServicePrincipalName) { $newParam.ServicePrincipalNames = $TestItem.Configuration.ServicePrincipalName | Resolve-String @parameters }
			if ($TestItem.Configuration.DisplayName) { $newParam.DisplayName = $TestItem.Configuration.DisplayName | Resolve-String @parameters }
			if ($TestItem.Configuration.Attributes) { $newParam.OtherAttributes = $TestItem.Configuration.Attributes | ConvertTo-PSFHashtable }
			
			#region Calculate desired principals
			$desiredPrincipals = @()
			
			foreach ($category in $TestItem.Configuration.ObjectCategory) {
				Get-ObjectCategoryContent -Categories $Categories -Name $category -Parameters $Parameters | ForEach-Object {
					$desiredPrincipals += $_
				}
			}
			
			# Direct Assignment
			foreach ($name in $TestItem.Configuration.ComputerName) {
				if ($name -notlike '*$') { $name = "$($name)$" }
				try {
					$null = Get-ADComputer -Identity $name -ErrorAction Stop
					$desiredPrincipals += $name
				}
				catch {
					Write-PSFMessage -Level Warning -String 'Invoke-DMServiceAccount.Computer.NotFound' -StringValues $name, $resolvedName -Target $TestItem.Configuration -Tag error, failed, serviceaccount, computer
					continue
				}
			}
			
			# Optional Direct Assignment
			foreach ($name in $TestItem.Configuration.ComputerNameOptional) {
				if ($name -notlike '*$') { $name = "$($name)$" }
				try {
					$null = Get-ADComputer -Identity $name -ErrorAction Stop
					$desiredPrincipals += $name
				}
				catch {
					Write-PSFMessage -Level Verbose -String 'Invoke-DMServiceAccount.Computer.Optional.NotFound' -StringValues $name, $resolvedName -Target $TestItem.Configuration -Tag error, failed, serviceaccount, computer
					continue
				}
			}
			if ($desiredPrincipals) {
				$newParam.PrincipalsAllowedToRetrieveManagedPassword = $desiredPrincipals
			}
			#endregion Calculate desired principals
			
			New-ADServiceAccount @newParam -ErrorAction Stop -Confirm:$false -Path $resolvedPath
		}
		
		function Set-ServiceAccount {
			[CmdletBinding()]
			param (
				$TestItem,
				
				[System.Collections.Hashtable]
				$Parameters
			)
			
			$setParam = $Parameters.Clone()
			$properties = @{ }
			$clear = @()
			foreach ($change in $testItem.Changed) {
				if (-not $change.NewValue -and 0 -ne $change.NewValue) { $clear += $change.Property }
				else { $properties[$change.Property] = $change.NewValue }
			}
			if ($properties.Count -gt 0) { $setParam.Replace = $properties }
			if ($clear) { $setParam.Clear = $clear }
			
			Set-ADServiceAccount @setParam -Identity $testItem.ADObject.ObjectGuid -Confirm:$false -ErrorAction Stop
		}
		#endregion Utility Functions
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type ServiceAccounts -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
		
		$categories = @{ }
	}
	process {
		if (-not $InputObject) {
			$InputObject = Test-DMServiceAccount @parameters
		}
		
		:main foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.ServiceAccount.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMServiceAccount', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				'Delete'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.Deleting' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						Remove-ADServiceAccount @parameters -Identity $testItem.ADObject.SamAccountName -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Create'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.Creating' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						New-ServiceAccount -TestItem $testItem -Parameters $parameters -Categories $categories
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Update'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.Updating' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						Set-ServiceAccount -TestItem $testItem -Parameters $parameters
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'PrincipalUpdate'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.UpdatingPrincipal' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						$principals = ($testItem.Changed | Where-Object Type -EQ Update).NewValue
						Set-ADServiceAccount @parameters -Identity $testItem.ADObject.ObjectGuid -PrincipalsAllowedToRetrieveManagedPassword $principals
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Move'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.Moving' -ActionStringValues $testItem.Identity, $testItem.Changed.NewValue -Target $testItem.Identity -ScriptBlock {
						Move-ADObject @parameters -Identity $testItem.ADObject.ObjectGuid -TargetPath $testItem.Changed.NewValue -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Rename'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.Moving' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						Rename-ADObject @parameters -Identity $testItem.ADObject.ObjectGuid -NewName $testItem.Changed.NewValue -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Enable'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.Enabling' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						Enable-ADAccount @parameters -Identity $testItem.ADObject.ObjectGuid -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Disable'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMServiceAccount.Disabling' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						Disable-ADAccount @parameters -Identity $testItem.ADObject.ObjectGuid -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
			}
		}
	}
}
