# Domain Management

## The Project

The Domain Management Module is part of the [Active Directory Management Framework](https://admf.one).

Visit the [Project Website](https://admf.one) for more details and the full documentation.

## Synopsis

Module to manage Domain level Active Directory content.
This module allows explicitly defining how a domain should be configured and then either validating an existing domain against the configured state, or bringing a domain into the configured state.

For most applications, it is recommended to use the tools provided by the ADMF module, rather than directly accessing the resources provided by this module:

```powershell
Install-Module ADMF
```

For more details on how to define and manage configuration, see the documentation on the ADMF module.

## Elementary Steps

First of all, it becomes necessary to define a desired state.
For example, let's define a group:

```powershell
Register-DMGroup -Name "SEC-0-Admins" -Path "OU=Groups,OU=Tier-0,%DomainDN%" -Description "Tier 0 Administrators group" -Scope DomainLocal
```

This allows us now to test, whether this group is properly configured:

```powershell
# Local Domain
Test-DMGroup

# Target Domain
Test-DMGroup -Server contoso.com

# Target Domain with credentials
Test-DMGroup -Server contoso.com -Credential $cred
```

If we now want to _apply_ those defined changes, all we need to do is invoke them:

```powershell
# Local Domain
Invoke-DMGroup

# Target Domain
Invoke-DMGroup -Server contoso.com

# Target Domain with credentials
Invoke-DMGroup -Server contoso.com -Credential $cred
```
