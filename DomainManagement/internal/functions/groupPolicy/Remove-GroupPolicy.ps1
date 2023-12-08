function Remove-GroupPolicy
{
	<#
	.SYNOPSIS
		Removes the specified group policy object.
	
	.DESCRIPTION
		Removes the specified group policy object.
	
	.PARAMETER Session
		PowerShell remoting session to the server on which to perform the operation.
	
	.PARAMETER ADObject
		AD object data retrieved when scanning the domain using Get-GroupPolicyEx.
	
	.EXAMPLE
		PS C:\> Remove-GroupPolicy -Session $session -ADObject $testItem.ADObject -ErrorAction Stop

		Removes the specified group policy object.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[System.Management.Automation.Runspaces.PSSession]
		$Session,

		[PSObject]
		$ADObject
	)
	
	process
	{
		Write-PSFMessage -Level Debug -String 'Remove-GroupPolicy.Deleting' -StringValues $ADObject.DisplayName -Target $ADobject
		try {
			Invoke-Command -Session $Session -ArgumentList $ADObject -ScriptBlock {
				param (
					$ADObject
				)
				$domainObject = Get-ADDomain -Server localhost

				Remove-GPO -Name $ADObject.DisplayName -ErrorAction Stop -Confirm:$false -Server $domainObject.PDCEmulator -Domain $domainObject.DNSRoot
			} -ErrorAction Stop
		}
		catch { Stop-PSFFunction -String 'Remove-GroupPolicy.Deleting.Failed' -StringValues $ADObject.DisplayName -ErrorRecord $_ -EnableException $true -Cmdlet $PSCmdlet }
	}
}
