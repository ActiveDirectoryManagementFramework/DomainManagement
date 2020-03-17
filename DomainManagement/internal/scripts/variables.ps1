# NOTE: All variables in this file will be cleared when using Clear-DMConfiguration
# That generally happens when switching between sets of configuration

 #----------------------------------------------------------------------------#
 #                               Configuration                                #
 #----------------------------------------------------------------------------#

# Mapping table of values to insert
$script:nameReplacementTable = @{ }

# Configured Organizational Units
$script:organizationalUnits = @{ }

# Configured groups
$script:groups = @{ }

# Configured users
$script:users = @{ }

# Configured Group Memberships
$script:groupMemberShips = @{ }

# Configured Finegrained Password Policies
$script:passwordPolicies = @{ }

# Configured group policy objects
$script:groupPolicyObjects = @{ }

# Configured group policy links
$script:groupPolicyLinks = @{ }

# Configured group policy permission filters
$script:groupPolicyPermissionFilters = @{ }

# Configured group policy permissions
$script:groupPolicyPermissions = @{ }

# Configured ACLs
$script:acls = @{ }

# Configured Access Rules - Based on OU / Path
$script:accessRules = @{ }

# Configured Access Rules - Based on Object Category
$script:accessCategoryRules = @{ }

# Configured Object Categories
$script:objectCategories = @{ }

# Configured generic objects
$script:objects = @{ }

# Configured data gathering scripts
$script:domainDataScripts = @{ }


 #----------------------------------------------------------------------------#
 #                                Cached Data                                 #
 #----------------------------------------------------------------------------#

# Cached security principals, used by Get-Principal. Mapping to AD Objects
$script:resolvedPrincipals = @{ }

# More principal caching, used by Convert-Principal. Mapping to SID or NT Account
$script:cache_PrincipalToSID = @{ }
$script:cache_PrincipalToNT = @{ }

# Cached domain data, used by Invoke-DMDomainData. Can be any script logic result
$script:cache_DomainData = @{ }


 #----------------------------------------------------------------------------#
 #                                Context Data                                #
 #----------------------------------------------------------------------------#

# Content Mode
$script:contentMode = [PSCustomObject]@{
    PSTypeName = 'DomainManagement.Content.Mode'
    Mode    = 'Additive'
    Include = @()
    Exclude = @()
    UserExcludePattern = @()
}
$script:contentSearchBases = [PSCustomObject]@{
    Include = @()
    Exclude = @()
    Bases   = @()
    Server = ''
}

# Domain Context
$script:domainContext = [PSCustomObject]@{
    Name = ''
    Fqdn = ''
    DN   = ''
    ForestFqdn = ''
}

#  Red Forest Context
$script:redForestContext = [PSCustomObject]@{
    Name = ''
    Fqdn = ''
    RootDomainFqdn = ''
    RootDomainName = ''
}