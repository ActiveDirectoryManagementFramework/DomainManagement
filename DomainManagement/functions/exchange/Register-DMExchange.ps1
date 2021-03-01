function Register-DMExchange
{
<#
	.SYNOPSIS
		Registers an exchange version to apply to the domain's exchange objects.
	
	.DESCRIPTION
		Registers an exchange version to apply to the domain's exchange objects.
		Updating this requires Enterprise Admin permissions.
	
	.PARAMETER LocalImagePath
		The path where to find the Exchange ISO file
		Must be local on the remote server connected to!
		Updating the Exchange AD settings is only supported when executed through the installer contained in that ISO file without exceptions.
	
	.PARAMETER ExchangeVersion
		The version of the Exchange server to apply.
		E.g. 2016CU6
		We map Exchange versions to their respective identifiers in AD:
		RangeUpper in schema and ObjectVersion in configuration.
		This parameter is to help avoiding to have to look up those values.
		If your version is not supported by us yet, look up those numbers and explicitly bind it to -RangeUpper and -ObjectVersion instead.
	
	.PARAMETER ObjectVersion
		The object version on the "Microsoft Exchange System Objects" container in the domain.
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Register-DMExchange -LocalImagePath 'C:\ISO\exchange-2019-cu6.iso' -ExchangeVersion '2019CU6'
		
		Registers the Exchange 2019 CU6 exchange version as exchange domain settings to be applied.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$LocalImagePath,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Version')]
		[PsfValidateSet(TabCompletion = 'ADMF.Core.ExchangeVersion')]
		[PsfArgumentCompleter('ADMF.Core.ExchangeVersion')]
		[string]
		$ExchangeVersion,
		
		[Parameter(ParameterSetName = 'Details')]
		[int]
		$ObjectVersion,
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process
	{
		$object = [pscustomobject]@{
			PSTypeName	    = 'DomainManagement.Configuration.Exchange'
			ObjectVersion   = $ObjectVersion
			LocalImagePath  = $LocalImagePath
			ExchangeVersion = (Get-AdcExchangeVersion | Where-Object DomainVersion -eq $ObjectVersion | Sort-Object Name | Select-Object -Last 1).Name
			ContextName	    = $ContextName
		}
		
		if ($ExchangeVersion)
		{
			# Will always succeede, since the input validation prevents invalid exchange versions
			$exchangeVersionInfo = Get-AdcExchangeVersion -Binding $ExchangeVersion
			$object.ObjectVersion = $exchangeVersionInfo.DomainVersion
			$object.ExchangeVersion = $exchangeVersionInfo.Name
		}
		
		Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value {
			if ($this.ExchangeVersion) { $this.ExchangeVersion }
			else { $this.ObjectVersion }
		} -Force
		$script:exchangeVersion = @($object)
	}
}
