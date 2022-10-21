function Get-LinkedPolicy {
	<#
	.SYNOPSIS
		Scans all managed OUs and returns linked GPOs.
	
	.DESCRIPTION
		Scans all managed OUs and returns linked GPOs.
		Use Set-DMContentMode to define what OUs are considered "managed".
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-LinkedPolicy @parameters

		Returns all group policy objects that are linked to OUs under management.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		
		# OneLevel needs to be converted to base, as searching for OUs with "OneLevel" would return unmanaged OUs.
		# This search however is targeted at GPOs linked to managed OUs only.
		$translateScope = @{
			'Subtree'  = 'Subtree'
			'OneLevel' = 'Base'
			'Base'     = 'Base'
		}
		
		$gpoProperties = 'DisplayName', 'Description', 'DistinguishedName', 'CN', 'Created', 'Modified', 'gPCFileSysPath', 'ObjectGUID', 'isCriticalSystemObject', 'VersionNumber', 'gPCWQLFilter'

		$wmiFilters = Get-ADWmiFilter @parameters
	}
	process {
		$adObjects = foreach ($searchBase in (Resolve-ContentSearchBase @parameters)) {
			Get-ADObject @parameters -LDAPFilter '(gPLink=*)' -SearchBase $searchBase.SearchBase -SearchScope $translateScope[$searchBase.SearchScope] -Properties gPLink
		}
		foreach ($adObject in $adObjects) {
			Add-Member -InputObject $adObject -MemberType NoteProperty -Name LinkedGroupPolicyObjects -Value ($adObject.gPLink | Split-GPLink) -Force
		}
		foreach ($adPolicyObject in ($adObjects.LinkedGroupPolicyObjects | Select-Object -Unique | Get-ADObject @parameters -Properties $gpoProperties)) {
			$result = [PSCustomObject]@{
				PSTypeName        = 'DomainManagement.GroupPolicy.Linked'
				DisplayName       = $adPolicyObject.DisplayName
				Description       = $adPolicyObject.Description
				DistinguishedName = $adPolicyObject.DistinguishedName
				LinkedTo          = $adObjects | Where-Object LinkedGroupPolicyObjects -Contains $adPolicyObject.DistinguishedName
				CN                = $adPolicyObject.CN
				Created           = $adPolicyObject.Created
				Modified          = $adPolicyObject.Modified
				Path              = $adPolicyObject.gPCFileSysPath
				ObjectGUID        = $adPolicyObject.ObjectGUID
				IsCritical        = $adPolicyObject.isCriticalSystemObject
				ADVersion         = $adPolicyObject.VersionNumber
				ExportID          = $null
				ImportTime        = $null
				WmiFilter         = $null
				Version           = -1
				State             = "Unknown"
			}

			if ($adPolicyObject.gPCWQLFilter) {
				$result.WmiFilter = "<unknown: $($adPolicyObject.gPCWQLFilter))=>"
				$registeredID = ($adPolicyObject.gPCWQLFilter -split ";")[1]
				$wmiFilter = $wmiFilters | Where-Object ID -eq $registeredID
				if ($wmiFilter) { $result.WmiFilter = $wmiFilter.Name }
			}
			$result
		}
	}
}
