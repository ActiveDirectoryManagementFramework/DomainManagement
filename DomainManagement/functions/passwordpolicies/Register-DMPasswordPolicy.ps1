function Register-DMPasswordPolicy
{
	<#
	.SYNOPSIS
		Register a new Finegrained Password Policy as the desired state.
	
	.DESCRIPTION
		Register a new Finegrained Password Policy as the desired state.
		These policies are then compared to the current state in a domain.
	
	.PARAMETER Name
		The name of the PSO.
	
	.PARAMETER DisplayName
		The display name of the PSO.
	
	.PARAMETER Description
		The description for the PSO.
	
	.PARAMETER Precedence
		The precedence rating of the PSO.
		The lower the precedence number, the higher the priority.
	
	.PARAMETER MinPasswordLength
		The minimum number of characters a password must have.
	
	.PARAMETER SubjectGroup
		The group that the PSO should be assigned to.
	
	.PARAMETER LockoutThreshold
		How many bad password entries will lead to account lockout?
	
	.PARAMETER MaxPasswordAge
		The maximum age a password may have before it must be changed.
	
	.PARAMETER ComplexityEnabled
		Whether complexity rules are applied to users affected by this policy.
		By default, complexity rules requires 3 out of: "Lowercase letter", "Uppercase letter", "number", "special character".
		However, custom password filters may lead to very validation rules.
	
	.PARAMETER LockoutDuration
		If the account is being locked out, how long will the lockout last.
	
	.PARAMETER LockoutObservationWindow
		What is the time window before the bad password count is being reset.
	
	.PARAMETER MinPasswordAge
		How soon may a password be changed again after updating the password.
	
	.PARAMETER PasswordHistoryCount
		How many passwords are kept in memory to prevent going back to a previous password.
	
	.PARAMETER ReversibleEncryptionEnabled
		Whether the password should be stored in a manner that allows it to be decrypted into cleartext.
		By default, only un-reversible hashes are being stored.
	
	.PARAMETER SubjectDomain
		The domain the group is part of.
		Defaults to the target domain.
	
	.PARAMETER Present
		Whether the PSO should exist.
		Defaults to $true.
		If this is set to $false, no PSO will be created, instead the PSO will be removed if it exists.
	
	.EXAMPLE
		PS C:\> Get-Content $configPath | ConvertFrom-Json | Write-Output | Register-DMPasswordPolicy

		Imports all the configured policies from the defined config json file.
	#>
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$DisplayName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[int]
		$Precedence,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[int]
		$MinPasswordLength,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$SubjectGroup,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[int]
		$LockoutThreshold,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PSFTimespan]
		$MaxPasswordAge,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$ComplexityEnabled = $true,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[PSFTimespan]
		$LockoutDuration = '1h',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[PSFTimespan]
		$LockoutObservationWindow = '1h',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[PSFTimespan]
		$MinPasswordAge = '30m',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[int]
		$PasswordHistoryCount = 24,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$ReversibleEncryptionEnabled = $false,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$SubjectDomain = '%DomainFqdn%',

		[bool]
		$Present = $true
	)
	
	process
	{
		$script:passwordPolicies[$Name] = [PSCustomObject]@{
			PSTypeName = 'DomainManagement.PasswordPolicy'
			Name = $Name
			Precedence = $Precedence
			ComplexityEnabled = $ComplexityEnabled
			LockoutDuration = $LockoutDuration.Value
			LockoutObservationWindow = $LockoutObservationWindow.Value
			LockoutThreshold = $LockoutThreshold
			MaxPasswordAge = $MaxPasswordAge.Value
			MinPasswordAge = $MinPasswordAge.Value
			MinPasswordLength = $MinPasswordLength
			DisplayName = $DisplayName
			Description = $Description
			PasswordHistoryCount = $PasswordHistoryCount
			ReversibleEncryptionEnabled = $ReversibleEncryptionEnabled
			SubjectDomain = $SubjectDomain
			SubjectGroup = $SubjectGroup
			Present = $Present
		}
	}
}
