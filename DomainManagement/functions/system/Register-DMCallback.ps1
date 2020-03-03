function Register-DMCallback
{
	<#
	.SYNOPSIS
		Registers a scriptblock to be called when invoking any Test- or Invoke- command.
	
	.DESCRIPTION
		Registers a scriptblock to be called when invoking any Test- or Invoke- command.
		This enables extending the module and ensuring correct configuration loading.
		The scriptblock will receive four arguments:
		- The Server targeted (if any)
		- The credentials used to do the targeting (if any)
		- The Forest the two earlier pieces of information map to (if any)
		- The Domain the two earlier pieces of information map to (if any)
		Any and all of these pieces of information may be empty.
		Any exception in a callback scriptblock will block further execution!

		For more details on this system, call:
		Get-Help about_DM_callbacks
	
	.PARAMETER Name
		The name of the callback to register (multiple can be active at any given moment).
	
	.PARAMETER ScriptBlock
		The scriptblock containing the callback logic.
	
	.EXAMPLE
		PS C:\> Register-DMCallback -Name MyCompany -Scriptblock $scriptblock

		Registers the scriptblock stored in $scriptblock under the name 'MyCompany'
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ScriptBlock]
		$ScriptBlock
	)
	
	begin
	{
		if (-not $script:callbacks) {
			$script:callbacks = @{ }
		}
	}
	process
	{
		$script:callbacks[$Name] = [PSCustomObject]@{
			Name = $Name
			ScriptBlock = $ScriptBlock
		}
	}
}
