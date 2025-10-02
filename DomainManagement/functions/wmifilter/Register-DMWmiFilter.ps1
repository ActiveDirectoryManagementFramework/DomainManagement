function Register-DMWmiFilter {
	<#
	.SYNOPSIS
		Registers the definition of a WMI Filter as desired state.
	
	.DESCRIPTION
		Registers the definition of a WMI Filter as desired state.
	
	.PARAMETER Name
		Name of the WMI Filter (must be unique in domain).
	
	.PARAMETER Description
	 	A description of the WMI filter
	
	.PARAMETER Query
		The filter query/ies to apply.
		Can be multiple queries, defaults to the WMI namespace defined in the namespace parameter.
		To specify a namespace with the query, use this notation: {namespace};{query}
		(without the curly braces).
		Examples:
		SELECT * FROM Win32_OperatingSystem WHERE Caption like "Microsoft Windows 10%"
		root\CIMv2;SELECT * FROM Win32_OperatingSystem WHERE Caption like "Microsoft Windows 10%"
	
	.PARAMETER Namespace
		The WMI namespace in which the queries will be executed by default.
		Defaults to: root\CIMv2
	
	.PARAMETER Author
		The author of the WMI filter. Purely documentational.
		Defaults to: undefined
	
	.PARAMETER CreatedOn
		The timestamp the WMI filter was defined at. Purely documentational.
		Defaults to: Get-Date
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\wmifilters.json | ConvertFrom-Json | Write-Output | Register-DMWmiFilter
	
		Load up all settings defined in wmifilters.json
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Query,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Namespace = 'root\CIMv2',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Author = 'undefined',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[DateTime]
		$CreatedOn = (Get-Date),
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		$queries = foreach ($entry in $Query) {
			$currentNamespace = $Namespace
			$currentQuery = $entry
			if ($entry -like "*;*") {
				$currentNamespace, $currentQuery = $entry -split ";"
			}
			$item = [PSCustomObject]@{
				Namespace = $currentNamespace
				Query = $currentQuery
			}
			Add-Member -InputObject $item -MemberType ScriptMethod -Name ToQuery -Value {
				'3;{0};{1};WQL;{2};{3};' -f $this.Namespace.Length, $this.Query.Length, $this.Namespace, $this.Query
			}
			Add-Member -InputObject $item -MemberType ScriptMethod -Name ToString -Value {
				'{0}: {1}' -f $this.Namespace, $this.Query
			} -Force -PassThru
		}

		$script:wmifilter[$Name] = [PSCustomObject]@{
			PSTypeName  = 'DomainManagement.Configuration.WmiFilter'
			Name        = $Name
			Description = $Description
			Query       = $queries
			Author      = $Author
			CreatedOn   = $CreatedOn
			ContextName = $ContextName
		}

		Add-Member -InputObject $script:wmifilter[$Name] -MemberType ScriptMethod -Name GetQueryString -Value {
			'{0};{1}' -f @($this.Query).Count, ($this.Query | ForEach-Object ToQuery | Join-String "")
		}
	}
}