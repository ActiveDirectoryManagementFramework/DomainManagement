function Register-DMExchangeVersion
{
<#
	.SYNOPSIS
		Registers an exchange version to apply to the domain's system objects.
	
	.DESCRIPTION
		Registers an exchange version to apply to the domain's system objects.
	
		Forest-Level changes to Exchange are handled by the ForestManagement module.
	
	.PARAMETER LocalImagePath
		The path where to find the Exchange ISO file
		Must be local on the remote server connected to!
		Updating the Exchange AD settings is only supported when executed through the installer contained in that ISO file without exceptions.
	
	.PARAMETER ExchangeVersion
		The version of the Exchange server to apply.
		E.g. 2016CU6
		We map Exchange versions to their respective identifiers in AD:
		RangeUpper in schema and ObjectVersion in the domain.
		This parameter is to help avoiding to have to look up those values.
		If your version is not supported by us yet, look up those numbers and explicitly bind it to -RangeUpper and -ObjectVersion isntead.
	
	.PARAMETER RangeUpper
		The explicit RangeUpper schema attribute property, found on the ms-Exch-Schema-Version-Pt class in schema.
	
	.PARAMETER ObjectVersion
		The object version on the msExchOrganizationContainer type object in the configuration.
		Do NOT confuse that with the ObjectVersion of the exchange object in the default Naming Context (regular domain space).
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Register-DMExchangeVersion -LocalImagePath 'C:\ISO\exchange-2019-cu6.iso' -ExchangeVersion '2019CU6'
	
		Registers the Exchange 2019 CU6 exchange version as exchange forest settings to be applied.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$LocalImagePath,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Version')]
		[PsfValidateSet(TabCompletion = 'ForestManagement.ExchangeVersion')]
		[PsfArgumentCompleter('ForestManagement.ExchangeVersion')]
		[string]
		$ExchangeVersion,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[int]
		$RangeUpper,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[int]
		$ObjectVersion,
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process
	{
		$object = [pscustomobject]@{
			PSTypeName	    = 'ForestManagement.Configuration.ExchangeSchema'
			RangeUpper	    = $RangeUpper
			ObjectVersion   = $ObjectVersion
			LocalImagePath  = $LocalImagePath
			ExchangeVersion = (Get-ExchangeVersion | Where-Object RangeUpper -eq $RangeUpper | Where-Object ObjectVersionConfig -EQ $ObjectVersion | Sort-Object Name | Select-Object -Last 1).Name
			ContextName	    = $ContextName
		}
		
		if ($ExchangeVersion)
		{
			# Will always succeede, since the input validation prevents invalid exchange versions
			$exchangeVersionInfo = Get-ExchangeVersion -Binding $ExchangeVersion
			$object.RangeUpper = $exchangeVersionInfo.RangeUpper
			$object.ObjectVersion = $exchangeVersionInfo.ObjectVersionDefault
			$object.ExchangeVersion = $exchangeVersionInfo.Name
		}
		
		Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value {
			if ($this.ExchangeVersion) { $this.ExchangeVersion }
			else { '{0} : {1}' -f $this.RangeUpper, $this.ObjectVersion }
		} -Force
		$script:exchangeVersion = @($object)
	}
}
