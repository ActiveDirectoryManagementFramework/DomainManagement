# File for variables that should NOT be reset on context changes
$script:builtInSidMapping = @{
	# English
	'BUILTIN\Administrators'                                            = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'
	'BUILTIN\Account Operators'                                         = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-548'
	'BUILTIN\Server Operators'                                          = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-549'
	'BUILTIN\Print Operators'                                           = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-550'
	'BUILTIN\Pre-Windows 2000 Compatible Access'                        = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-554'
	'BUILTIN\Incoming Forest Trust Builders'                            = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-557'
	'BUILTIN\Windows Authorization Access Group'                        = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-560'
	'BUILTIN\Terminal Server License Servers'                           = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-561'
	'BUILTIN\Certificate Service DCOM Access'                           = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-574'
	'BUILTIN\RDS Remote Access Servers'                                 = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-575'
	'BUILTIN\RDS Endpoint Servers'                                      = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-576'
	'BUILTIN\RDS Management Servers'                                    = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-577'
	'BUILTIN\Storage Replica Administrators'                            = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-582'

	# Deutsch
	'BUILTIN\Administratoren'                                           = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'
	'BUILTIN\Konten-Operatoren'                                         = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-548'
	'BUILTIN\Server-Operatoren'                                         = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-549'
	'BUILTIN\Druck-Operatoren'                                          = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-550'
	'BUILTIN\Prä-Windows 2000 kompatibler Zugriff'                      = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-554'
	'BUILTIN\Erstellungen eingehender Gesamtstrukturvertrauensstellung' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-557'
	'BUILTIN\Windows-Autorisierungszugriffsgruppe'                      = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-560'
	'BUILTIN\Terminalserver-Lizenzserver'                               = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-561'
	'BUILTIN\Zertifikatdienst-DCOM-Zugriff'                             = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-574'
	# 'BUILTIN\RDS Remote Access Servers'                                 = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-575'
	# 'BUILTIN\RDS Endpoint Servers'                                      = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-576'
	# 'BUILTIN\RDS Management Servers'                                    = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-577'
	# 'BUILTIN\Storage Replica Administrators'                            = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-582'
}

# Persistent Cache for Default Permissions
$script:schemaObjectDefaultPermission = @{ }