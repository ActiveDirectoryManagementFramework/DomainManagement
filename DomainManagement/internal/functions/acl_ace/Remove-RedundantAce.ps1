function Remove-RedundantAce {
    <#
    .SYNOPSIS
        Removes redundant Access Rule entries.
    
    .DESCRIPTION
        Removes redundant Access Rule entries.
        This only considers explicit rules for the specified identity reference.
        It compares the highest privileged access rule with other rules only.

        This is designed to help prevent an explicit "GenericAll" privilege making redundant other entries.
        This function is explicitly called in Invoke-DMAccessRule, in case of a planned ACE removal failing (and only for the failing identity).
        That will only lead to trouble if a conflicting ACE is in the desired state (and who would desire something like that??)
    
    .PARAMETER AccessControlList
        The access control list to remove redundant ACE from.
    
    .PARAMETER IdentityReference
        The identity for which to do the removing.
    
    .EXAMPLE
        PS C:\> Remove-RedundantAce -AccessControlList $aclObject -IdentityReference $identity

        Removes all redundant access rules on $aclobject that apply to $identity.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    param (
        [System.DirectoryServices.ActiveDirectorySecurity]
        $AccessControlList,

        $IdentityReference
    )

    $relevantRules = $AccessControlList.Access | Where-Object {
        ($_.IsInherited -eq $false) -and ($_.IdentityReference -eq $IdentityReference)
    } | Sort-Object ActiveDirectoryRights -Descending
    if (-not $relevantRules) { return }

    $master = $null
    $results = foreach ($rule in $relevantRules) {
        if ($null -eq $master) {
            $master = $rule
            $rule
            continue
        }

        # If rights are not a subset of master: It's not redundant
        if (($master.ActiveDirectoryRights -band $rule.ActiveDirectoryRights) -ne $rule.ActiveDirectoryRights) {
            $rule
            continue
        }

        if ($master.InheritanceType -ne $rule.InheritanceType) {
            $rule
            continue
        }
        if ($master.AccessControlType -ne $rule.AccessControlType) {
            $rule
            continue
        }
        if (($master.ObjectType -ne $rule.ObjectType) -and ('00000000-0000-0000-0000-000000000000' -ne $master.ObjectType)) {
            $rule
            continue
        }
        if (($master.InheritedObjectType -ne $rule.InheritedObjectType) -and ('00000000-0000-0000-0000-000000000000' -ne $master.InheritedObjectType)) {
            $rule
            continue
        }
    }

    # If none were filtered out: Don't do anything
    if ($results.Count -eq $relevantRules.Count) { return }

    foreach ($rule in $relevantRules) { $null = $AccessControlList.RemoveAccessRule($rule) }
    foreach ($rule in $results) { $AccessControlList.AddAccessRule($rule) }
}