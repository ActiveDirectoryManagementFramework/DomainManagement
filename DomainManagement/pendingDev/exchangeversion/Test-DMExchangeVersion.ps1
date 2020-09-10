function Test-FMExchangeSchema
{
<#
	.SYNOPSIS
		Tests, whether the desired Exchange version has already been applied to the Forest.
	
	.DESCRIPTION
		Tests, whether the desired Exchange version has already been applied to the Forest.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-FMExchangeSchema -Server contoso.com
	
		Tests whether the desired Exchange version has already been applied to the contoso.com forest.
#>
	[CmdletBinding()]
	Param (
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
		Assert-Configuration -Type ExchangeSchema -Cmdlet $PSCmdlet
		
		#region Utility Functions
		function Get-ExchangeRangeUpper
		{
			[CmdletBinding()]
			param (
				[hashtable]
				$Parameters
			)
			
			$rootDSE = Get-ADRootDSE @parameters
			(Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(name=ms-Exch-Schema-Version-Pt)" -Properties rangeUpper).rangeUpper
		}
		
		function Get-ExchangeObjectVersion
		{
			[CmdletBinding()]
			param (
				[hashtable]
				$Parameters
			)
			
			$rootDSE = Get-ADRootDSE @parameters
			(Get-ADObject @parameters -SearchBase $rootDSE.configurationNamingContext -LDAPFilter '(objectClass=msExchOrganizationContainer)' -Properties ObjectVersion).ObjectVersion
		}
		#endregion Utility Functions
	}
	process
	{
		$forest = Get-ADForest @parameters
		$schemaVersion = Get-ExchangeRangeUpper -Parameters $parameters
		$objectVersion = Get-ExchangeObjectVersion -Parameters $parameters
		$displayName = (Get-ExchangeVersion | Where-Object RangeUpper -eq $schemaVersion | Where-Object ObjectVersionConfig -EQ $objectVersion | Sort-Object Name | Select-Object -Last 1).Name
		
		$adData = [pscustomobject]@{
			SchemaVersion = $schemaVersion
			ObjectVersion = $objectVersion
			DisplayName = $displayName
		}
		Add-Member -InputObject $adData -MemberType ScriptMethod -Name ToString -Value {
			if ($this.DisplayName) { $this.DisplayName }
			else { '{0} : {1}' -f $this.SchemaVersion, $this.ObjectVersion }
		} -Force
		$configuredData = Get-FMExchangeSchema
		
		if (-not $schemaVersion -or -not $objectVersion)
		{
			New-TestResult -ObjectType ExchangeSchema -Type Create -Identity $forest -Server $Server -Configuration $configuredData -ADObject $adData
		}
		elseif (($configuredData.RangeUpper -gt $schemaVersion) -or ($configuredData.ObjectVersion -gt $objectVersion))
		{
			New-TestResult -ObjectType ExchangeSchema -Type Update -Identity $forest -Server $Server -Configuration $configuredData -ADObject $adData
		}
	}
}
