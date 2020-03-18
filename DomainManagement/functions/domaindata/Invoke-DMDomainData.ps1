function Invoke-DMDomainData {
	<#
	.SYNOPSIS
		Gathers domain specific data.
	
	.DESCRIPTION
		Gathers domain specific data.
		The gathering scripts are supplied using Register-DMDomainData.
		The data is currently consumed only by the extended group policy Component.
	
	.PARAMETER Name
		Name of the registered scriptblock to invoke.
	
	.PARAMETER Reset
		Disable retrieving data from cache.
		By default, all data is cached on a per-domain basis.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Invoke-DMDomainData @parameters -Name PKIServer

		Executes the scriptblock stored as PKIServer against the targeted domain.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[PsfValidatePattern('^[\d\w_]+$', ErrorString = 'DomainManagement.Validate.DomainData.Pattern')]
		[string]
		$Name,

		[switch]
		$Reset,
		
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

		[switch]
		$EnableException
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		#region Script not found
		if (-not $script:domainDataScripts[$Name]) {
			$result = [PSCustomObject]@{
				Name      = $Name
				Data      = $null
				Error     = "Script not found, check configuration"
				Success   = $false
				Type      = "ScriptNotFound"
				Timestamp = Get-Date
			}
			Write-PSFMessage -Level Warning -String 'Invoke-DMDomainData.Script.NotFound' -StringValues $Name -Target $result
			if ($EnableException) {
				Stop-PSFFunction -String 'Invoke-DMDomainData.Script.NotFound.Error' -StringValues $Name -Target $result -EnableException $EnableException -Category ObjectNotFound
			}

			$result
			return
		}
		#endregion Script not found

		$domainObject = Get-Domain2 @parameters
		if (-not $script:cache_DomainData[$domainObject.DNSRoot]) { $script:cache_DomainData[$domainObject.DNSRoot] = @{ } }
		if ($script:cache_DomainData[$domainObject.DNSRoot][$Name] -and -not $Reset) { return $script:cache_DomainData[$domainObject.DNSRoot][$Name] }
		
		$scriptTask = $script:domainDataScripts[$Name]
		$result = [PSCustomObject]@{
			Name      = $Name
			Data      = $null
			Error     = $null
			Success   = $false
			Type      = $null
			Timestamp = Get-Date
		}

		try {
			$result.data = $scriptTask.Scriptblock.Invoke($parameters.Clone())
			$result.Success = $true
			$result.Type = 'Success'
			$result.Timestamp = Get-Date
			$script:cache_DomainData[$domainObject.DNSRoot][$Name] = $result
			$result
		}
		catch {
			$result.Error = $_
			$result.Timestamp = Get-Date
			$result.Type = $_.CategoryInfo.Category

			Write-PSFMessage -String 'Invoke-DMDomainData.Invocation.Error' -StringValues $Name -ErrorRecord $_ -Target $result
			if ($EnableException) {
				Stop-PSFFunction -String 'Invoke-DMDomainData.Invocation.Error.Terminate' -StringValues $Name -ErrorRecord $_ -Target $result -EnableException $EnableException
			}
			$result
		}
	}
}
