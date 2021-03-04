function Test-KdsRootKey
{
<#
	.SYNOPSIS
		Tests whether the KDS Root Key has been set up.
	
	.DESCRIPTION
		Tests whether the KDS Root Key has been set up.
		Prompts the user whether to set it up if not done yet.
		A valid KDS Root Key is required for using group Managed Service Accounts.
	
	.PARAMETER ComputerName
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-KdsRootKey -ComputerName contoso.com
	
		Tests whether the contoso.com domain has been set up for gMSA.
#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		[Alias('Server')]
		$ComputerName,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential
	}
	process
	{
		$rootKeys = Invoke-Command @parameters { Get-KdsRootKey }
		if ($rootKeys | Where-Object EffectiveTime -LT $limit) { return $true }
		
		$paramGetPSFUserChoice = @{
			Caption = 'No active KDS Root Key Detected'
			Message = 'Do you want to create a KDS Rootkey backdated to be instantly applicable?'
			Options = 'Yes', 'No'
			DefaultChoice = 1
		}
		$choice = Get-PSFUserChoice @paramGetPSFUserChoice
		if ($choice -eq 1) { return $false }
		
		try {
			Write-PSFMessage -Level Host -String 'Test-KdsRootKey.Adding'
			$null = Invoke-Command @parameters -ScriptBlock {
				Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10) -ErrorAction Stop
			} -ErrorAction Stop
			return $true
		}
		catch {
			Write-PSFMessage -Level Warning -String 'Test-KdsRootKey.Failed' -ErrorRecord $_
		}
		$false
	}
}