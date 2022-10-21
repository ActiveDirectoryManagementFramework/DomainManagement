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
				
				New-TestResult @resultDefaults -Type Delete -ADObject $adObject
				continue
			}
			#endregion Password Policy that needs to be removed

			#region Password Policies that don't exist but should : $adObject
			try { $adObject = Get-ADFineGrainedPasswordPolicy @parameters -Identity $resolvedName -Properties Description, DisplayName -ErrorAction Stop }
			catch
			{
				New-TestResult @resultDefaults -Type Create
				continue main
			}
			#endregion Password Policies that don't exist but should : $adObject

			[System.Collections.ArrayList]$changes = @()
			$compare = @{
				Configuration = $psoDefinition
				ADObject = $adObject
				Changes = $changes
				Type = 'PSO'
				AsUpdate = $true
			}
			Compare-Property @compare -Property ComplexityEnabled
			Compare-Property @compare -Property Description -Resolve
			Compare-Property @compare -Property DisplayName -Resolve
			Compare-Property @compare -Property LockoutDuration -Resolve
			Compare-Property @compare -Property LockoutObservationWindow
			Compare-Property @compare -Property LockoutThreshold
			Compare-Property @compare -Property MaxPasswordAge
			Compare-Property @compare -Property MinPasswordAge
			Compare-Property @compare -Property MinPasswordLength
			Compare-Property @compare -Property PasswordHistoryCount
			Compare-Property @compare -Property Precedence
			Compare-Property @compare -Property ReversibleEncryptionEnabled
			$groupObjects = foreach ($groupName in $psoDefinition.SubjectGroup) {
				try { Get-ADGroup @parameters -Identity (Resolve-String -Text $groupName) }
				catch { Write-PSFMessage -Level Warning -String 'Test-DMPasswordPolicy.SubjectGroup.NotFound' -StringValues $groupName, $resolvedName }
			}
			if (-not $groupObjects -or -not $adObject.AppliesTo -or (Compare-Object $groupObjects.DistinguishedName $adObject.AppliesTo)) {
				$null = $changes.Add((New-Change -Property 'SubjectGroup' -OldValue $adObject.AppliesTo -NewValue $groupObjects -Identity $adObject.DistinguishedName -Type PSO))
			}

			if ($changes.Count) {
				New-TestResult @resultDefaults -Type Update -Changed $changes.ToArray() -ADObject $adObject
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
			New-TestResult @resultDefaults -Type Delete -ADObject $passwordPolicy -Identity $passwordPolicy.Name
		}
	}
}
