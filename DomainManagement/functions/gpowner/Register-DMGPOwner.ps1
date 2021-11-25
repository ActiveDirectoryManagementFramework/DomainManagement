function Register-DMGPOwner {
	<#
	.SYNOPSIS
		Define the desired state for group policy ownership.
	
	.DESCRIPTION
		Define the desired state for group policy ownership.
		Afterwards use Test-DMGPOwner to determine, whether reality matches desire.
		Or Invoke-DMGPOwner to bring reality into the desired state.

		You can define ownership in three ways:
		- Explicitly to a specific group policy object
		- By filter, using the same filter syntax as used for GP Permissions
		- Global, a default setting for when the other two do not apply

		In Case multiple rules apply to a GPO, this precedence will be adhered to:
		Explicit > Filter > Global
		In case multiple filters apply, the one with the lowest Weight value applies.
	
	.PARAMETER GpoName
		The name of the GPO this rule applies to.
		This parameter uses name resolution.
	
	.PARAMETER Filter
		The filter by which to determine which GPO this rule applies to.
		Examples:
		- "IsManaged -and Tier0"
		- "-not (IsManaged) -or (Tier1 -and UserScope)"
		Each condition (e.g. "IsManaged" or "Tier0") needs to be defined as a condition separately.

		Conditions are documented here:
		- https://admf.one/documentation/components/domain/gppermissionfilters.html
		Examples on how to use them can be found in the "Filter" parameter description here:
		- https://admf.one/documentation/components/domain/gppermissions.html
	
	.PARAMETER Weight
		The precedence order when multiple filter conditions apply.
		The lower the number, the higher the priority.
	
	.PARAMETER All
		Define a global default rule.
		There can always only be one global default value.
	
	.PARAMETER Identity
		The identity that should be the owner of the affected GPO(s).
		Can be a sid or an NT identity reference.
		This parameter supports name resolution.
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\gpoowners.json | ConvertFrom-Json | Write-Output | Register-DMGPOwner

		Reads all settings from the provided json file and registers them.
	
	.NOTES
	General notes
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Explicit')]
		[string]
		$GpoName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[PsfValidateScript('DomainManagement.Validate.GPPermissionFilter', ErrorString = 'DomainManagement.Validate.GPPermissionFilter')]
		[string]
		$Filter,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[int]
		$Weight = 50,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[switch]
		$All,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Explicit')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[PsfValidateScript('DomainManagement.Validate.Identity', ErrorString = 'DomainManagement.Validate.Identity')]
		[string]
		$Identity,

		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Explicit' {
				$permIdentity = 'Explicit|{0}' -f $GpoName

				$script:groupPolicyOwners[$permIdentity] = [PSCustomObject]@{
					PSTypeName    = 'DomainManagement.Configuration.GPOwner'
					EntryIdentity = $permIdentity
					Type          = $PSCmdlet.ParameterSetName
					GpoName       = $GpoName
					Identity      = $Identity
					ContextName   = $ContextName
				}
			}
			'Filter' {
				$permIdentity = 'Filter|{0}' -f $Filter

				$script:groupPolicyOwners[$permIdentity] = [PSCustomObject]@{
					PSTypeName       = 'DomainManagement.Configuration.GPOwner'
					EntryIdentity    = $permIdentity
					Type             = $PSCmdlet.ParameterSetName
					Filter           = $Filter
					FilterConditions = ConvertTo-FilterName -Filter $Filter
					Weight           = $Weight
					Identity         = $Identity
					ContextName      = $ContextName
				}
			}
			'All' {
				$script:groupPolicyOwners['All'] = [PSCustomObject]@{
					PSTypeName    = 'DomainManagement.Configuration.GPOwner'
					EntryIdentity = 'All'
					Type          = $PSCmdlet.ParameterSetName
					All           = $true
					Identity      = $Identity
					ContextName   = $ContextName
				}
			}
		}
	}
}