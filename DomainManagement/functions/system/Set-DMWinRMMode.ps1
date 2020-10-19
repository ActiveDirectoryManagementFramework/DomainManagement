function Set-DMWinRMMode {
	<#
	.SYNOPSIS
		Configures the way the module handles WinRM when gathering default object permissions from schema.

	.DESCRIPTION
		Configures the way the module handles WinRM when gathering default object permissions from schema.
		Depending on the desired domain configuration, dealing with undesired objects may be desirable.

		This module handles the following configurations:
		Mode:
			- Default: WinRM is used in full session mode. Connects to the DC. This requires domain admin permission.
			- JEA: WinRM will use Just-Enough-Administration, this must be configured on the target DC or a different JEA target.
			- noWinRM: WinRM is not used. This implies that the command is run directly on the domain controller.

		When specifying JEA Server name, specify the full DN, inserting '%DomainDN%' (without the quotes) for the domain root.

	.PARAMETER Mode
		The mode to operate under.
			- Default: WinRM is used in full session mode. Connects to the DC. This requires domain admin permission.
			- JEA: WinRM will use Just-Enough-Administration, this must be configured on the target DC or a different JEA target.
			- noWinRM: WinRM is not used. This implies that the command is run directly on the domain controller.

	.PARAMETER JEAConfigurationName
		Required when WinRMMode is set to JEA.
		Defines the JEA endpoint name.
		This name must be configured on the target server.

	.PARAMETER JEAEndpointServer
		When defined, module will connect to this server instead of domain controller.
		Specify the full DN, inserting '%DomainDN%' (without the quotes) for the domain root.

	.EXAMPLE
		PS C:\> Set-DMWinRMMode -Mode 'Default'

		Enables Default mode and connects to the DC in full session.

	.EXAMPLE
		PS C:\> Set-DMWinRMMode -Mode 'JEA' -JEAConfigurationName 'JEA_DMJEAModule' -JEAEndpointServer 'JEAServer.%DomainDN%'

		Enables JEA mode and connects to dedicated JEA endpoint server.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[ValidateSet('Default', 'JEA', 'NoWinRM')]
		[string]
		$Mode,

		[string]
		$JEAConfigurationName,

		[string]
		$JEAEndpointServer
	)
	begin {
		if ($Mode -eq 'JEA' -and -not $JEAConfigurationName){
			Stop-PSFFunction -String 'Set-DMWinRMMode.JEAConfiguration.Missing' -EnableException $true -Cmdlet $PSCmdlet -Category InvalidArgument
		}
	}

	process {
		if ($Mode) { $script:WinRMMode.Mode = $Mode }
		if (Test-PSFParameterBinding -ParameterName JEAConfigurationName) { $script:WinRMMode.JEAConfigurationName = $JEAConfigurationName }
		if (Test-PSFParameterBinding -ParameterName JEAEndpointServer) { $script:WinRMMode.JEAEndpointServer = $JEAEndpointServer }
	}
}