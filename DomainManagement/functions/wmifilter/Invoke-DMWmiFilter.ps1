function Invoke-DMWmiFilter {
	<#
	.SYNOPSIS
		Applies the desired state of WMI Filters to the target domain.
	
	.DESCRIPTION
		Applies the desired state of WMI Filters to the target domain.
		Use Register-DMWmiFilter to define the desired state.
	
	.PARAMETER InputObject
		Individual test results to apply.
		Use Test-DMWmiFilter to generate these test result objects.
		If none are specified, it will instead execute its own test and apply all test results.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Invoke-DMWmiFilter -Server fabrikam.org
	
		Brings the fabrikam.org domain into compliance with the defined wmi filter configuration.
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
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
		Assert-Configuration -Type wmifilter -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		if (-not $InputObject) {
			$InputObject = Test-DMWmiFilter @parameters
		}

		:main foreach ($testItem in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DomainManagement.WmiFilter.TestResult') {
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DMWmiFilter', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type) {
				'Create' {
					$newID = ('{{{0}}}' -f ([Guid]::NewGuid())).ToUpper()
					$newParam = @{
						Path            = 'CN=SOM,CN=WMIPolicy,CN=System,%DomainDN%' | Resolve-String
						Name            = $newID
						Type            = 'msWMI-Som'
						OtherAttributes = @{
							'msWMI-Name'         = $testItem.Configuration.Name
							'msWMI-Author'       = $testItem.Configuration.Author
							'msWMI-CreationDate' = '{0:yyyyMMddHHmmss.fff}000-000' -f $testItem.Configuration.CreatedOn
							'msWMI-ChangeDate'   = '{0:yyyyMMddHHmmss.fff}000-000' -f $testItem.Configuration.CreatedOn
							'msWMI-Parm1'        = $testItem.Configuration.Description | Resolve-String
							'msWMI-Parm2'        = $testItem.Configuration.GetQueryString()
							'msWMI-ID'           = $newID
						}
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMWmiFilter.Creating' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						New-ADObject @parameters @newParam -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Update' {
					$replaceHash = @{ }
					foreach ($change in $testItem.Changed) {
						switch ($change.Property) {
							Author { $replaceHash['msWMI-Author'] = $change.New }
							Description { $replaceHash['msWMI-Parm1'] = $change.New }
							CreatedOn {
								$replaceHash['msWMI-CreationDate'] = '{0:yyyyMMddHHmmss.fff}000-000' -f $change.New
								$replaceHash['msWMI-ChangeDate'] = '{0:yyyyMMddHHmmss.fff}000-000' -f $change.New
							}
							Query { $replaceHash['msWMI-Parm2'] = $testItem.Configuration.GetQueryString() }
						}
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMWmiFilter.Updating' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						Set-ADObject @parameters -Replace $replaceHash -Identity $testItem.ADObject.DistinguishedName -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
				'Delete' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMWmiFilter.Deleting' -ActionStringValues $testItem.Identity -Target $testItem.Identity -ScriptBlock {
						Remove-ADObject @parameters -Identity $testItem.ADObject.DistinguishedName -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet
				}
			}
		}
	}
}