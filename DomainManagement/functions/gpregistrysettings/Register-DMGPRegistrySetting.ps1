function Register-DMGPRegistrySetting {
	<#
	.SYNOPSIS
		Register a registry setting that should be applied to a group policy object.
	
	.DESCRIPTION
		Register a registry setting that should be applied to a group policy object.
		Note: These settings are only applied to group policy objects deployed through the GroupPolicy Component
	
	.PARAMETER PolicyName
		Name of the group policy object to attach this setting to.
		Subject to string insertion.
	
	.PARAMETER Key
		The registry key affected.
		Subject to string insertion.
	
	.PARAMETER ValueName
		The name of the value to modify.
	
	.PARAMETER Value
		The value to insert into the specified registry-key-value.
	
	.PARAMETER DomainData
		Instead of offering an explicit value, have the resulting value calculated by a scriptblock executed against the target domain.
		In opposite to ADMF Contexts, DomainData data gathering scriptblocks are executed on a per-domain basis.
		While a Context supports integrating logic, Contexts themselves are not re-run when switching to another domain with the same Context choice.
		DomainData gathering logic can be configured using Register-DMDomainData or defining appropriate configuration in ADMF Contexts.
	
	.PARAMETER Type
		What kind of registry value should be defined?
		Supported types: 'Binary', 'DWord', 'ExpandString', 'MultiString', 'QWord', 'String'
	
	.EXAMPLE
		PS C:\> Get-Content .\registrysettings.json | ConvertFrom-Json | Write-Output | Register-DMGPRegistrySetting

		Imports all the registry value definitions configured in the specified file.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Value')]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$PolicyName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Key,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ValueName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Value')]
		$Value,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DomainData')]
		[string]
		$DomainData,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'QWord', 'String')]
		[string]
		$Type
	)
	
	process {
		$identity = $PolicyName, $Key, $ValueName -join "þ"
		$data = @{
			PSTypeName = 'DomainManagement.Configuration.GPRegistrySetting'
			Identity   = $identity
			PolicyName = $PolicyName
			Key        = $Key
			ValueName  = $ValueName
			Type       = $Type
		}
		switch ($PSCmdlet.ParameterSetName) {
			'Value' { $data['Value'] = $Value }
			'DomainData' { $data['DomainData'] = $DomainData }
		}
		$script:groupPolicyRegistrySettings[$identity] = [PSCustomObject]$data
	}
}
