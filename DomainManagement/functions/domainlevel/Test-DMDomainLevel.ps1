function Test-DMDomainLevel
{
<#
	.SYNOPSIS
		Tests whether the target domain has at least the desired functional level.
	
	.DESCRIPTION
		Tests whether the target domain has at least the desired functional level.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-DMDomainLevel -Server contoso.com
	
		Tests whether the domain contoso.com has at least the desired functional level.
#>
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type DomainLevel -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		$levelValues = @{
			'2008R2' = 4
			'2012'   = 5
			'2012R2' = 6
			'2016'   = 7
		}
		$level = Get-DMDomainLevel
		$desiredLevel = $levelValues[$level.Level]
		$tempConfiguration = $level | ConvertTo-PSFHashtable
		$tempConfiguration['DesiredLevel'] = [Microsoft.ActiveDirectory.Management.ADDomainMode]$desiredLevel
		$domain = Get-ADDomain @parameters
		if ($domain.DomainMode -lt $desiredLevel)
		{
			New-TestResult -ObjectType DomainLevel -Type Raise -Identity $domain -Server $Server -Configuration ([pscustomobject]$tempConfiguration) -ADObject $domain -Changed (
				New-AdcChange -Property DomainLevel -OldValue $domain.DomainMode -NewValue $tempConfiguration['DesiredLevel'] -Identity $domain -Type DomainLevel -ToString {
					{ '{0}: {1} -> {2}' -f $this.Identity, $this.Old, $this.New }
				}
			)
		}
	}
}