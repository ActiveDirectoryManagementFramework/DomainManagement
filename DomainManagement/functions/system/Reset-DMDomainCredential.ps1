function Reset-DMDomainCredential
{
<#
	.SYNOPSIS
		Resets cached credentials for contacting domains.
	
	.DESCRIPTION
		Resets cached credentials for contacting domains.
		Use this command when invalidating credentials you used.
		For example in ADMF the credential provider:
		If you create one that uses a temporary account, then delete it when done, you need to reset the cache when connecting with your default credentials.
	
	.PARAMETER Credential
		Clear all cache entries using this credential object.
	
	.PARAMETER Domain
		Clear the cached credentials for the target domain.
	
	.PARAMETER UserName
		Clear all cached credentials using this username.
	
	.PARAMETER All
		Clear ALL cached credentials
	
	.EXAMPLE
		PS C:\> Reset-DMDomainCredential -All
	
		Clear all cached credentials
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
		[PSCredential]
		$Credential,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Domain')]
		[string]
		$Domain,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$UserName,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'All')]
		[switch]
		$All
	)
	
	process
	{
		switch ($PSCmdlet.ParameterSetName)
		{
			'Credential'
			{
				[string[]]$keys = $script:domainCredentialCache.Keys
				foreach ($key in $keys)
				{
					if ($script:domainCredentialCache[$key] -eq $Credential) { $script:domainCredentialCache.Remove($key) }
				}
			}
			'Domain'
			{
				$script:domainCredentialCache.Remove($Domain)
			}
			'Name'
			{
				[string[]]$keys = $script:domainCredentialCache.Keys
				foreach ($key in $keys)
				{
					if ($script:domainCredentialCache[$key].UserName -eq $UserName) { $script:domainCredentialCache.Remove($key) }
				}
			}
			'All'
			{
				$script:domainCredentialCache = @{ }
			}
		}
	}
}