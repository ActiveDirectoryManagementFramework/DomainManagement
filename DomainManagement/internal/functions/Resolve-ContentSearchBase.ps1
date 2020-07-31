function Resolve-ContentSearchBase
{
<#
	.SYNOPSIS
		Resolves the ruleset for content enforcement into actionable search data.
	
	.DESCRIPTION
		Resolves the ruleset for content enforcement into actionable search data.
		This ensures that both Include and Exclude rules are properly translated into AD search queries.
		This command is designed to be called by all Test- commands across the entire module.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER NoContainer
		By defaults, containers are returned as well.
		Using this parameter prevents container processing.
	
	.PARAMETER IgnoreMissingSearchbase
		Disables warnings if a defined searchbase is missing.
		For use in OU tests.
	
	.EXAMPLE
		PS C:\> Resolve-ContentSearchBase @parameters
		
		Resolves the configured filters into searchbases for the targeted domain.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding()]
    Param (
        [string]
        $Server,

        [pscredential]
		$Credential,
		
		[switch]
		$NoContainer,
		
		[switch]
		$IgnoreMissingSearchbase
    )
    begin
    {
        $parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false

		#region Utility Functions
        function Convert-DistinguishedName {
            [CmdletBinding()]
            param (
                [Parameter(ValueFromPipeline = $true)]
                [string[]]
                $Name,

                [switch]
                $Exclude
            )
            process {
                foreach ($nameItem in $Name) {
                    [PSCustomObject]@{
                        Name = $nameItem
                        Depth = ($nameItem -split "," | Where-Object { $_ -notlike "DC=*" }).Count
                        Elements = ($nameItem -split "," | Where-Object { $_ -notlike "DC=*" })
                        Exclude = $Exclude.ToBool()
                    }
                }
            }
        }

        function Get-ChildRelationship {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                $Parent,

                [Parameter(Mandatory = $true)]
                $Items
            )

            foreach ($item in $Items) {
				if ($item.Name -notlike "*,$($Parent.Name)") { continue }

                [PSCustomObject]@{
                    Child = $item
                    Parent = $Parent
                    Delta = $item.Depth - $Parent.Depth
                }
            }
		}

		function New-SearchBase {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				[string]
				$Name,

				[ValidateSet('OneLevel', 'Subtree')]
				[string]
				$Scope = 'Subtree'
			)

			[PSCustomObject]@{
				SearchBase = $Name
				SearchScope = $Scope
			}
		}

		function Resolve-SearchBase {
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory = $true)]
				$Parent,

				[Parameter(Mandatory = $true)]
				$Children,

				[string]
				$Server,

				[pscredential]
				$Credential
			)
			New-SearchBase -Name $Parent.Name -Scope OneLevel

			$childPaths = @{
				$Parent.Name = @{}
			}
			foreach ($childItem in $Children) {
				$subPath = $childItem.Name.Replace($Parent.Name, '').Trim(",")
				$subPathSegments = $subPath.Split(",")
				[System.Array]::Reverse($subPathSegments)

				$basePath = $Parent.Name
				foreach ($pathSegment in $subPathSegments) {
					$newDN = $pathSegment, $basePath -join ","
					$childPaths[$basePath][$newDN] = $newDN
					if (-not $childPaths[$newDN]) { $childPaths[$newDN] = @{ } }
					$basePath = $newDN
				}
			}

			$currentPath = ''
			[System.Collections.ArrayList]$pathsToProcess = @($Parent.Name)
			while ($pathsToProcess.Count -gt 0) {
				$currentPath = $pathsToProcess[0]
				$nextContainerObjects = Get-ADObject @parameters -SearchBase $currentPath -SearchScope OneLevel -LDAPFilter '(|(objectCategory=container)(objectCategory=organizationalUnit))'
				foreach ($containerObject in $nextContainerObjects) {
					# Skip the actual children, as those (and their children) have already been processed
					if ($containerObject.DistinguishedName -in $Children.Name) { continue }
					if ($childPaths.ContainsKey($containerObject.DistinguishedName)) {
						New-SearchBase -Name $containerObject.DistinguishedName -Scope OneLevel
						$null = $pathsToProcess.Add($containerObject.DistinguishedName)
					}
					else {
						New-SearchBase -Name $containerObject.DistinguishedName
					}
				}
				$pathsToProcess.Remove($currentPath)
			}
		}
		#endregion Utility Functions

		Set-DMDomainContext @parameters
		$warningLevel = 'Warning'
		if (@(Get-ADOrganizationalUnit @parameters -ErrorAction Ignore -ResultSetSize 2 -Filter *).Count -eq 1) { $warningLevel = 'Verbose' }
    }
    process
    {
		#region preprocessing and early termination
        # Don't process any OUs if in Additive Mode
        if ($script:contentMode.Mode -eq 'Additive') { return }

        # If already processed, return previous results
        if (($Server -eq $script:contentSearchBases.Server) -and (-not (Compare-Object $script:contentMode.Include $script:contentSearchBases.Include)) -and (-not (Compare-Object $script:contentMode.Exclude $script:contentSearchBases.Exclude))) {
			if ($NoContainer) { $script:contentSearchBases.Bases | Where-Object SearchBase -notlike "CN=*" }
			else { $script:contentSearchBases.Bases }
			return
        }

		# Parse Includes and excludes
        $include = $script:contentMode.Include | Resolve-String | Convert-DistinguishedName
        $exclude = $script:contentMode.Exclude | Resolve-String | Convert-DistinguishedName -Exclude
		
		# If no todo: Terminate
		if (-not ($include -or $exclude)) { return }

		# Implicitly include domain when no custom include rules
        if ($exclude -and -not $include) {
            $include = $script:domainContext.DN | Convert-DistinguishedName
        }
        $allItems = @{}
        foreach ($item in $include) {
			if (-not (Test-ADObject @parameters -Identity $item.Name)) {
				if ($IgnoreMissingSearchbase) { continue }
				Write-PSFMessage -Level $warningLevel -String 'Resolve-ContentSearchBase.Include.NotFound' -StringValues $item.Name -Tag notfound, container -Target $Server
				continue
			}
            $allItems[$item.Name] = $item
        }
        foreach ($item in $exclude) {
			if (-not (Test-ADObject @parameters -Identity $item.Name)) {
				if ($IgnoreMissingSearchbase) { continue }
				Write-PSFMessage -Level $warningLevel -String 'Resolve-ContentSearchBase.Exclude.NotFound' -StringValues $item.Name -Tag notfound, container -Target $Server
				continue
			}
            $allItems[$item.Name] = $item
        }
        $relationship_All = foreach ($item in $allItems.Values) {
            Get-ChildRelationship -Parent $item -Items $allItems.Values
        }
        # Remove multiple include/exclude nestings producing reddundant inheritance detection
        $relationship_Relevant = $relationship_All | Group-Object { $_.Child.Name } | ForEach-Object {
            $_.Group | Sort-Object Delta | Select-Object -First 1
        }
		#endregion preprocessing and early termination

		[System.Collections.ArrayList]$itemsProcessed = @()
		[System.Collections.ArrayList]$targetOUsFound = @()

		foreach ($item in ($allItems.Values | Sort-Object Depth -Descending)) {
			$children = $relationship_Relevant | Where-Object { $_.Parent.Name -eq $item.Name }
			$allChildren = $relationship_All | Where-Object { $_.Parent.Name -eq $item.Name }

			# Case: Exclude Rule - will not be scanned
			if ($item.Exclude) {
				$null = $itemsProcessed.Add($item)
				continue
			}

			# Casse: No Children - Just add a plain searchbase
			if (-not $children) {
				$null = $targetOUsFound.Add((New-SearchBase -Name $item.Name))
				$null = $itemsProcessed.Add($item)
				continue
			}

			# Case: No recursive Children that would exclude something - Add plain searchbase and remove all entries from all children as not needed
			if (-not ($allChildren.Child | Where-Object Exclude)) {
				$redundantFindings = $targetOUsFound | Where-Object SearchBase -in $allChildren.Child.Name
				foreach ($finding in $redundantFindings) { $targetOUsFound.Remove($finding) }
				$null = $targetOUsFound.Add((New-SearchBase -Name $item.Name))
				$null = $itemsProcessed.Add($item)
				continue
			}

			# Case: Children that require processing
			foreach ($searchbase in (Resolve-SearchBase @parameters -Parent $item -Children $children.Child)) {
				$null = $targetOUsFound.Add($searchbase)
			}
			$null = $itemsProcessed.Add($item)
		}

		$script:contentSearchBases.Include = $script:contentMode.Include
		$script:contentSearchBases.Exclude = $script:contentMode.Exclude
		$script:contentSearchBases.Server = $Server
		$script:contentSearchBases.Bases = $targetOUsFound.ToArray()

		foreach ($searchBase in $script:contentSearchBases.Bases) {
			if ($NoContainer -and ($searchBase.SearchBase -like 'CN=*')) { continue }
			Write-PSFMessage -String 'Resolve-ContentSearchBase.Searchbase.Found' -StringValues $searchBase.SearchScope, $searchBase.SearchBase, $script:domainContext.Fqdn
			$searchBase
		}
	}
}