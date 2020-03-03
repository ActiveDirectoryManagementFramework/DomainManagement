function Test-DMObject
{
	<#
		.SYNOPSIS
			Tests, whether the desired objects have been defined correctly in AD.
		
		.DESCRIPTION
			Tests, whether the desired objects have been defined correctly in AD.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
	
		.EXAMPLE
			PS C:\> Test-DMObject

			Tests whether the current domain has all the custom objects as defined.
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
		Assert-Configuration -Type Objects -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process
	{
		foreach ($objectDefinition in $script:objects.Values) {
			$resolvedPath = Resolve-String -Text $objectDefinition.Identity

			$resultDefaults = @{
				Server = $Server
				ObjectType = 'Object'
				Identity = $resolvedPath
				Configuration = $objectDefinition
			}

			#region Does not exist
			if (-not (Test-ADObject @parameters -Identity $resolvedPath)) {
				New-TestResult @resultDefaults -Type Create
			}
			#endregion Does not exist

			#region Exists
			else {
				if ($objectDefinition.Attributes.Keys) {
					try { $adObject = Get-ADObject @parameters -Identity $resolvedPath -Properties ($objectDefinition.Attributes.Keys | Write-Output) }
					catch { Stop-PSFFunction -String 'Test-DMObject.ADObject.Access.Error' -StringValues $resolvedPath, ($objectDefinition.Attributes.Keys -join ",") -Continue -ErrorRecord $_ -Tag error, baddata }
				}
				else {
					try { $adObject = Get-ADObject @parameters -Identity $resolvedPath }
					catch { Stop-PSFFunction -String 'Test-DMObject.ADObject.Access.Error2' -StringValues $resolvedPath -Continue -ErrorRecord $_ -Tag error }
				}
				
				[System.Collections.ArrayList]$changes = @()
				foreach ($propertyName in $objectDefinition.Attributes.Keys) {
					Compare-Property -Property $propertyName -Configuration $objectDefinition.Attributes -ADObject $adObject -Changes $changes -Resolve:$($objectDefinition.AttributesToResolve -contains $propertyName)
				}
				if ($changes.Count) {
					New-TestResult @resultDefaults -Type Changed -Changed $changes.ToArray() -ADObject $adObject
				}
			}
			#endregion Exists
		}
	}
}