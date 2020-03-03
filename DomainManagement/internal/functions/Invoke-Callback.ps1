function Invoke-Callback
{
	<#
	.SYNOPSIS
		Invokes registered callbacks.
	
	.DESCRIPTION
		Invokes registered callbacks.
		Should be placed inside the begin block of every single Test-* and Invoke-* command.

		For more details on this system, call:
		Get-Help about_DM_callbacks
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command
	
	.EXAMPLE
		PS C:\> Invoke-Callback @parameters -Cmdlet $PSCmdlet

		Executes all callbacks against the specified server using the specified credentials.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding()]
	Param (
		[string]
		$Server,

		[PSCredential]
		$Credential,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet
	)
	
	begin
	{
		if (-not $script:callbacks) { return }

		if (-not $script:callbackDomains) { $script:callbackDomains = @{ } }
		if (-not $script:callbackForests) { $script:callbackForests = @{ } }

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false

		$serverName = '<Default Domain>'
		if ($Server) { $serverName = $Server }
	}
	process
	{
		if (-not $script:callbacks) { return }

		if (-not $script:callbackDomains[$serverName]) {
			try { $script:callbackDomains[$serverName] = Get-ADDomain @parameters -ErrorAction Stop }
			catch { } # Ignore errors, might not work yet
		}
		if (-not $script:callbackForests[$serverName]) {
			try { $script:callbackForests[$serverName] = Get-ADForest @parameters -ErrorAction Stop }
			catch { } # Ignore errors, might not work yet
		}

		foreach ($callback in $script:callbacks.Values) {
			Write-PSFMessage -Level Debug -String 'Invoke-Callback.Invoking' -StringValues $callback.Name
			try {
				$param = @($serverName, $Credential, $script:callbackDomains[$serverName], $script:callbackForests[$serverName])
				$callback.Scriptblock.Invoke($param)
				Write-PSFMessage -Level Debug -String 'Invoke-Callback.Invoking.Success' -StringValues $callback.Name
			}
			catch {
				Write-PSFMessage -Level Debug -String 'Invoke-Callback.Invoking.Failed' -StringValues $callback.Name -ErrorRecord $_
				$Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
