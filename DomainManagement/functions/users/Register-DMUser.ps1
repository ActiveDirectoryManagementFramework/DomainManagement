function Register-DMUser {
	<#
	.SYNOPSIS
		Registers a user definition into the configuration domains are compared to.
	
	.DESCRIPTION
		Registers a user definition into the configuration domains are compared to.
		This configuration is then compared to the configuration in AD when using Test-ADUser.

		Note: Many properties can be set up for string replacement at runtime.
		For example to insert the domain DN into the path, insert "%DomainDN%" (without the quotes) where the domain DN would be placed.
		Use Register-DMNameMapping to add additional values and the placeholder they will be inserted into.
		Use Get-DMNameMapping to retrieve a list of available mappings.
		This can be used to use the same content configuration across multiple environments, accounting for local naming differences.
	
	.PARAMETER SamAccountName
		SamAccountName of the user to manage.
		Subject to string insertion.
	
	.PARAMETER GivenName
		Given Name of the user to manage.
		Subject to string insertion.
	
	.PARAMETER Surname
		Surname (Family Name) of the user to manage.
		Subject to string insertion.
	
	.PARAMETER Description
		Description of the user account.
		This is required and should describe the purpose / use of the account.
		Subject to string insertion.
	
	.PARAMETER PasswordNeverExpires
		Whether the password should never expire.
		By default it WILL expire.
	
	.PARAMETER UserPrincipalName
		The user principal name the account should have.
		Subject to string insertion.
	
	.PARAMETER Path
		The organizational unit the user should be placed in.
		Subject to string insertion.

	.PARAMETER Enabled
		Whether the user object should be enabled or disabled.
		Defaults to: Undefined
	
	.PARAMETER OldNames
		Previous names the user object had.
		Will trigger a rename if a user is found under one of the old names but not the current one.
		Subject to string insertion.
	
	.PARAMETER Present
		Whether the user should be present.
		This can be used to trigger deletion of a managed account.
	
	.EXAMPLE
		PS C:\> Get-Content .\users.json | ConvertFrom-Json | Write-Output | Register-DMUser

		Reads a json configuration file containing a list of objects with appropriate properties to import them as user configuration.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$SamAccountName,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$GivenName,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Surname,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[switch]
		$PasswordNeverExpires,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$UserPrincipalName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[PSFramework.Utility.TypeTransformationAttribute([string])]
		[DomainManagement.TriBool]
		$Enabled = 'Undefined',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$OldNames = @(),

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Present = $true
	)

	process {

		$userHash = @{
			PSTypeName           = 'DomainManagement.User'
			SamAccountName       = $SamAccountName
			GivenName            = $GivenName
			Surname              = $Surname
			Description          = $null
			PasswordNeverExpires = $PasswordNeverExpires.ToBool()
			UserPrincipalName    = $UserPrincipalName
			Path                 = $Path
			Enabled              = $Enabled
			OldNames             = $OldNames
			Present              = $Present
		}
		if ($Description) {
			$userHash['Description'] = $Description
		}
		$script:users[$SamAccountName] = [PSCustomObject]$userHash
	}
}
