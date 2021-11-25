function Test-DMServiceAccount {
<#
	.SYNOPSIS
		Tests whether the currently deployed service accoaunts match the configured desired state.
	
	.DESCRIPTION
		Tests whether the currently deployed service accoaunts match the configured desired state.
		Use Register-DMServiceAccount to define the desired state.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMServiceAccount -Server contoso.com
	
		Tests whether the service accounts in the contoso.com domain are compliant with the desired state.
#>
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		#region Utility Functions
		function New-Change {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$Identity,
				
				$Type,
				
				$Property,
				
				$Previous,
				
				$NewValue
			)
			
			[pscustomobject]@{
				PSTypeName = 'DomainManagement.Change.ServiceAccount'
				Identity   = $Identity
				Type	   = $Type
				Property   = $Property
				Previous   = $Previous
				NewValue   = $NewValue
			}
		}
		#endregion Utility Functions
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type serviceAccounts -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		#region Prepare Object Categories
		$rawCategories = $script:serviceAccounts.Values.ObjectCategory | Remove-PSFNull -Enumerate | Sort-Object -Unique
		$categories = @{ }
		foreach ($rawCategory in $rawCategories) {
			$categories[$rawCategory] = Find-DMObjectCategoryItem -Name $rawCategory @parameters -Property SamAccountName
		}
		$renameCurrentSAM = @()
		#endregion Prepare Object Categories
		
		#region Process Configured Objects
		foreach ($serviceAccountDefinition in $script:serviceAccounts.Values) {
			$resolvedName = (Resolve-String -Text $serviceAccountDefinition.SamAccountName @parameters) -replace '\$$'
			$resolvedPath = Resolve-String -Text $serviceAccountDefinition.Path @parameters
			
			$resultDefaults = @{
				Server	      = $Server
				ObjectType    = 'ServiceAccount'
				Identity	  = $resolvedName
				Configuration = $serviceAccountDefinition
			}
			$adObject = $null
			
			try { $adObject = Get-ADServiceAccount @parameters -Identity $resolvedName -ErrorAction Stop -Properties * }
			catch {
                foreach ($oldName in $serviceAccountDefinition.OldNames) {
                    try { $adObject = Get-ADServiceAccount @parameters -Identity ($oldName | Resolve-String @parameters) -ErrorAction Stop -Properties * }
                    catch { continue }
                    # No Need to rename when deleting it anyway
                    if (-not $serviceAccountDefinition.Present) { break }
                    New-TestResult -Type RenameSam @resultDefaults -ADObject $adObject
					$renameCurrentSAM += $adObject.SamAccountName
                    break
                }
			}

            if (-not $adObject) {
                # .Present is of type TriBool, so itself would be $true for both 'true' and 'undefined' cases,
                # and we do not want to create if undefined
                if ($serviceAccountDefinition.Present -eq 'true') {
                    New-TestResult -Type Create @resultDefaults (New-Change -Identity $resolvedName -Type Create)
                }
				continue
            }
			$resultDefaults.ADObject = $adObject
			
			if (-not $serviceAccountDefinition.Present) {
				New-TestResult -Type Delete @resultDefaults -Changed (New-Change -Identity $adObject.SamAccountName -Type Delete)
				continue
			}
			
			#region Compare Common Properties
			$parentPath = $adObject.DistinguishedName -split ",", 2 | Select-Object -Last 1
			if ($parentPath -ne $resolvedPath) {
				New-TestResult -Type Move @resultDefaults -Changed (New-Change -Type Move -Property 'Path' -Previous $parentPath -NewValue $resolvedPath -Identity $resolvedName)
			}
			
			if ($adObject.Name -ne $resolvedName) {
				New-TestResult -Type Rename @resultDefaults -Changed (New-Change -Type Rename -Property 'Name' -Previous $adObject.Name -NewValue $resolvedName -Identity $resolvedName)
			}
			
			[System.Collections.ArrayList]$changes = @()
			Compare-Property -Property DNSHostName -Configuration $serviceAccountDefinition -ADObject $adObject -Changes $changes -Resolve -Parameters $parameters
			Compare-Property -Property Description -Configuration $serviceAccountDefinition -ADObject $adObject -Changes $changes -Resolve -Parameters $parameters -AsString
			Compare-Property -Property DisplayName -Configuration $serviceAccountDefinition -ADObject $adObject -Changes $changes -Resolve -Parameters $parameters -AsString
			if ($adObject.ServicePrincipalName -or $serviceAccountDefinition.ServicePrincipalName) {
				Compare-Property -Property ServicePrincipalName -Configuration $serviceAccountDefinition -ADObject $adObject -Changes $changes -Resolve -Parameters $parameters
			}
            if ($adObject.KerberosEncryptionType[0] -ne $serviceAccountDefinition.KerberosEncryptionType) {
                $null = $changes.Add('KerberosEncryptionType')
            }
            
			if ($serviceAccountDefinition.Attributes.Count -gt 0) {
				$attributesObject = [PSCustomObject]$serviceAccountDefinition.Attributes
				foreach ($key in $serviceAccountDefinition.Attributes.Keys) {
					Compare-Property -Property $key -Configuration $attributesObject -ADObject $adObject -Changes $changes
				}
			}
			$defaultProperties = 'DNSHostName', 'Description', 'ServicePrincipalName', 'DisplayName'
			$changeObjects = foreach ($change in $changes) {
				if ($change -in $defaultProperties) { New-Change -Type Update -Property $change -Previous $adObject.$change -NewValue ($serviceAccountDefinition.$change | Resolve-String @parameters) -Identity $resolvedName }
				else { New-Change -Type Update -Property $change -Previous $adObject.$change -NewValue $attributesObject.$change -Identity $resolvedName }
			}
			if ($changes) {
				New-TestResult -Type Update @resultDefaults -Changed $changeObjects
			}
			#endregion Compare Common Properties
			
			#region Enabled
			if ($serviceAccountDefinition.Enabled -ne 'Undefined') {
				if ($adObject.Enabled -and -not $serviceAccountDefinition.Enabled) {
					New-TestResult -Type Disable @resultDefaults -Changed (New-Change -Type Disable -Property Enabled -Previous $true -NewValue $false -Identity $resolvedName)
				}
				if (-not $adObject.Enabled -and $serviceAccountDefinition.Enabled) {
					New-TestResult -Type Enable @resultDefaults -Changed (New-Change -Type Enable -Property Enabled -Previous $false -NewValue $true -Identity $resolvedName)
				}
			}
			#endregion Enabled
			
			#region PrincipalsAllowedToRetrieveManagedPassword
			# Use SamAccountName rather than DistinguishedName as accounts may not yet have been moved to their correct container so DN might fail
			$currentPrincipals = ($adObject.PrincipalsAllowedToRetrieveManagedPassword | Get-ADObject @parameters -Properties SamAccountName).SamAccountName
			
			# Object Category
			$desiredPrincipals = @()
			foreach ($category in $serviceAccountDefinition.ObjectCategory) {
				$categories[$category].SamAccountName | ForEach-Object {
					$desiredPrincipals += $_
				}
			}
			
			# Direct Assignment
			foreach ($name in $serviceAccountDefinition.ComputerName | Resolve-String @parameters) {
				if ($name -notlike '*$') { $name = "$($name)$" }
				try {
					$null = Get-ADComputer @parameters -Identity $name -ErrorAction Stop
					$desiredPrincipals += $name
				}
				catch {
					Write-PSFMessage -Level Warning -String 'Test-DMServiceAccount.Computer.NotFound' -StringValues $name, $resolvedName -Target $serviceAccountDefinition -Tag error, failed, serviceaccount, computer
					continue
				}
			}
			
			# Optional Direct Assignment
			foreach ($name in $serviceAccountDefinition.ComputerNameOptional | Resolve-String @parameters) {
				if ($name -notlike '*$') { $name = "$($name)$" }
				try {
					$null = Get-ADComputer @parameters -Identity $name -ErrorAction Stop
					$desiredPrincipals += $name
				}
				catch {
					Write-PSFMessage -Level Verbose -String 'Test-DMServiceAccount.Computer.Optional.NotFound' -StringValues $name, $resolvedName -Target $serviceAccountDefinition -Tag error, failed, serviceaccount, computer
					continue
				}
			}
			
			# Direct Group Assignment
			foreach ($name in $serviceAccountDefinition.GroupName | Resolve-String @parameters) {
				try {
					$null = Get-ADGroup @parameters -Identity $name -ErrorAction Stop
					$desiredPrincipals += $name
				}
				catch {
					Write-PSFMessage -Level Warning -String 'Test-DMServiceAccount.Group.NotFound' -StringValues $name, $resolvedName -Target $serviceAccountDefinition -Tag error, failed, serviceaccount, group
					continue
				}
			}
			
			$principalChanges = @()
			foreach ($principal in $currentPrincipals) {
				if ($principal -in $desiredPrincipals) { continue }
				$principalChanges += New-Change -Type Remove -Property Principal -Previous $principal -Identity $resolvedName
			}
			foreach ($principal in $desiredPrincipals) {
				if ($principal -in $currentPrincipals) { continue }
				$principalChanges += New-Change -Type Add -Property Principal -NewValue $principal -Identity $resolvedName
			}
			if (-not $principalChanges) { continue }
			
			$principalChanges += New-Change -Type Update -Property Principal -Previous $currentPrincipals -NewValue $desiredPrincipals -Identity $resolvedName
			New-TestResult -Type PrincipalUpdate @resultDefaults -Changed $principalChanges
			#endregion PrincipalsAllowedToRetrieveManagedPassword
		}
		#endregion Process Configured Objects
		
		#region Process Non-Configuted AD-Objects
		$foundServiceAccounts = foreach ($searchBase in (Resolve-ContentSearchBase @parameters)) {
			Get-ADServiceAccount @parameters -LDAPFilter '(!(isCriticalSystemObject=TRUE))' -SearchBase $searchBase.SearchBase -SearchScope $searchBase.SearchScope
		}
		
		$configuredNames = $script:serviceAccounts.Values.SamAccountName | Resolve-String @parameters | ForEach-Object {
			if ($_ -like '*$') { $_ }
			else { "$($_)$" }
		}
		
		$resultDefaults = @{
			Server	   = $Server
			ObjectType = 'ServiceAccount'
		}
		
		foreach ($foundServiceAccount in $foundServiceAccounts) {
			if ($foundServiceAccount.SamAccountName -in $configuredNames) { continue }
			if ($foundServiceAccount.SamAccountName -in $renameCurrentSAM) { continue }
			
			New-TestResult @resultDefaults -Type Delete -Identity $foundServiceAccount.SamAccountName -ADObject $foundServiceAccount -Changed (New-Change -Identity $foundServiceAccount.SamAccountName -Type Delete)
		}
		#endregion Process Non-Configuted AD-Objects
	}
}
