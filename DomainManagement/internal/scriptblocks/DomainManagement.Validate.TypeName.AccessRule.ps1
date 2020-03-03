Set-PSFScriptblock -Name 'DomainManagement.Validate.TypeName.AccessRule' -Scriptblock {
    ($_.PSObject.TypeNames -contains 'DomainManagement.AccessRule')
}