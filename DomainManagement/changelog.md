# Changelog

## 1.8.180 (2022-10-21)

- New: Component: WmiFilter - manage WMI Filters in active directory
- Upd: Set-DMContentMode - added parameter RemoveUnknownWmiFilter to define how unknown WMI filters are handled
- Upd: ACL - renamed test result "Changed" to "Update" to be in line with other test result types.
- Upd: ACL - Improved user experience of the test results / more useful change information
- Upd: Access Rules - Improved user experience of the test results / more useful change information
- Upd: GPLink - renamed test result "New" to "Create" to be in line with other test result types.
- Upd: GPLink - Improved user experience of the test results / more useful change information
- Upd: GPLink - add change information when creating first links to an OU
- Upd: GPO Owner - Improved user experience of the test results / more useful change information
- Upd: GPPermission - Improved user experience of the test results / more useful change information
- Upd: Group Policies - Improved user experience of the test results / more useful change information
- Upd: Group Policies - Standardized test result codes, merging most update-related codes into the Update result code and adding the details to the Changed property
- Upd: Group Membership - Identity of test results now more readable
- Upd: Group Membership - renamed test result "Remove" to "Delete" to be in line with other test result types
- Upd: Group Membership - Improved user experience of the test results / more useful change information
- Upd: Group - renamed test result "ShouldDelete" to "Delete"  to be in line with other test result types
- Upd: Group - renamed test result "Changed" to "Update"  to be in line with other test result types
- Upd: Group - Improved user experience of the test results / more useful change information
- Upd: Object - Improved user experience of the test results / more useful change information
- Upd: Organizational Unit - renamed test result "Changed" to "Update"  to be in line with other test result types
- Upd: Organizational Unit - Improved user experience of the test results / more useful change information
- Upd: Organizational Unit - the "Description" property is now optional and may be left empty in configuration
- Upd: Password Policy - renamed test result "ShouldDelete" to "Delete" to be in line with other test result types
- Upd: Password Policy - renamed test result "ConfigurationOnly" to "Create" to be in line with other test result types
- Upd: Password Policy - renamed test result "Changed" to "Update" to be in line with other test result types
- Upd: Password Policy - Improved user experience of the test results / more useful change information
- Upd: User - Improved user experience of the test results / more useful change information
- Fix: Group Membership - Identity for "Add" operation now includes actual information
- Fix: Group Membership - Will always try to add and remove all members
- Fix: GPO Owner - test will not fail correctly when the intended owner cannot be resolve and still generate an Update action

## 1.7.150 (2022-09-16)

- Upd: GroupPolicy - New state for group policies that are both out of date and have been modified outside of the system
- Upd: Organizational Units - TestResults with the DELETE action now show the full DN as identity
- Upd: Domain Level - Adding support to accept test results via pipeline for consistency reasons
- Fix: Service Accounts - Modifying the "KerberosEncryptionType" property of existing accounts fails
- Fix: Group Members - Identity fails to include member when trying to remove foreign security principals

## 1.7.145 (2022-03-18)

- New: Component "Group Policy Ownership"
- Upd: AccessRules - Improved initial rights mapping performance
- Upd: AccessRules - Implemented restoration of default access rules that had been deleted
- Upd: AccessRules - Added "NoFixConfig" property to disable the FixConfig result for a given configuration entry
- Upd: AccessRules - Added default permission mappings for explicit diversions from the schema default in the Context default-set.
- Upd: Acl - Implemented support for disabling inheritance
- Upd: GPLink - Supports defining the enablement state
- Fix: AccessRules - Explicit rule deletion would only delete first access rule found on object if undesirable
- Fix: AccessRules - Fails to show "FixConfig" test result, when configuring a default access rule
- Fix: Service Accounts - when renaming account, also tries to delete it
- Fix: Service Accounts - might be created with bad SamAccountNames in some situations
- Fix: Service Accounts - bad config/ad object matching might lead to wrong intended changes
- Fix: Principal Resolution - fails to search for samAccountName
- Fix: BuiltIn account detection in a German-languaged domain

## 1.6.131 (2021-07-13)

- Upd: AccessRules - added "Present" configuration, allowing explicit delete actions as well as optional rule pressence
- Fix: Test-DMAccessRule - fixed unintended command interruption when Identity on AD object could not be unresolved

## 1.6.129 (2021-05-28)

- Upd: Group Memberships - can now assign Object Categories
- Upd: Group Memberships - can now assign gMSAs as member
- Upd: Service Accounts - can now define supported Kerberos encryption types
- Upd: Service Accounts - added ability to specify previous names, changing a service accounts SamAccountName.
- Upd: Service Accounts - added 'DomainManagement.ServiceAccount.SkipKdsCheck' configuration setting to allow skipping the scan for whether a KDS Rootkey exists.

## 1.6.124 (2021-04-23)

- Upd: Test-DMAcl - removed exclusion for computer objects (and associated types), as ObjectCategory based assignment resolves the original issue.
- Upd: ServiceAccount - updated "Present" to include third option: "undefined"
- Upd: Invoke-DMAccessRule - Improved logging for individual rule changes, now including the full DN of the modified AD object
- Fix: Invoke-DMAccessRule - fails to remove some access rules for unknown reasons
- Fix: Get-DMServiceAccount | Unregister-DMServiceAccount pipelining fails
- Fix: Register-DMObject - registers objects under their name/path combination rather than their identity, breaking processing by Unregister-DMObject on mismatch.

## 1.6.118 (2021-03-04)

- New: Component Exchange - adding capability to define Exchange domain object update level.
- Upd: ServiceAccounts - added support for directly authorizing groups through the new GroupName option, rather than requiring definition of a ObjectCategory for it.
- Upd: Test-DMGPLink - reordered changes to show delete actions first.
- Fix: ServiceAccounts - ignores target domain / credentials for computer resolution
- Fix: ServiceAccounts - name resolution not applied correctly during invocation
- Fix: ServiceAccounts - KDS RootKey generation ignores target domain / server

## 1.5.112 (2021-01-15)

- Upd: Invoke-DMServiceAccount - added option to create a KDS Root Key if needed

## 1.5.111 (2021-01-15)

- New: Component: Service Accounts - manage Group Managed Service Accounts
- New: Command Find-DMObjectCategoryItem - Searches objects that are part of a specified object category.
- Upd: Register-DMObjectCategory - Added SearchBase and SearchScope parameters.
- Upd: Resolve-DMObjectCategory - Added support for Searchbase and Searchscope of object categories.
- Upd: GroupMembership - allowed computer objects
- Upd: Organizational Units - added option for "optional", tolerating an existing OU but not creating it
- Upd: Organizational Units - renamed change type "ConfigurationOnly" to "Create"
- Upd: Organizational Units - renamed change type "ShouldDelete" to "Delete"
- Upd: Users - added option for "optional", tolerating an existing OU but not creating it
- Upd: Users - renamed change type "ConfigurationOnly" to "Create"
- Upd: Users - renamed change type "ShouldDelete" to "Delete"
- Fix: Test-DMGroupMembership - incorrectly reports foreign security principals that were resolved as "unidentified" if another fsp was incorrectly a group member.

## 1.4.99 (2020-12-11)

- Fix: Get-DMGPLink - returns null objects as part of return
- Fix: Unregister-DMGPLink - would not unregister filter-based links

## 1.4.97 (2020-12-11)

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
