function Assert-ADConnection
{
	<#
	.SYNOPSIS
		Ensures connection to AD is possible before performing actions.
	
	.DESCRIPTION
		Ensures connection to AD is possible before performing actions.
		Should be the first things all commands connecting to AD should call.
		Do this before invoking callbacks, as the configuration change becomes pointless if the forest is unavailable to begin with,
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
		Used to safely terminate the calling command in case of failure.
	
	.EXAMPLE
		PS C:\> Assert-ADConnection @parameters -Cmdlet $PSCmdlet

		Kills the calling command if AD is not available.
	#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process
	{
		# A domain being unable to retrieve its own object can really only happen if the service is down
		try { $null = Get-ADDomain @parameters -ErrorAction Stop }
		catch {
			Write-PSFMessage -Level Warning -String 'Assert-ADConnection.Failed' -StringValues $Server -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
		}
	}
}
