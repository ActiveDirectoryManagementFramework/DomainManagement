Set-PSFScriptblock -Name 'DomainManagement.Validate.Identity' -Scriptblock {
	if ($_ -as [System.Security.Principal.SecurityIdentifier]) { return $true }
	if (($_ -replace '%[\d\w_]+%','S-1-0-00-0000000000-0000000000-0000000000') -as [System.Security.Principal.SecurityIdentifier]) { return $true }
	if ($_ -like "*@*") { return $true }
	if ($_ -like "*\*") { return $true }
	$false
}