function Get-Dmobjectsdefaultpermissions
{
$rootDSE = Get-ADRootDSE -Server $env:COMPUTERNAME 
$classes = Get-ADObject -Server $env:COMPUTERNAME  -SearchBase $rootDSE.schemaNamingContext -LDAPFilter '(objectCategory=classSchema)' -Properties defaultSecurityDescriptor, lDAPDisplayName
foreach ($class in $classes) {
	$acl = [System.DirectoryServices.ActiveDirectorySecurity]::new()
	$acl.SetSecurityDescriptorSddlForm($class.defaultSecurityDescriptor)
	$access = foreach ($accessRule in $acl.Access) {
		try { Add-Member -InputObject $accessRule -MemberType NoteProperty -Name SID -Value $accessRule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]) }
		catch {
			# Do nothing, don't want the property if no SID is to be had
		}
		$accessRule
	}
	[PSCustomObject]@{
		Class = $class.lDAPDisplayName
		Access = $access
	}
}
}