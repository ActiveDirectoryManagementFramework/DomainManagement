function Test-AccessRuleEquality {
    <#
    .SYNOPSIS
        Compares two access rules with each other.
    
    .DESCRIPTION
        Compares two access rules with each other.
    
    .PARAMETER Rule1
        The first rule to compare
    
    .PARAMETER Rule2
        The second rule to compare
    
    .EXAMPLE
        PS C:\> Test-AccessRuleEquality -Rule1 $rule -Rule2 $rule2

        Compares $rule with $rule2
    #>
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param (
        $Rule1,
        $Rule2,
		$Parameters
	)

	function Get-SID {
		[CmdletBinding()]
		param (
			$Rule,
			$Parameters
		)

		if ($Rule.SID) { return $Rule.SID }
		if ($Rule.IdentityReference -is [System.Security.Principal.SecurityIdentifier]) { return $Rule.IdentityReference }

		# NTAccount
		Convert-Principal -Name $Rule.IdentityReference -OutputType SID @Parameters
	}
	
	if ($Rule1.ActiveDirectoryRights -ne $Rule2.ActiveDirectoryRights) { return $false }
    if ($Rule1.InheritanceType -ne $Rule2.InheritanceType) { return $false }
    if ($Rule1.ObjectType -ne $Rule2.ObjectType) { return $false }
    if ($Rule1.InheritedObjectType -ne $Rule2.InheritedObjectType) { return $false }
    if ($Rule1.AccessControlType -ne $Rule2.AccessControlType) { return $false }
	if ("$(Convert-BuiltInToSID -Identity $Rule1.IdentityReference)" -ne "$(Convert-BuiltInToSID -Identity $Rule2.IdentityReference)")
	{
		$oneSID = Get-SID -Rule $Rule1 -Parameters $Parameters
		$twoSID = Get-SID -Rule $Rule2 -Parameters $Parameters
		if ("$oneSID" -ne "$twoSID") { return $false }
	}
    return $true
}