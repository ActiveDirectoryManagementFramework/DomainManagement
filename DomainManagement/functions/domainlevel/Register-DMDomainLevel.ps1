function Register-DMDomainLevel
{
<#
	.SYNOPSIS
		Register a domain functional level as desired state.
	
	.DESCRIPTION
		Register a domain functional level as desired state.
	
	.PARAMETER Level
		The level to apply.
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Register-DMDomainLevel -Level 2016
	
		Apply the desired domain level of 2016
#>
	[CmdletBinding()]
	param (
		[ValidateSet('2008R2', '2012', '2012R2', '2016')]
		[int]
		$Level,
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process
	{
		$script:domainLevel = [PSCustomObject]@{
			PSTypeName  = 'DomainManagement.Configuration.DomainLevel'
			Level	    = $Level
			ContextName = $ContextName
		}
	}
}