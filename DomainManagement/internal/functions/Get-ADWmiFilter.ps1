function Get-ADWmiFilter {
	<#
	.SYNOPSIS
		Parses WMI filter objects from the active directory.
	
	.DESCRIPTION
		Parses WMI filter objects from the active directory.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER Name
		Name of the WMI filter to retrieve.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-ADWmiFilter

		Returns all WMI Filters in the current domain.
	#>
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

		[string]
		$Name = '*'
	)

	begin {
		#region Functions
		function ConvertFrom-WmiFilterQuery {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				[string]
				$Query
			)

			process {
				$segments = $Query.Trim(';') -split ";"
				$index = 1
				while ($index -lt $segments.Count) {
					$item = [PSCustomObject]@{
						Namespace = $segments[$index + 4]
						Query     = $segments[$index + 5]
					}
					Add-Member -InputObject $item -MemberType ScriptMethod -Name ToString -Value { $this.Query } -Force
					Add-Member -InputObject $item -MemberType ScriptMethod -Name ToQuery -Value {
						'3;{0};{1};WQL;{2};{3};' -f $this.Namespace.Length, $this.Query.Length, $this.Namespace, $this.Query
					}
					$item
					$index = $index + 6
				}
			}
		}
		
		function ConvertFrom-WmiFilterTime {
			[OutputType([DateTime])]
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				[string]
				$Time
			)

			process {
				[datetime]::ParseExact(($Time -replace '000-000$'), 'yyyyMMddHHmmss.fff', $null)
			}
		}
		#endregion Functions

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
	}
	process {
		$wmiFilterObjects = Get-ADObject @parameters -LDAPFilter "(&(objectClass=msWMI-Som)(msWMI-Name=$Name))" -Properties msWMI-Name, msWMI-Author, msWMI-CreationDate, msWMI-ChangeDate, msWMI-Parm1, msWMI-Parm2, msWMI-ID

		foreach ($wmiFilterObject in $wmiFilterObjects) {
			[PSCustomObject]@{
				Name              = $wmiFilterObject.'msWMI-Name'
				Author            = $wmiFilterObject.'msWMI-Author'
				CreationDate      = $wmiFilterObject.'msWMI-CreationDate' | ConvertFrom-WmiFilterTime
				ChangeDate        = $wmiFilterObject.'msWMI-ChangeDate' | ConvertFrom-WmiFilterTime
				Description       = $wmiFilterObject.'msWMI-Parm1'
				Query             = $wmiFilterObject.'msWMI-Parm2' | ConvertFrom-WmiFilterQuery
				DistinguishedName = $wmiFilterObject.DistinguishedName
				ID                = $wmiFilterObject.'msWMI-ID'
			}
		}
	}
}