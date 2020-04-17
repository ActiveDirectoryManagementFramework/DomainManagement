function Register-DMDomainData {
	<#
	.SYNOPSIS
		Registers a domain data gathering script.
	
	.DESCRIPTION
		Registers a domain data gathering script.
		These can be used to provide domain specific data (in contrast to the usual context specific data, which might be applied to multiple domains).
	
	.PARAMETER Name
		Name under which to register the data gathering script.
		Can only contain letters, numbers and underscores.
	
	.PARAMETER Scriptblock
		The scriptblock performing the actual gathering.
		Receives a hashtable containing Server and - possibly - Credentials.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Import-PowerShellDataFile .\config.psd1 | ForEach-Object { Register-DMDomainData @_ }

		Registers all configuration settings stored in config.psd1
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidatePattern('^[\d\w_]+$', ErrorString = 'DomainManagement.Validate.DomainData.Pattern')]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[scriptblock]
		$Scriptblock,

		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		$script:domainDataScripts[$Name] = [PSCustomObject]@{
			Name        = $Name
			Placeholder = '%!{0}%' -f $Name
			Scriptblock = $Scriptblock
			ContextName = $ContextName
		}
	}
}
