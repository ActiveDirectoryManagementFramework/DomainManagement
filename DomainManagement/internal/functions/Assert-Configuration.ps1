﻿function Assert-Configuration
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
		[string[]]
		$Type,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet
	)
	
	process
	{
		foreach ($typeName in $type) {
			if ((Get-Variable -Name $typeName -Scope Script -ValueOnly -ErrorAction SilentlyContinue).Count -gt 0) { return }
		}
		
		Write-PSFMessage -Level Warning -String 'Assert-Configuration.NotConfigured' -StringValues ($Type -join ", ") -FunctionName $Cmdlet.CommandRuntime

		$exception = New-Object System.Data.DataException("No configuration data provided for: $($Type -join ", ")")
		$errorID = 'NotConfigured'
		$category = [System.Management.Automation.ErrorCategory]::NotSpecified
		$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, ($Type -join ", "))
		$cmdlet.ThrowTerminatingError($recordObject)
	}
}
