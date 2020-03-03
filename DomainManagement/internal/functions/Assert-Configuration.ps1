function Assert-Configuration
{
	<#
	.SYNOPSIS
		Ensures a set of configuration settings has been provided for the specified setting type.
	
	.DESCRIPTION
		Ensures a set of configuration settings has been provided for the specified setting type.
		This maps to the configuration variables defined in variables.ps1
		Note: Not ALL variables defined in that file should be mapped, only those storing individual configuration settings!
	
	.PARAMETER Type
		The setting type to assert.

	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
		Used to safely terminate the calling command in case of failure.
	
	.EXAMPLE
		PS C:\> Assert-Configuration -Type Users

		Asserts, that users have already been specified.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Type,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet
	)
	
	process
	{
		if ((Get-Variable -Name $Type -Scope Script -ValueOnly).Count -gt 0) { return }
		
		Write-PSFMessage -Level Warning -String 'Assert-Configuration.NotConfigured' -StringValues $Type -FunctionName $Cmdlet.CommandRuntime

		$exception = New-Object System.Data.DataException("No configuration data provided for: $Type")
		$errorID = 'NotConfigured'
		$category = [System.Management.Automation.ErrorCategory]::NotSpecified
		$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Type)
		$cmdlet.ThrowTerminatingError($recordObject)
	}
}
