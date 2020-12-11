# Changelog

## ???

- Upd: Register-DMGroup - added parameter `-Optional` to make a group optional
- Upd: Renamed test result type `ConfigurationOnly` to `Create`
- Upd: Test-DMGroup - don't create Create actions for groups that are optional
- Upd: GPLink - added capability for dynamic path assignments
- Upd: GPLink - added processing modes to enable adding without removing unknown, as well as explicit delete orders
- Upd: GPLink - new priority system called tier. This enables grouping GPOs by category in separate priority sets
- Upd: ACL - added capability to define default ownership of objects under management
- Upd: ACL - added capability to define ownership and inheritance by object category for objects under management
- Fix: Test-GPPermission - path-based filters would not correctly map permissions
- Fix: Component Object - Does not allow modifying properties on the domain object itself
- Fix: Various - Removed duplicate confirm prompts from several invoke commands
- Fix: Invoke-DMGPPermission - handled error when identity could not be resolved (e.g. when a group does not exist but has assigned permissions)

## 1.4.85 (2020-10-11)

- Upd: Removed most dependencies due to bug in PS5.1. Dependencies in ADMF itself are now expected to provide the necessary tools / modules.
- Upd: Incremented PSFramework minimum version.

## 1.4.84 (2020-09-10)

- New: Component: DomainLevel - manage the functional level of your domain
- Upd: Test-DMGroupPolicy - added session re-use for GP Registry testing
- Fix: Invoke-DMAccessRule - updated action message to respect individual rule changes that failed
- Fix: Invoke-DMGroup - removed double shouldprocess when creating new group
- Fix: Invoke-DMOrganizationalUnit - removed double shouldprocess when creating new ou
- Fix: Invoke-DMUser - removed double shouldprocess when creating new user
- Fix: Test-DMGroupPolicy - removed confirm action on session removal
- Fix: Test-DMGPRegistrySetting - removed confirm action on session removal

## 1.3.76 (2020-07-31)

- New: Reset-DMDomainCredential - Resets cached credentials for contacting domains.
- Upd: Component Group Membership - now can define Group Processing Mode, introducing Constrained and Additive Modes to a group's memberships.
- Upd: Component Group Membership - configured names may now include SIDs, such as the SIDs of built-in accounts or groups.
- Fix: Register-DMGroupMembership - explicitly registering empty as $false no longer clears configured settings.
- Fix: Invoke-DMPasswordPolicy - disabled per-item confirmation prompt
- Fix: Invoke-DMOrganizationalUnit - fixed processing order

## 1.3.70 (2020-06-12)

- Upd: Test-DMAcl - supports SIDs for Ownership.

## 1.3.69 (2020-06-04)

- New: AccessRuleMode Component - allows controlling, how individual AccessRules are being processed.
- Upd: AccessRule - added support for AccessRule processing modes defined by the AccessRuleMode Component.
- Upd: GroupMember - added support for different processing modes, allowing optional group membership or optional assignee existence.
- Fix: Component Group - Renaming groups & delta between Name and SamAccountName will now be properly detected and handled.
- Fix: Invoke-DMUser ignores name updates

## 1.3.64 (2020-04-22)

- Fix: Test-DMAccessRule - Identity Resolution would fail sometimes

## 1.3.63 (2020-04-20)

- Fix: All Invokes broken

## 1.3.62 (2020-04-17)

- New: DomainData Component - allows dynamically gathering domain specific information.
- New: Group Policy Registry Settings Component - allows definining explicit registry settings to deploy using the targete GPO. Tightly integrated into the Group Policy component.
- Upd: User - now supports setting the "Enabled" state.
- Upd: User - now supports specifying a name in addition to SamAccountName
- Upd: Domain Context - Adding %DomainNetBIOSName% placeholder
- Upd: Names - All placeholders are no longer case sensitive
- Upd: Get-DMObjectDefaultPermission - now returns also the SID of each identity
- Upd: Invoke-DMUser - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMPasswordPolicy - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMOrganizationalUnit - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMObject - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMGroup - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMGroupPolicy - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMGroupMembership - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMGPPermission - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMGPLink - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMAcl - Supports individual testresults from pipeline, to process specific results
- Upd: Invoke-DMAccessRule - Supports individual testresults from pipeline, to process specific results
- Fix: Access Rules - identity reference comparison would rarely fail to match equal identities
- Fix: Access Rules - identity resolution of parents would domain-prefix the netbios name, not the domain name.
- Fix: Access Rules - an unknown privilege (e.g. due to missing Schema Extension) now reports an actionable error cause.
- Fix: Access Rules - broken detection of default permissions in domains where NETBIOS name -ne Domain Name
- Fix: GPPermissions - under rare circumstances would fail due to "unexpected value"
- Fix: GPPermissions - does not remove all cases of FullControl rights that should be removed
- Fix: GPPermissions - cannot downgrade permissions from FullControl to Custom
- Fix: GPPermissions - changing permissions causes the GroupPolicy component to detect a change and flags the policy as modified.
- Fix: GPPermissions - access error no longer _automatically_ fails with a terminating exception
- Fix: Identity Resolution fails when netbios name and domainname don't match.
- Fix: Invoke-DMGroupMembership fails to remove members from different domains.
- Fix: Groups: Fails to rename groups when an OldName exists.
- Fix: Test-DMAccessRule - returns wrong adobject property on testresult of undefined access rules (cosmetic error only)
- Fix: Group Membership - fails to remove group members when using credentials
- Fix: Group Membership - silently fails to remove cross-domain memberships
- Fix: Identity Resolution - first scan against a forest will cache a bad domain object if the searched domain is not accessible with destination domain credentials.
- Fix: Users - inconsistent name matching could lead to unexpected delete generation when Name and SamAccountName mismatch

## 1.1.27 (2020-03-02)

- New: Group Policy Permissions can now be defined as configuration.
- New: Group Policy Permission Filters can be defined, dynamically applying configuration.
- Upd: Name mapping: %DomainSID% and %RootDomainSID% are now available as placeholders.
- Fix: Unregister-DMGPLink no longer retains empty OUs

## 1.0.22 (2020-02-18)

- Upd: Invoke-DMGroupPolicy - error messages now include policy name in their onscreen display as well.
- Fix: Set-DMContentMode will now actually clear property when given an empty array.
- Fix: Unregister-DMAccessRule will no longer complain about invalid types
- Fix: Unregister-DMGroupMembership will no longer refuse to unregister foreignSecurityPrincipals or empty groups.
- Fix: Name resolution no longer causes errors on empty strings.
- Fix: Invoke-DMUser - Changing the surname property no longer errors.
- Fix: Test-DMGPLink would fail with an indexing error in some cases.
- Fix: Unregister-DMAccessRule - prevent accidentally hiding remaining access rules when calling Get-DMAccessRule.
- Fix: Unregister-DMGroupMembership - deleting the last membership from a group fails to remove group entry, causing the setting to switch to "This group should be empty", not "Don't manage the group".
- Fix: Invoke-DMGroup - will now correctly update GroupScope.

## 1.0.12 (2020-01-27)

- Metadata update

## 1.0.11 (2019-12-21)

- Initial Release
