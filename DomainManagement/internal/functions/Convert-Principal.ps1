function Convert-Principal {
    <#
    .SYNOPSIS
        Converts a principal to either SID or NTAccount format.
    
    .DESCRIPTION
        Converts a principal to either SID or NTAccount format.
        It caches all resolutions, uses Convert-BuiltInToSID to resolve default builtin account names,
        uses Get-Domain to resolve foreign domain SIDs and names.

        Basically, it is a best effort attempt to resolve principals in a useful manner.
    
    .PARAMETER Name
        The name of the entity to convert.
    
    .PARAMETER OutputType
        Whether to return an NTAccount or SID.
        Defaults to SID
    
    .PARAMETER Server
        The server / domain to work with.
    
    .PARAMETER Credential
        The credentials to use for this operation.
    
    .EXAMPLE
        PS C:\> Convert-Principal @parameters -Name contoso\administrator

        Tries to convert the user contoso\administrator into a SID
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Name,

        [ValidateSet('SID','NTAccount')]
		[string]
		$OutputType = 'SID',

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
    )
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process {
		Write-PSFMessage -Level Debug -String 'Convert-Principal.Processing' -StringValues $Name
		
        # Terminate if already cached
        if ($OutputType -eq 'SID' -and $script:cache_PrincipalToSID[$Name]) { return $script:cache_PrincipalToSID[$Name] }
        if ($OutputType -eq 'NTAccount' -and $script:cache_PrincipalToNT[$Name]) { return $script:cache_PrincipalToNT[$Name] }

        $builtInIdentity = Convert-BuiltInToSID -Identity $Name
        if ($builtInIdentity -ne $Name) { return $builtInIdentity }

        #region Processing Input SID
		if ($Name -as [System.Security.Principal.SecurityIdentifier]) {
			Write-PSFMessage -Level Debug -String 'Convert-Principal.Processing.InputSID' -StringValues $Name
            if ($OutputType -eq 'SID') {
                $script:cache_PrincipalToSID[$Name] = $Name -as [System.Security.Principal.SecurityIdentifier]
                return $script:cache_PrincipalToSID[$Name]
            }

            $script:cache_PrincipalToNT[$Name] = Get-Principal @parameters -Sid $Name -Domain $Name -OutputType NTAccount
            return $script:cache_PrincipalToNT[$Name]
        }
        #endregion Processing Input SID
		
		Write-PSFMessage -Level Debug -String 'Convert-Principal.Processing.InputNT' -StringValues $Name
        $ntAccount = $Name -as [System.Security.Principal.NTAccount]
        if ($OutputType -eq 'NTAccount') {
            $script:cache_PrincipalToNT[$Name] = $ntAccount
            return $script:cache_PrincipalToNT[$Name]
        }

        try {
            $script:cache_PrincipalToSID[$Name] = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
            return $script:cache_PrincipalToSID[$Name]
        }
        catch {
            $domainPart, $namePart = $ntAccount.Value.Split("\", 2)
			$domain = Get-Domain @parameters -DnsName $domainPart
			Write-PSFMessage -Level Debug -String 'Convert-Principal.Processing.NTDetails' -StringValues $domainPart, $namePart

            $param = @{
                Server = $domain.DNSRoot
            }
            $cred = Get-DMDomainCredential -Domain $domain.DNSRoot
			if ($cred) { $param['Credential'] = $cred }
			Write-PSFMessage -Level Debug -String 'Convert-Principal.Processing.NT.LdapFilter' -StringValues "(samAccountName=$namePart)"
			$adObject = Get-ADObject @param -LDAPFilter "(samAccountName=$namePart)" -Properties ObjectSID
            $script:cache_PrincipalToSID[$Name] = $adObject.ObjectSID
            $adObject.ObjectSID
        }
    }
}