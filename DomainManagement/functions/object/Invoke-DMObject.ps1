function Invoke-DMObject
{
	<#
		.SYNOPSIS
			Updates the generic ad object configuration of a domain to conform to the configured state.
		
		.DESCRIPTION
			Updates the generic ad object configuration of a domain to conform to the configured state.
		
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
			PS C:\> Invoke-DMObject -Server contoso.com

			Updates the generic objects in the domain contoso.com to conform to configuration
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Objects -Cmdlet $PSCmdlet
		$testResult = Test-DMObject @parameters
		Set-DMDomainContext @parameters
	}
	process
	{
		foreach ($testItem in ($testResult | Sort-Object { $_.Identity.Length })) {
			switch ($testItem.Type) {
				'Create' {
					$createParam = $parameters.Clone()
					$createParam += @{
						Path = Resolve-String -Text $testItem.Configuration.Path
						Name = Resolve-String -Text $testItem.Configuration.Name
						Type = Resolve-String -Text $testItem.Configuration.ObjectClass
					}
					if ($testItem.Configuration.Attributes.Count -gt 0) {
						$hash = @{ }
						foreach ($key in $testItem.Configuration.Attributes.Keys) {
							if ($key -notin $testItem.Configuration.AttributesToResolve) { $hash[$key] = $testItem.Configuration.Attributes[$key] }
							else { $hash[$key] = $testItem.Configuration.Attributes[$key] | Resolve-String }
						}
						$createParam['OtherAttributes'] = $hash
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMObject.Object.Create' -ActionStringValues $testItem.Configuration.ObjectClass, $testItem.Identity -Target $testItem -ScriptBlock {
						New-ADObject @createParam -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'Changed' {
					$setParam = $parameters.Clone()
					$setParam += @{
						Identity = $testItem.Identity
					}
					$replaceHash = @{ }
					foreach ($propertyName in $testItem.Changed) {
						if ($propertyName -notin $testItem.Configuration.AttributesToResolve) { $replaceHash[$propertyName] = $testItem.Configuration.Attributes[$propertyName] }
						else { $replaceHash[$propertyName] = $testItem.Configuration.Attributes[$propertyName] | Resolve-String }
					}
					$setParam['Replace'] = $replaceHash
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DMObject.Object.Change' -ActionStringValues ($testItem.Changed -join ", ") -Target $testItem -ScriptBlock {
						Set-ADObject @setParam -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
			}
		}
	}
}