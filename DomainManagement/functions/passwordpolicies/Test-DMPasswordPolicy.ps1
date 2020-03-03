function Test-DMPasswordPolicy
{
	<#
	.SYNOPSIS
		Tests, whether the deployed PSOs match the desired PSOs.
	
	.DESCRIPTION
		Tests, whether the deployed PSOs match the desired PSOs.
		Use Register-DMPasswordPolicy to define the desired PSOs.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMPasswordPolicy -Server contoso.com

		Checks, whether the contoso.com domain's password policies match the desired state.
	#>
	
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type PasswordPolicies -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		:main foreach ($psoDefinition in $script:passwordPolicies.Values) {
			$resolvedName = Resolve-String -Text $psoDefinition.Name

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'PSO'
				Identity = $resolvedName
				Configuration = $psoDefinition
			}

			#region Password Policy that needs to be removed
			if (-not $psoDefinition.Present) {
				try { $adObject = Get-ADFineGrainedPasswordPolicy @parameters -Identity $resolvedName -Properties DisplayName, Description -ErrorAction Stop }
				catch { continue main } # Only errors when PSO not present = All is well
				
				New-TestResult @resultDefaults -Type ShouldDelete -ADObject $adObject
				continue
			}
			#endregion Password Policy that needs to be removed

			#region Password Policies that don't exist but should : $adObject
			try { $adObject = Get-ADFineGrainedPasswordPolicy @parameters -Identity $resolvedName -Properties Description, DisplayName -ErrorAction Stop }
			catch
			{
				New-TestResult @resultDefaults -Type ConfigurationOnly
				continue main
			}
			#endregion Password Policies that don't exist but should : $adObject

			[System.Collections.ArrayList]$changes = @()
			Compare-Property -Property ComplexityEnabled -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property Description -Configuration $psoDefinition -ADObject $adObject -Changes $changes -Resolve
			Compare-Property -Property DisplayName -Configuration $psoDefinition -ADObject $adObject -Changes $changes -Resolve
			Compare-Property -Property LockoutDuration -Configuration $psoDefinition -ADObject $adObject -Changes $changes -Resolve
			Compare-Property -Property LockoutObservationWindow -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property LockoutThreshold -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property MaxPasswordAge -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property MinPasswordAge -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property MinPasswordLength -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property PasswordHistoryCount -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property Precedence -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			Compare-Property -Property ReversibleEncryptionEnabled -Configuration $psoDefinition -ADObject $adObject -Changes $changes
			$groupObjects = foreach ($groupName in $psoDefinition.SubjectGroup) {
				try { Get-ADGroup @parameters -Identity (Resolve-String -Text $groupName) }
				catch { Write-PSFMessage -Level Warning -String 'Test-DMPasswordPolicy.SubjectGroup.NotFound' -StringValues $groupName, $resolvedName }
			}
			if (-not $groupObjects -or -not $ADObject.AppliesTo -or (Compare-Object $groupObjects.DistinguishedName $ADObject.AppliesTo)) {
				$null = $changes.Add('SubjectGroup')
			}

			if ($changes.Count) {
				New-TestResult @resultDefaults -Type Changed -Changed $changes.ToArray() -ADObject $adObject
			}
		}

		$passwordPolicies = Get-ADFineGrainedPasswordPolicy @parameters -Filter *
		$resolvedPolicies = $script:passwordPolicies.Values.Name | Resolve-String

		$resultDefaults = @{
			Server = $Server
			ObjectType = 'PSO'
		}

		foreach ($passwordPolicy in $passwordPolicies) {
			if ($passwordPolicy.Name -in $resolvedPolicies) { continue }
			New-TestResult @resultDefaults -Type ShouldDelete -ADObject $passwordPolicy -Identity $passwordPolicy.Name
		}
	}
}
