# File for variables that should NOT be reset on context changes
$script:builtInSidMapping = @{
    # English
    'BUILTIN\Account Operators' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-548'
    'BUILTIN\Server Operators' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-549'
    'BUILTIN\Print Operators' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-550'
    'BUILTIN\Pre-Windows 2000 Compatible Access' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-554'
    'BUILTIN\Incoming Forest Trust Builders' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-557'
    'BUILTIN\Windows Authorization Access Group' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-560'
    'BUILTIN\Terminal Server License Servers' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-561'
    'BUILTIN\Certificate Service DCOM Access' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-574'
    'BUILTIN\RDS Remote Access Servers' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-575'
    'BUILTIN\RDS Endpoint Servers' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-576'
    'BUILTIN\RDS Management Servers' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-577'
    'BUILTIN\Storage Replica Administrators' = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-582'
}