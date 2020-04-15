# Changelog

## ???

- New: DomainData Component - allows dynamically gathering domain specific information.
- New: Group Policy Registry Settings Component - allows definining explicit registry settings to deploy using the targete GPO. Tightly integrated into the Group Policy component.
- Upd: User - now supports setting the "Enabled" state.
- Upd: Domain Context - Adding %DomainNetBIOSName% placeholder
- Upd: Names - All placeholders are no longer case sensitive
- Upd: Get-DMObjectDefaultPermission - now returns also the SID of each identity
- Fix: Access Rules - identity reference comparison would rarely fail to match equal identities
- Fix: Access Rules - identity resolution of parents would domain-prefix the netbios name, not the domain name.
- Fix: Access Rules - an unknown privilege (e.g. due to missing Schema Extension) now reports an actionable error cause.
- Fix: Access Rules - broken detection of default permissions in domains where NETBIOS name -ne Domain Name
- Fix: GPPermissions - under rare circumstances would fail due to "unexpected value"
- Fix: GPPermissions - does not remove all cases of FullControl rights that should be removed
- Fix: GPPermissions - cannot downgrade permissions from FullControl to Custom
- Fix: GPPermissions - changing permissions causes the GroupPolicy component to detect a change and flags the policy as modified.
- Fix: Identity Resolution fails when netbios name and domainname don't match.
- Fix: Invoke-DMGroupMembership fails to remove members from different domains.
- Fix: Groups: Fails to rename groups when an OldName exists.
- Fix: Test-DMAccessRule - returns wrong adobject property on testresult of undefined access rules (cosmetic error only)
- Fix: Group Membership - fails to remove group members when using credentials
- Fix: Group Membership - silently fails to remove cross-domain memberships

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
