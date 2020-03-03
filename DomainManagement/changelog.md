# Changelog

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
