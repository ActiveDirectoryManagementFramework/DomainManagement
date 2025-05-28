function Register-DMGPLink {
	<#
	.SYNOPSIS
		Registers a group policy link as a desired state.
	
	.DESCRIPTION
		Registers a group policy link as a desired state.
	
	.PARAMETER PolicyName
		The name of the group policy being linked.
		Supports string expansion.
	
	.PARAMETER OrganizationalUnit
		The organizational unit (or domain root) being linked to.
		Supports string expansion.

	.PARAMETER OUFilter
		A filter string for an organizational unit.
		The filter must be a wildcard-pattern supporting distinguishedname.
	
	.PARAMETER Precedence
		Numeric value representing the order it is linked in.
		The lower the number, the higher on the list, the more relevant the setting.

	.PARAMETER Tier
		The tier of a link is a priority ordering on top of Precedence.
		While precedence determines order within a given tier, each tier is processed separately.
		The higher the tier number, the higher the priority.
		In additive mode, already existing linked policies have a Tier 0 priority.
		If you want your own policies to be prepended, use Tier 1 or higher.
		If you want your own policies to have the least priority however, user Tier -1 or lower.
		Default: 1

	.PARAMETER State
		The state the link should be in.
		Supported states:
		+ Enabled: Link should be enabled
		+ Disabled: Link should be disabled
		+ Enforced: Link is being enforced
		+ Undefined: The current state of the link is ignored
		Defaults to: Enabled

	.PARAMETER ProcessingMode
		In which way GPO links are being processed:
		- Additive: Add provided links, but do not modify the existing ones.
		- Constrained: Replace existing links that are undesired
		By default, constrained mode is being used.
		If any single link for a given Organizational Unit is in constrained mode, the entire OU is processed under constraind mode.

	.PARAMETER Present
		Whether the link should be present at all.
		Relevant in additive mode, to retain the capability to delete undesired links.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content $configPath | ConvertFrom-Json | Write-Output | Register-DMGPLink

		Import all GPLinks stored in the json file located at $configPath.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$PolicyName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Path')]
		[Alias('OU')]
		[string]
		$OrganizationalUnit,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Filter')]
		[string]
		$OUFilter,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[int]
		$Precedence,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[int]
		$Tier = 1,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Enabled', 'Disabled', 'Enforced', 'Undefined')]
		[string]
		$State = 'Enabled',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Constrained', 'Additive')]
		[string]
		$ProcessingMode = 'Constrained',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Present = $true,
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Path' {
				if (-not $script:groupPolicyLinks[$OrganizationalUnit]) {
					$script:groupPolicyLinks[$OrganizationalUnit] = @{ }
				}
				$script:groupPolicyLinks[$OrganizationalUnit][$PolicyName] = [PSCustomObject]@{
					PSTypeName         = 'DomainManagement.GPLink'
					PolicyName         = $PolicyName
					OrganizationalUnit = $OrganizationalUnit
					Precedence         = $Precedence
					Tier               = $Tier
					State              = $State
					ProcessingMode     = $ProcessingMode
					Present            = $Present
					ContextName        = $ContextName
				}
			}
			'Filter' {
				if (-not $script:groupPolicyLinksDynamic[$OUFilter]) {
					$script:groupPolicyLinksDynamic[$OUFilter] = @{ }
				}
				$script:groupPolicyLinksDynamic[$OUFilter][$PolicyName] = [PSCustomObject]@{
					PSTypeName     = 'DomainManagement.GPLink'
					PolicyName     = $PolicyName
					OUFilter       = $OUFilter
					Precedence     = $Precedence
					Tier           = $Tier
					State          = $State
					ProcessingMode = $ProcessingMode
					Present        = $Present
					ContextName    = $ContextName
				}
			}
		}
	}
}