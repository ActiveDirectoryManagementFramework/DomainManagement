function Register-DMGPPermissionFilter {
	<#
	.SYNOPSIS
		Registers a GP Permission filter rule.
	
	.DESCRIPTION
		Registers a GP Permission filter rule.
		These rules are used to apply GP Permissions not on any one specific object but on any number of GPOs that match the defined rule.
		For example it is possible to define rules that match GPOs by name, that apply to all GPOs defined in configuration or to GPOs linked under a specific OU structure.
	
	.PARAMETER Name
		Name of the filter rule.
		Must only contain letters, numbers and underscore.
	
	.PARAMETER Reverse
		Reverses the result of the rule.
		This combined with another condition allows reversing the result.
		For example, combined with a Path condition, this would make the filter match any GPO NOT linked to that path.
	
	.PARAMETER Managed
		Matches GPOs that are defined by ADMF ($true) or not so ($false).
	
	.PARAMETER Path
		Matches GPOs that have been linked to the specified organizational unit (or potentially OUs beneath it).
		Subject to name insertion.
	
	.PARAMETER PathScope
		Defines how the path rule is applied:
		- Base:     Only the specified OU's linked GPOs are evaluated (default).
		- OneLevel: Only the OU's directly beneath the specified OU are evaluated for linked GPOs.
		- SubTree:  All OUs under the specified path are avaluated for linked GPOs.

	.PARAMETER PathOptional
		Whether the path is optional.
		By default, when evaluating a path filter, processing of GP permission terminates if the designated path does not exist, as we cannot guarantee a consistent permission-set being applied.
		With this setting enabled, instead processing silently continues.
		(Even if this is enabled, a silent log entry will be added  for tracking purposes!)
	
	.PARAMETER GPName
		Name of the GP to filter for.
		This can be a wildcard or regex match, depending on the -GPNameMode parameter, however by default an exact match is required.
		Subject to name insertion.
	
	.PARAMETER GPNameMode
		How exactly the GPName parameter is applied:
		- Explicit: An exact name equality is required (default)
		- Wildcard: Supports wildcard comparisons (using the -like operator)
		- Regex:    Supports regex matching (using the -match operator)
		None of the three options is case sensitive.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\gppermissionfilter.json | ConvertFrom-Json | Write-Output | Register-DMGPPermissionFilter

		Reads all registered filters from the input file and registers them for use in testing Group Policy Permissionss.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidatePattern('^[\w\d_]+$', ErrorString = 'DomainManagement.Validate.PermissionFilterName')]
		[string]
		$Name,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[switch]
		$Reverse,

		[Parameter(Mandatory = $true, ParameterSetName = 'Managed', ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Managed,

		[Parameter(Mandatory = $true, ParameterSetName = 'Path', ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[Parameter(ParameterSetName = 'Path', ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Base', 'OneLevel', 'SubTree')]
		[string]
		$PathScope = 'Base',

		[Parameter(ParameterSetName = 'Path', ValueFromPipelineByPropertyName = $true)]
		[switch]
		$PathOptional,

		[Parameter(Mandatory = $true, ParameterSetName = 'GPName', ValueFromPipelineByPropertyName = $true)]
		[string]
		$GPName,

		[Parameter(ParameterSetName = 'GPName', ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Explicit', 'Wildcard', 'Regex')]
		[string]
		$GPNameMode = 'Explicit',

		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Managed' {
				$script:groupPolicyPermissionFilters[$Name] = [PSCustomObject]@{
					PSTypeName  = 'DomainManagement.Configuration.GPPermissionFilter'
					Type        = 'Managed'
					Name        = $Name
					Reverse     = $Reverse
					Managed     = $Managed
					ContextName = $ContextName
				}
			}
			'Path' {
				$script:groupPolicyPermissionFilters[$Name] = [PSCustomObject]@{
					PSTypeName  = 'DomainManagement.Configuration.GPPermissionFilter'
					Type        = 'Path'
					Name        = $Name
					Reverse     = $Reverse
					Path        = $Path
					Optional    = $PathOptional
					Scope       = $PathScope
					ContextName = $ContextName
				}
			}
			'GPName' {
				$script:groupPolicyPermissionFilters[$Name] = [PSCustomObject]@{
					PSTypeName  = 'DomainManagement.Configuration.GPPermissionFilter'
					Type        = 'GPName'
					Name        = $Name
					Reverse     = $Reverse
					GPName      = $GPName
					Mode        = $GPNameMode
					ContextName = $ContextName
				}
			}
		}
	}
}