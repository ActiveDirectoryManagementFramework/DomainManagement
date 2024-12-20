﻿# NOTE: All variables in this file will be cleared when using Clear-DMConfiguration
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

# Configured group policy registry settings
$script:groupPolicyRegistrySettings = @{ }

# Configured group policy links
$script:groupPolicyLinks = @{ }
$script:groupPolicyLinksDynamic = @{ }

# Configured group policy permission filters
$script:groupPolicyPermissionFilters = @{ }

# Configured group policy permissions
$script:groupPolicyPermissions = @{ }

# Configured owners of group policy objects
$script:groupPolicyOwners = @{ }

# Configured ACLs
$script:acls = @{ }
$script:aclByCategory = @{ }
$script:aclDefaultOwner = $null

# Configured Access Rules - Based on OU / Path
$script:accessRules = @{ }

# Configured Access Rule processing Modes
$script:accessRuleMode = @{ }

# Configured Access Rules - Based on Object Category
$script:accessCategoryRules = @{ }

# Configured Object Categories
$script:objectCategories = @{ }

# Configured generic objects
$script:objects = @{ }

# Configured data gathering scripts
$script:domainDataScripts = @{ }

# Configured domain functional level
$script:domainLevel = $null

# Configured Exchange Domain Setting Versions
$script:exchangeVersion = $null

# Configured Group Managed Service Accounts
$script:serviceAccounts = @{ }

# Configured WMI Filter
$script:wmifilter = @{ }


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

# Domain mapping cache, used by Get-Domain
$script:SIDtoDomain = @{ }
$script:DNStoDomain = @{ }
$script:DNStoDomainName = @{ }
$script:NetBiostoDomain = @{ }


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
	RemoveUnknownWmiFilter = $false

	# Note: Also update the help on Set-DMContentMode and on the website Content Mode documentation, when adding new entries here.
	ExcludeComponents = @{
		ACLs = $false
		GPLinks = $false
		GroupMembership = $false
		Groups = $false
		OrganizationalUnits = $false
		ServiceAccounts = $false
	}
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