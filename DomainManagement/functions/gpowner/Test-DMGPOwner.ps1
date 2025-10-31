function Test-DMGPOwner {
	<#
	.SYNOPSIS
		Tests, whether a domain's group policy ownerships are in the desired state.
	
	.DESCRIPTION
		Tests, whether a domain's group policy ownerships are in the desired state.

		Use Register-DMGPOwner to define the desired state.
		Use Invoke-DMGPOwner to bring the domain into the desired state.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Test-DMGPOwner -Server corp.contoso.com

		Tests whether the domain of corp.contoso.com has the desired GP Owner configuration.
	#>
	[CmdletBinding()]
	Param (
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
		Assert-Configuration -Type GroupPolicyOwners -Cmdlet $PSCmdlet
		Set-DMDomainContext @parameters
	}
	process {
		$ownerConfig = Get-DMGPOwner

		#region Resolve which condition maps to which GPO
		$filterMapping = Resolve-GPFilterMapping @parameters -Conditions ($ownerConfig.FilterConditions | Remove-PSFNull -Enumerate | Sort-Object -Unique)
		if (-not $filterMapping.Success) {
			switch ($filterMapping.ErrorType) {
				MissingCondition {
					Stop-PSFFunction -String Test-DMGPOwner.Filter.Error.MissingCondition -StringValues ($filterMapping.MissingCondition -join ", ") -EnableException $EnableException -Category ObjectNotFound -Tag fail, panic -Target $filterMapping
					return
				}
				PathNotFound {
					Stop-PSFFunction -String Test-DMGPOwner.Filter.Error.PathNotFound -StringValues $filterMapping.ErrorData -EnableException $EnableException -Category ObjectNotFound -Tag fail, panic -Target $filterMapping
					return
				}
			}
		}
		#endregion Resolve which condition maps to which GPO

		foreach ($gpoADObject in $filterMapping.AllGpos) {
			$ownerCfg = $null
			#region Resolve applicable config item
			$ownerCfg = $ownerConfig | Where-Object {
				$_.Type -eq 'Explicit' -and
				$gpoADObject.DisplayName -eq (Resolve-String -Text $_.GpoName)
			} | Select-Object -First 1
			if (-not $ownerCfg) {
				$ownerCfg = $ownerConfig | Where-Object {
					$_.Type -eq 'Filter' -and
					(Test-GPPermissionFilter -GpoName $gpoADObject.DisplayName -Filter $_.Filter -Conditions $_.FilterConditions -FilterHash $filterMapping.Mapping)
				} | Sort-Object Weight | Select-Object -First 1
			}
			if (-not $ownerCfg) {
				$ownerCfg = $ownerConfig | Where-Object {
					$_.Type -eq 'All'
				}
			}
			# If nothing is configured, ignore GPO
			if (-not $ownerCfg) { continue }
			#endregion Resolve applicable config item

			try { $desiredOwner = Resolve-Principal @parameters -Name (Resolve-String -Text $ownerCfg.Identity) -OutputType ADObject -ErrorAction Stop }
			catch {
				Write-PSFMessage -Level Warning -String 'Test-DMGPOwner.Identity.NotFound' -StringValues $ownerCfg.Identity, $gpoADObject.DisplayName -Target $ownerCfg
				New-TestResult -ObjectType GPOwner -Type IdentityNotFound -Identity $gpoADObject.DisplayName -Server $Server -Configuration $ownerCfg -ADObject $gpoADObject
				continue
			}
			$actualAcl = Get-AdsAcl @parameters -Path $gpoADObject
			Add-Member -InputObject $gpoADObject -MemberType NoteProperty -Name Acl -Value $actualAcl -Force
			$actualOwner = $actualAcl.GetOwner([System.Security.Principal.SecurityIdentifier])
			if ("$actualOwner" -eq "$($desiredOwner.ObjectSID)") { continue }

			try { $actualOwnerAD = Resolve-Principal @parameters -Name $actualOwner -OutputType ADObject -ErrorAction Stop }
			catch { $actualOwnerAD = $null }

			$change = [PSCustomObject]@{
				PSTypeName = 'DomainManagement.GPOwner.Change'
				Type       = 'ChangeOwner'
				New        = $desiredOwner.SamAccountName
				Old        = $actualOwnerAD.SamAccountName
				NewObject  = $desiredOwner
				Policy     = $gpoADObject.DisplayName
			}
			if (-not $change.Old) { $change.Old = $actualOwner }
			Add-Member -InputObject $change -MemberType ScriptMethod -Name ToString -Value {
				'{0} -> {1}' -f $this.Old, $this.New
			} -Force

			New-TestResult -ObjectType GPOwner -Type Update -Identity $gpoADObject.DisplayName -Changed $change -Server $Server -Configuration $ownerCfg -ADObject $gpoADObject
		}
	}
}
