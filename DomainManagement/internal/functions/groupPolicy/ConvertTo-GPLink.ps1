function ConvertTo-GPLink {
    <#
    .SYNOPSIS
        Parses the gPLink property on ad objects.
    
    .DESCRIPTION
        Parses the gPLink property on ad objects.
        This allows analyzing gPLinkOrder without consulting the GPO API.
    
    .PARAMETER ADObject
        The adobject from which to take the gPLink property.
    
    .PARAMETER PolicyMapping
        Hashtable mapping distinguished names of group policies to their respective displayname.
    
    .EXAMPLE
        PS C:\> $adObjects | ConvertTo-GPLink

        Converts all objects in $adObjects to GPLink metadata.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $ADObject,

        [Hashtable]
        $PolicyMapping = @{ }
    )

    begin {
        $statusMapping = @{
            "0" = 'Enabled'
            "1" = 'Disabled'
            "2" = 'Enforced'
		}
    }
    process {
        foreach ($adItem in $ADObject) {
            if (-not $adItem.gPLink) { continue }
            if ([string]::IsNullOrWhiteSpace($adItem.gPLink)) { continue }

            $pieces = $adItem.gPLink -Split "\[" | Remove-PSFNull
            $index = ($pieces | Measure-Object).Count

            foreach ($gpLink in $pieces) {
                $linkObject = [PSCustomObject]@{
                    ADObject = $adItem
                    DistinguishedName = ($gpLink -replace '^LDAP://|;\d\]$')
                    Status = $statusMapping[($gpLink -replace '^.+;|\]$')]
                    DisplayName = $PolicyMapping[($gpLink -replace '^LDAP://|;\d\]$')]
                    Precedence = $index
                }
                Add-Member -InputObject $linkObject -MemberType ScriptMethod -Name ToString -Value {
                    switch ($this.Status) {
                        'Enabled' { $this.DisplayName }
                        'Disabled' { '~|{0}' -f $this.DisplayName }
                        'Enforced' { '*|{0}' -f $this.DisplayName }
                    }
				} -Force
				Add-Member -InputObject $linkObject -MemberType ScriptMethod -Name ToLink -Value {
					# [LDAP://cn={F4A6ADB1-BEDE-497D-901F-F24B19394951},cn=policies,cn=system,DC=contoso,DC=com;0][LDAP://cn={2036B9B6-D5C1-4756-B7AB-8291A9B26521},cn=policies,cn=system,DC=contoso,DC=com;0]
					$status = '0'
					if ($this.Status -eq 'Disabled') { $status = '1' }
					if ($this.Status -eq 'Enforced') { $status = '2' }
					'[LDAP://{0};{1}]' -f $this.DistinguishedName, $status
				}
                $linkObject
                $index--
            }
        }
    }
}