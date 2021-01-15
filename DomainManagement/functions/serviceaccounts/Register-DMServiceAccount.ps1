function Register-DMServiceAccount {
<#
	.SYNOPSIS
		Register a Group Managed Service Account as a desired state object.
	
	.DESCRIPTION
		Register a Group Managed Service Account as a desired state object.
		This will then be tested for during Test-DMServiceAccount and ensured during Invoke-DMServiceAccount.
	
	.PARAMETER Name
		Name of the Service Account.
		This must be a legal name, 15 characters or less (no trailing $ needed).
		The SamAccountName will be automatically calculated based off this setting (by appending a $).
		Supports string resolution.
	
	.PARAMETER DNSHostName
		The DNSHostName of the gMSA.
		Supports string resolution.
	
	.PARAMETER Description
		Describe what the gMSA is supposed to be used for.
		Supports string resolution.
	
	.PARAMETER Path
		The path where to place the gMSA.
		Supports string resolution.
	
	.PARAMETER ServicePrincipalName
		Any service principal names to add to the gMSA.
		Supports string resolution.
	
	.PARAMETER DisplayName
		A custom DisplayName for the gMSA.
		Note, this setting will be ignored in the default dsa.msc console!
		It only affects other applications that might be gMSA aware and support it.
		Supports string resolution.
	
	.PARAMETER ObjectCategory
		Only thus designated principals are allowed to retrieve the password to the gMSA.
		Using this you can grant access to any members of given Object Categories.
	
	.PARAMETER ComputerName
		Only thus designated principals are allowed to retrieve the password to the gMSA.
		Using this you can grant access to an explicit list of computer accounts.
		A missing computer will cause a warning, but not otherwise fail the process.
		Supports string resolution.
	
	.PARAMETER ComputerNameOptional
		Only thus designated principals are allowed to retrieve the password to the gMSA.
		Using this you can grant access to an explicit list of computer accounts.
		A missing computer will be logged but not otherwise noted.
		Supports string resolution.
	
	.PARAMETER Enabled
		Whether the account should be enabled or disabled.
		By default, this is 'Undefined', causing the workflow to ignore its enablement state.
	
	.PARAMETER Present
		Whether the account should exist or not.
		By default, it should.
		Set this to $false in order to explicitly delete an existing gMSA.
	
	.PARAMETER Attributes
		Offer additional attributes to define.
		This can be either a hashtable or an object and can contain any writeable properties a gMSA can have in your organization.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\serviceaccounts.json | ConvertFrom-Json | Write-Output | Register-DMServiceAccount
	
		Load up all settings defined in serviceaccounts.json
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$DNSHostName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ServicePrincipalName = @(),
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$DisplayName,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ObjectCategory,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ComputerName,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ComputerNameOptional,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[PSFramework.Utility.TypeTransformationAttribute([string])]
		[DomainManagement.TriBool]
		$Enabled = 'Undefined',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Present = $true,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		$Attributes,
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		$script:serviceAccounts[$Name] = [PSCustomObject]@{
			PSTypeName		      = 'DomainManagement.Configuration.ServiceAccount'
			Name				  = $Name
			SamAccountName	      = $Name
			DNSHostName		      = $DNSHostName
			Description		      = $Description
			Path				  = $Path
			ServicePrincipalName  = $ServicePrincipalName
			DisplayName		      = $DisplayName
			ObjectCategory	      = $ObjectCategory
			ComputerName		  = $ComputerName
			ComputerNameOptional  = $ComputerNameOptional
			Enabled			      = $Enabled
			Present			      = $Present
			Attributes		      = $Attributes | ConvertTo-PSFHashtable
			ContextName		     = $ContextName
		}
	}
}