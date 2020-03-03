function Get-DMObjectDefaultPermission
{
	<#
	.SYNOPSIS
		Gathers the default object permissions in AD.
	
	.DESCRIPTION
		Gathers the default object permissions in AD.
		Uses PowerShell remoting against the SchemaMaster to determine the default permissions, as local identity resolution is not reliable.
	
	.PARAMETER ObjectClass
		The object class to look up.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-DMObjectDefaultPermission -ObjectClass user

		Returns the default permissions for a user.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$ObjectClass,

		[PSFComputer]
		$Server = '<Default>',

		[PSCredential]
		$Credential
	)
	
	begin
	{
		if (-not $script:schemaObjectDefaultPermission) {
			$script:schemaObjectDefaultPermission = @{ }
		}

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential

		#region Scriptblock that gathers information on default permission
		$gatherScript = {
			#$domain = Get-ADDomain -Server localhost
			#$forest = Get-ADForest -Server localhost
			#$rootDomain = Get-ADDomain -Server $forest.RootDomain
			$commonAce = @()
			<#
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '4c164200-20c0-11d0-a768-00aa006e0529', 'Descendents', '4828cc14-1437-45bc-9b07-ad6f015e5f28')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', 'bc0ac240-79a9-11d0-9020-00c04fc2d4cf', 'Descendents', '4828cc14-1437-45bc-9b07-ad6f015e5f28')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', 'bc0ac240-79a9-11d0-9020-00c04fc2d4cf', 'Descendents', 'bf967aba-0de6-11d0-a285-00aa003049e2')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '59ba2f42-79a2-11d0-9020-00c04fc2d3cf', 'Descendents', '4828cc14-1437-45bc-9b07-ad6f015e5f28')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '59ba2f42-79a2-11d0-9020-00c04fc2d3cf', 'Descendents', 'bf967aba-0de6-11d0-a285-00aa003049e2')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '037088f8-0ae1-11d2-b422-00a0c968f939', 'Descendents', '4828cc14-1437-45bc-9b07-ad6f015e5f28')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '037088f8-0ae1-11d2-b422-00a0c968f939', 'Descendents', 'bf967aba-0de6-11d0-a285-00aa003049e2')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '4c164200-20c0-11d0-a768-00aa006e0529', 'Descendents', 'bf967aba-0de6-11d0-a285-00aa003049e2')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '5f202010-79a5-11d0-9020-00c04fc2d4cf', 'Descendents', 'bf967aba-0de6-11d0-a285-00aa003049e2')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ReadProperty', 'Allow', '5f202010-79a5-11d0-9020-00c04fc2d4cf', 'Descendents', '4828cc14-1437-45bc-9b07-ad6f015e5f28')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'GenericRead', 'Allow', '00000000-0000-0000-0000-000000000000', 'Descendents', 'bf967aba-0de6-11d0-a285-00aa003049e2')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'GenericRead', 'Allow', '00000000-0000-0000-0000-000000000000', 'Descendents', 'bf967a9c-0de6-11d0-a285-00aa003049e2')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'GenericRead', 'Allow', '00000000-0000-0000-0000-000000000000', 'Descendents', '4828cc14-1437-45bc-9b07-ad6f015e5f28')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'BUILTIN\Pre-Windows 2000 Compatible Access'), 'ListChildren', 'Allow', '00000000-0000-0000-0000-000000000000', 'All', '00000000-0000-0000-0000-000000000000')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]"$($domain.NetBIOSName)\Key Admins"), 'ReadProperty, WriteProperty', 'Allow', '5b47d60f-6090-40b2-9f37-2a4de88f3063', 'All', '00000000-0000-0000-0000-000000000000')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]"$($rootDomain.NetBIOSName)\Enterprise Key Admins"), 'ReadProperty, WriteProperty', 'Allow', '5b47d60f-6090-40b2-9f37-2a4de88f3063', 'All', '00000000-0000-0000-0000-000000000000')
			$commonAce += New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]"$($rootDomain.NetBIOSName)\Enterprise Admins"), 'GenericAll', 'Allow', '00000000-0000-0000-0000-000000000000', 'All', '00000000-0000-0000-0000-000000000000')
			#>
			$parameters = @{ Server = $env:COMPUTERNAME }
			$rootDSE = Get-ADRootDSE @parameters
			$classes = Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter '(objectCategory=classSchema)' -Properties defaultSecurityDescriptor, lDAPDisplayName
			foreach ($class in $classes) {
				$acl = [System.DirectoryServices.ActiveDirectorySecurity]::new()
				$acl.SetSecurityDescriptorSddlForm($class.defaultSecurityDescriptor)
				foreach ($rule in $commonAce) { $acl.AddAccessRule($rule) }
				
				<#
				if ($class.lDAPDisplayName -eq 'organizationalUnit') {
					$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule(([System.Security.Principal.NTAccount]'Everyone'), 'DeleteTree, Delete', 'Deny', '00000000-0000-0000-0000-000000000000', 'None', '00000000-0000-0000-0000-000000000000')))
				}
				#>
				[PSCustomObject]@{
					Class = $class.lDAPDisplayName
					Access = $acl.Access
				}
			}
		}
		#endregion Scriptblock that gathers information on default permission
	}
	process
	{
		if ($script:schemaObjectDefaultPermission["$Server"]) {
			return $script:schemaObjectDefaultPermission["$Server"].$ObjectClass
		}

		#region Process Gathering logic
		if ($Server -ne '<Default>') {
			$parameters['ComputerName'] = $parameters.Server
			$parameters.Remove("Server")
		}
		
		try { $data = Invoke-PSFCommand @parameters -ScriptBlock $gatherScript -ErrorAction Stop }
		catch { throw }
		$script:schemaObjectDefaultPermission["$Server"] = @{ }
		foreach ($datum in $data) {
			$script:schemaObjectDefaultPermission["$Server"][$datum.Class] = $datum.Access
		}
		$script:schemaObjectDefaultPermission["$Server"].$ObjectClass
		#endregion Process Gathering logic
	}
}