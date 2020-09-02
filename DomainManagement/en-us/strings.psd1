# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	
	'Assert-ADConnection.Failed'								    = 'Failed to connect to {0}' # $Server
	
	'Assert-Configuration.NotConfigured'						    = 'No configuration data provided for: {0}' # $Type
	
	'Convert-AccessRule.Identity.ResolutionError'				    = 'Failed to convert identity. This generally means a configuration error, especially when referencing the parent as identity.' # 
	
	'Convert-Principal.Processing'								    = 'Converting principal: {0}' # $Name
	'Convert-Principal.Processing.InputNT'						    = 'Input detected as NT: {0}' # $Name
	'Convert-Principal.Processing.InputSID'						    = 'Input detected as SID: {0}' # $Name
	'Convert-Principal.Processing.NT.LdapFilter'				    = 'Resolving NT identity via AD using the following filter: {0}' # "(samAccountName=$namePart)"
	'Convert-Principal.Processing.NTDetails'					    = 'Resolved NT identity: Domain = {0} | Name = {1}' # $domainPart, $namePart
	
	'General.Invalid.Input'										    = 'Invalid input: {1}! This command only accepts output objects from {0}' # 'Test-DMAccessRule', $testItem
	
	'Get-PermissionGuidMapping.Processing'						    = 'Processing Permission Guids for domain: {0} (This may take a while)' # $identity
	
	'Get-Principal.Resolution.Failed'							    = 'Failed to resolve principal: SID {0} | Name {1} | ObjectClass {2} | Domain {3}' # $Sid, $Name, $ObjectClass, $Domain
	
	'Get-SchemaGuidMapping.Processing'							    = 'Processing Schema Guids for domain: {0} (This may take a while)' # $identity
	
	'Install-GroupPolicy.CopyingFiles'							    = 'Copying GPO files for "{0}"' # $Configuration.DisplayName
	'Install-GroupPolicy.CopyingFiles.Failed'					    = 'Failed to copy the GPO files for "{0}"' # $Configuration.DisplayName
	'Install-GroupPolicy.DeletingImportFiles'					    = 'Deleting the GPO files for "{0}"' # $Configuration.DisplayName
	'Install-GroupPolicy.Importing.RegistryValues'				    = 'Applying registry settings to GPO "{0}"' # $Configuration.DisplayName
	'Install-GroupPolicy.Importing.RegistryValues.Failed'		    = 'Failed to apply registry settings to GPO "{0}": {1} --> {2}' # $Configuration.DisplayName, $registryDatum.Key, $registryDatum.ValueName
	'Install-GroupPolicy.ImportingConfiguration'				    = 'Importing the GPO "{0}" from the defined source files' # $Configuration.DisplayName
	'Install-GroupPolicy.ImportingConfiguration.Failed'			    = 'Failed to impoter the GPO "{0}"' # $Configuration.DisplayName
	'Install-GroupPolicy.ReadingADObject'						    = 'Reading the AD object of the imported GPO: "{0}"' # $Configuration.DisplayName
	'Install-GroupPolicy.ReadingADObject.Failed.Error'			    = 'Failed to access the GPO AD object of "{0}", could not validate creation!' # $Configuration.DisplayName
	'Install-GroupPolicy.ReadingADObject.Failed.NoObject'		    = 'The AD object for GPO "{0}" cannot be found! Please manually verify succcess and troubleshoot the creation process/environment.' # $Configuration.DisplayName
	'Install-GroupPolicy.ReadingADObject.Failed.Timestamp'		    = 'Failed to vallidate import of the GPO "{0}". Its last modified timestamp ({1}) is older than the time the import started ({2}). This would usually be the case when the GPO already existed before the process and the import failed for some reason. Please troubleshoot the GPO creation process and the target environment.' # $Configuration.DisplayName, $policyObject.Modified, $timestamp
	'Install-GroupPolicy.UpdatingConfigurationFile'				    = 'Updating the configuration metadata file for "{0}" on the target domain.' # $Configuration.DisplayName
	'Install-GroupPolicy.UpdatingConfigurationFile.Failed'		    = 'Failed to update the configuration metadata file for "{0}" on the target domain. This will cause the GPO to not register as managed and will be flagged as to update on the next test. Please validate filesystem write access to the targeted GPO.' # $Configuration.DisplayName
	
	'Invoke-Callback.Invoking'									    = 'Executing callback: {0}' # $callback.Name
	'Invoke-Callback.Invoking.Failed'							    = 'Error executing callback: {0}' # $callback.Name
	'Invoke-Callback.Invoking.Success'							    = 'Successfully executed callback: {0}' # $callback.Name
	
	'Invoke-DMAccessRule.Access.Failed'							    = 'Failed to access ACL on {0}' # $testItem.Identity
	'Invoke-DMAccessRule.AccessRule.Create'						    = 'Adding access rule for {0}, granting {1} ({2})' # $changeEntry.Configuration.IdentityReference, $changeEntry.Configuration.ActiveDirectoryRights, $changeEntry.Configuration.AccessControlType
	'Invoke-DMAccessRule.AccessRule.Creation.Failed'			    = 'Failed to create accessrule at {0} for {1}' # $testItem.Identity, $changeEntry.Configuration.IdentityReference
	'Invoke-DMAccessRule.AccessRule.Remove'						    = 'Removing access rule for {0}, granting {1} ({2})' # $changeEntry.ADObject.IdentityReference, $changeEntry.ADObject.ActiveDirectoryRights, $changeEntry.ADObject.AccessControlType
	'Invoke-DMAccessRule.AccessRule.Remove.Failed'				    = 'Failed to removing access rule for {0}, granting {1} ({2}) for unknown reasons (sorry)' # $changeEntry.ADObject.IdentityReference, $changeEntry.ADObject.ActiveDirectoryRights, $changeEntry.ADObject.AccessControlType
	'Invoke-DMAccessRule.ADObject.Missing'						    = 'Cannot process access rules, due to missing AD object: {0}. Please ensure the domain object is created before trying to apply rules to it!' # $testItem.Identity
	'Invoke-DMAccessRule.Processing.Execute'					    = 'Applying {0} out of {1} intended access rule changes' # $testItem.Changed.Count
	'Invoke-DMAccessRule.Processing.Rules'						    = 'Processing {1} access rule changes on {0}' # $testItem.Identity, $testItem.Changed.Count
	
	'Invoke-DMAcl.MissingADObject'								    = 'The target object could not be found: {0}' # $testItem.Identity
	'Invoke-DMAcl.NoAccess'										    = 'Failed to access Acl on {0}' # $testItem.Identity
	'Invoke-DMAcl.OwnerNotResolved'								    = 'Was unable to resolve the current owner ({1}) of {0}' # $testItem.Identity, $testItem.ADObject.GetOwner([System.Security.Principal.SecurityIdentifier])
	'Invoke-DMAcl.ShouldManage'									    = 'The ADObject {0} has no defined ACL state and should either be configured or removed' # $testItem.Identity
	'Invoke-DMAcl.UpdatingInheritance'							    = 'Updating inheritance - Inheritance Disabled: {0}' # $testItem.Configuration.NoInheritance
	'Invoke-DMAcl.UpdatingOwner'								    = 'Granting ownership to {0}' # ($testItem.Configuration.Owner | Resolve-String)
	
	'Invoke-DMDomainData.Invocation.Error'						    = 'An exception was thrown while executing the domain data script "{0}".' # $Name
	'Invoke-DMDomainData.Invocation.Error.Terminate'			    = 'Critical Error: An exception was thrown while executing the domain data script "{0}".' # $Name
	'Invoke-DMDomainData.Script.NotFound'						    = 'Could not find a registered DomainData set with the name "{0}". Be sure to register an appropriate configuration and check for typos.' # $Name
	'Invoke-DMDomainData.Script.NotFound.Error'					    = 'Critical error: Could not find a registered DomainData set with the name "{0}". Be sure to register an appropriate configuration and check for typos.' # $Name
	
	'Invoke-DMDomainLevel.Raise.Level'							    = 'Raising domainlevel to {0}' # $testItem.Configuration.Level
	
	'Invoke-DMGPLink.Delete.AllDisabled'						    = 'Removing all ({0}) policy links (all of which are disabled)' # $countActual
	'Invoke-DMGPLink.Delete.AllEnabled'							    = 'Removing all ({0}) policy links (all of which are enabled)' # $countActual
	'Invoke-DMGPLink.Delete.SomeDisabled'						    = 'Removing all ({0}) policy links' # $countActual
	'Invoke-DMGPLink.New'										    = 'Linking {0} group policies (all new links)' # $countConfigured
	'Invoke-DMGPLink.New.GpoNotFound'							    = 'Unable to find Group POlicy Object: {0}' # (Resolve-String -Text $_.PolicyName)
	'Invoke-DMGPLink.New.NewGPLinkString'						    = 'Finished gPLink string being applied to {0}: {1}' # $ADObject.DistinguishedName, $gpLinkString
	'Invoke-DMGPLink.Update.AllDisabled'						    = 'Updating GPLink - {0} links configured, {1} links present, {2} links present that are not in configuration (All present and undesired links are disabled)' # $countConfigured, $countActual, $countNotInConfig
	'Invoke-DMGPLink.Update.AllEnabled'							    = 'Updating GPLink - {0} links configured, {1} links present, {2} links present that are not in configuration (All present and undesired links are enabled)' # $countConfigured, $countActual, $countNotInConfig
	'Invoke-DMGPLink.Update.GpoNotFound'						    = 'Unable to find Group POlicy Object: {0}' # (Resolve-String -Text $_.PolicyName)
	'Invoke-DMGPLink.Update.NewGPLinkString'					    = 'Finished gPLink string being applied to {0}: {1}' # $ADObject.DistinguishedName, $gpLinkString
	'Invoke-DMGPLink.Update.SomeDisabled'						    = 'Updating GPLink - {0} links configured, {1} links present, {2} links present that are not in configuration' # $countConfigured, $countActual, $countNotInConfig
	
	'Invoke-DMGPPermission.AD.Access.Error'						    = 'Error accessing Active Directory for {0} ({1})' # $testResult, $testResult.ADObject.DistinguishedName
	'Invoke-DMGPPermission.AD.UpdatingPermission'				    = 'Updating {0} permission changes on the AD object' # $testResult.Changed.Count
	'Invoke-DMGPPermission.Gpo.SyncingPermission'				    = 'Making {0} permission changes consistent through the GPO Api' # $testResult.Changed.Count
	'Invoke-DMGPPermission.Invalid.Input'						    = 'The input object was not recognized as a valid test result for Group Policy Permissions: {0}' # $testResult
	'Invoke-DMGPPermission.Result.Access.Error'					    = 'The test for {0} failed, due to access error during the test phase!' # $testResult.Identity
	'Invoke-DMGPPermission.WinRM.Failed'						    = 'Failed to connect to {0}' # $computerName
	
	'Invoke-DMGroup.Group.Create'								    = 'Creating active directory group' # 
	'Invoke-DMGroup.Group.Create.OUExistsNot'					    = 'Cannot create group {1} : Path does not exist: {0}' # $targetOU, $testItem.Identity
	'Invoke-DMGroup.Group.Delete'								    = 'Deleting active directory group' # 
	'Invoke-DMGroup.Group.InvalidScope'							    = 'Invalid scope defined for {0}: {1} is not a legal group scope.' # $testItem, $targetScope
	'Invoke-DMGroup.Group.Move'									    = 'Moving active directory group to {0}' # $targetOU
	'Invoke-DMGroup.Group.MultipleOldGroups'					    = 'Cannot rename group to {0}: More than one group exists owning one of the previous names. Conflicting groups: {1}. Please investigate and manually resolve.' # $testItem.Identity, ($testItem.ADObject.Name -join ', ')
	'Invoke-DMGroup.Group.Rename'								    = 'Renaming active directory group to {0}' # (Resolve-String -Text $testItem.Configuration.Name)
	'Invoke-DMGroup.Group.Update'								    = 'Updating {0} on active directory group' # ($changes.Keys -join ", ")
	'Invoke-DMGroup.Group.Update.OUExistsNot'					    = 'Cannot move active directory group {0} - OU does not exist: {1}' # $testItem.Identity, $targetOU
	'Invoke-DMGroup.Group.Update.Scope'							    = 'Updating the group scope of {0} from {1} to {2}' # $testItem, $testItem.ADObject.GroupScope, $targetScope
	
	'Invoke-DMGroupMembership.GroupMember.Add'					    = 'Adding member to {0}' # $testItem.ADObject.Name
	'Invoke-DMGroupMembership.GroupMember.Remove'				    = 'Removing member from {0}' # $testItem.ADObject.Name
	'Invoke-DMGroupMembership.GroupMember.RemoveUnidentified'	    = 'Removing unidentified foreign security principal from {0}' # $testItem.ADObject.Name
	'Invoke-DMGroupMembership.Unidentified'						    = 'Could not identify current group member: {0}' # $testItem.Identity
	'Invoke-DMGroupMembership.Unresolved'						    = 'Could not identify required group member: {0}' # $testItem.Identity
	
	'Invoke-DMGroupPolicy.Delete'								    = 'Deleting group policy object: {0}.' # $testItem.Identity
	'Invoke-DMGroupPolicy.Install.OnBadRegistry'				    = 'Re-applying GPO "{0}" after detecting a registry setting that is not as defined.' # $testItem.Identity
	'Invoke-DMGroupPolicy.Install.OnConfigError'				    = 'Re-applying GPO "{0}" after failing to read its configuration' # $testItem.Identity
	'Invoke-DMGroupPolicy.Install.OnManage'						    = 'Re-Applying GPO "{0}" for the first time to bring it under management' # $testItem.Identity
	'Invoke-DMGroupPolicy.Install.OnModify'						    = 'GPO "{0}" was modified outside this system, re-applying GPO' # $testItem.Identity
	'Invoke-DMGroupPolicy.Install.OnNew'						    = 'GPO "{0}" not found in AD, creating new GPO' # $testItem.Identity
	'Invoke-DMGroupPolicy.Install.OnUpdate'						    = 'New GPO definition available, updating GPO "{0}"' # $testItem.Identity
	'Invoke-DMGroupPolicy.Remote.WorkingDirectory.Failed'		    = 'Failed to create working directory on {0}. This is required for importing GPOs' # $computerName
	'Invoke-DMGroupPolicy.Skipping.InCriticalState'				    = 'Critical error validating {0}. The GPO will be skipped, please manually verify the GPO and bring it into a supportable state.' # $testItem.Identity
	'Invoke-DMGroupPolicy.WinRM.Failed'							    = 'Failed to connect to "{0}" via WinRM/PowerShell Remoting.' # $computerName
	
	'Invoke-DMObject.Object.Change'								    = 'Updating the properties {0}' # ($testItem.Changed -join ", ")
	'Invoke-DMObject.Object.Create'								    = 'Creating {0} object in {1}' # $testItem.Configuration.ObjectClass, $testItem.Identity
	
	'Invoke-DMOrganizationalUnit.OU.Create'						    = 'Creating organizational unit' # 
	'Invoke-DMOrganizationalUnit.OU.Create.OUExistsNot'			    = 'Cannot create OU {1}, parent OU does not exist: {0}' # $targetOU, $testItem.Identity
	'Invoke-DMOrganizationalUnit.OU.Delete'						    = 'Deleting organizational unit' # 
	'Invoke-DMOrganizationalUnit.OU.Delete.HasChildren'			    = 'Skipping the deletion of {0} - OU has {1} childitem(s) that would also be deleted. Please manually handle these before proceeding.' # $testItem.ADObject.DistinguishedName, ($childObjects | Measure-Object).Count
	'Invoke-DMOrganizationalUnit.OU.Delete.NoAction'			    = 'Skipping the deletion of {0} - OU deletion has been disabled' # $testItem.Identity
	'Invoke-DMOrganizationalUnit.OU.MultipleOldOUs'				    = 'Cannot rename organizational unit to {0}: More than one organizational unit exists owning one of the previous names. Conflicting organizational unit: {1}. Please investigate and manually resolve.' # $testItem.Identity, ($testItem.ADObject.Name -join ', ')
	'Invoke-DMOrganizationalUnit.OU.Rename'						    = 'Renaming organizational unit to {0}' # (Resolve-String -Text $testItem.Configuration.Name)
	'Invoke-DMOrganizationalUnit.OU.Update'						    = 'Updating {0} on organizational unit' # ($changes.Keys -join ", ")
	
	'Invoke-DMPasswordPolicy.PSO.Create'						    = 'Creating new PSO object' # 
	'Invoke-DMPasswordPolicy.PSO.Delete'						    = 'Deleting PSO object' # 
	'Invoke-DMPasswordPolicy.PSO.Update'						    = 'Updating properties: {0}' # ($changes.Keys -join ", ")
	'Invoke-DMPasswordPolicy.PSO.Update.GroupAssignment'		    = 'Assigning PSO to {0}' # (Resolve-String -Text $testItem.Configuration.SubjectGroup)
	
	'Invoke-DMUser.User.Create'									    = 'Creating active directory user' # 
	'Invoke-DMUser.User.Create.OUExistsNot'						    = 'Cannot create user {1} : Path does not exist: {0}' # $targetOU, $testItem.Identity
	'Invoke-DMUser.User.Delete'									    = 'Deleting active directory user' # 
	'Invoke-DMUser.User.Move'									    = 'Moving active directory user to {0}' # $targetOU
	'Invoke-DMUser.User.MultipleOldUsers'						    = 'Cannot rename user to {0}: More than one user exists owning one of the previous names. Conflicting users: {1}. Please investigate and manually resolve.' # $testItem.Identity, ($testItem.ADObject.Name -join ', ')
	'Invoke-DMUser.User.Rename'									    = 'Renaming active directory user to {0}' # (Resolve-String -Text $testItem.Configuration.SamAccountName)
	'Invoke-DMUser.User.Update'									    = 'Updating {0} on active directory user' # ($changes.Keys -join ", ")
	'Invoke-DMUser.User.Update.EnableDisable'					    = 'Changing user enabled state to: {0}' # $testItem.Configuration.Enabled
	'Invoke-DMUser.User.Update.OUExistsNot'						    = 'Cannot move active directory group {0} - user does not exist: {1}' # $testItem.Identity, $targetOU
	'Invoke-DMUser.User.Update.PasswordNeverExpires'			    = 'Changing user password non-expiration to: {0}' # $testItem.Configuration.PasswordNeverExpires
	
	'Remove-GroupPolicy.Deleting'								    = 'Deleting GPO: {0}' # $ADObject.DisplayName
	'Remove-GroupPolicy.Deleting.Failed'						    = 'Failed to delete GPO: {0}' # $ADObject.DisplayName
	
	'Resolve-ContentSearchBase.Exclude.NotFound'				    = 'Failed to find excluded ou/container: {0}' # $item.Name
	'Resolve-ContentSearchBase.Include.NotFound'				    = 'Failed to find included ou/container: {0}' # $item.Name
	'Resolve-ContentSearchBase.Searchbase.Found'				    = 'Resolved searchbase in {2}: {0} | {1}' # $searchBase.SearchScope, $searchBase.SearchBase, $script:domainContext.Fqdn
	
	'Resolve-Identity.ParentObject.NoSecurityPrincipal'			    = 'Error processing parent of {0} : {1} of type {2} is no legal security principal and cannot be assigned permissions!' # $ADObject, $parentObject.Name, $parentObject.ObjectClass
	
	'Resolve-PolicyRevision.Result.ErrorOnConfigImport'			    = 'Failed to read configuration for {0}: {1}' # $Policy.DisplayName, $result.Error.Exception.Message
	'Resolve-PolicyRevision.Result.PolicyError'					    = 'Policy object not found in filesystem: {0}. Check existence and permissions!' # $Policy.DisplayName
	'Resolve-PolicyRevision.Result.Result.SuccessNotYetManaged'	    = 'Policy found: {0}. Has not yet been managed, will need to be overwritten.' # $Policy.DisplayName
	'Resolve-PolicyRevision.Result.Success'						    = 'Found GPO: {0}. Last export ID: {1}. Last updated on {2}' # $Policy.DisplayName, $result.ExportID, $result.Timestamp
	
	'Set-DMRedForestContext.Connection.Failed'					    = 'Failed to connect to {0}' # $Server
	
	'Test-DMAccessRule.DefaultPermission.Failed'				    = 'Failed to retrieve default permissions from Schema when connecting to {0}' # $Server
	'Test-DMAccessRule.NoAccess'								    = 'Failed to access {0}' # $resolvedPath
	
	'Test-DMAcl.ADObjectNotFound'								    = 'The target object could not be found: {0}' # $resolvedPath
	'Test-DMAcl.NoAccess'										    = 'Failed to access Acl on {0}' # $resolvedPath
	'Test-DMAcl.OwnerDomainNotResolved'							    = 'Failed to resolve the domain of the owner of {0}' # $resolvedPath
	'Test-DMAcl.OwnerPrincipalNotResolved'						    = 'Failed to resolve the identity of the owner of {0}' # $resolvedPath
	
	'Test-DMGPLink.OUNotFound'									    = 'Failed to find the configured OU: {0} - Please validate your OU configuration and bring your OU estate into the desired state first!' # $resolvedName
	
	'Test-DMGPPermission.Filter.Path.DoesNotExist.SilentlyContinue' = 'The searchbase for the filter condition {0} could not be found. This however was defined as optional and is not an error: {1}' # $Condition.Name, $searchBase
	'Test-DMGPPermission.Filter.Path.DoesNotExist.Stop'			    = 'The searchbase {1} for the filter condition {0} could not be found. A consistent picture of the desired permission configuration is impossible, terminating!' # $searchBase
	'Test-DMGPPermission.Filter.Result'							    = 'Resolved filter condition {0} to GPOs: {1}' # $key, ($filterToGPOMapping[$key].DisplayName -join ', ')
	'Test-DMGPPermission.Identity.Resolution.Error'				    = 'Failed to resolve the identity of an intended privilege-holder on {0}. Cancelling the processing for this GPO, as correct access configuration is not assured.' # $adObject.DisplayName
	'Test-DMGPPermission.Validate.MissingFilterConditions'		    = 'Critical configuration error: Not all referenced Group Policy Permission filter-conditions were defined. Undefined conditions: {0}' # ($missingConditions -join ", ")
	'Test-DMGPPermission.WinRM.Failed'							    = 'Failed to connect to {0}' # $computerName
	
	'Test-DMGPRegistrySetting.TestResult'						    = 'Finished testing GP Registry settings against {0}. Success: {1} | Status: {2}' # $resolvedName, $result.Success, $result.Status
	'Test-DMGPRegistrySetting.WinRM.Failed'						    = 'Failed to connect to {0}' # $parameters.Server
	
	'Test-DMGroupMembership.Assignment.Resolve.Connect'			    = 'Failed to resolve {2} {1} - Could not connect to {0}' # (Resolve-String -Text $assignment.Domain), (Resolve-String -Text $assignment.Name), $assignment.ItemType
	'Test-DMGroupMembership.Assignment.Resolve.NotFound'		    = 'Successfully queried domain "{0}", but the member {1} of type {2} could not be found' # (Resolve-String -Text $assignment.Domain), (Resolve-String -Text $assignment.Name), $assignment.ItemType
	'Test-DMGroupMembership.Group.Access.Failed'				    = 'Failed to access group {0} in target domain, cannot compare its members with the configured state.' # $resolvedGroupName
	
	'Test-DMGroupPolicy.ADObjectAccess.Failed'					    = 'Failed to access GPO active directory object for: {0}' # $managedPolicy.DistinguishedName
	'Test-DMGroupPolicy.DomainData.Failed'						    = 'Failed to retrieve the domain-specific data for the following sources: {0}' # ($domainDataNames -join ",")
	'Test-DMGroupPolicy.PolicyRevision.Lookup.Failed'			    = 'Failed to resolve GPO in AD: {0}' # $managedPolicies.DisplayName
	'Test-DMGroupPolicy.WinRM.Failed'							    = 'Failed to connect to "{0}" via WinRM/PowerShell Remoting.' # $computerName
	
	'Test-DMObject.ADObject.Access.Error'						    = 'Failed to access {0} while retrieving {1}' # $resolvedPath, ($objectDefinition.Attributes.Keys -join ",")
	'Test-DMObject.ADObject.Access.Error2'						    = 'Failed to access {0}' # $resolvedPath
	
	'Test-DMPasswordPolicy.SubjectGroup.NotFound'				    = 'Failed to find the group {0}, which should be granted permission to the Finegrained Password Policy {1}' # $groupName, $resolvedName
	
	'Validate.DomainData.Pattern'								    = 'Invalid input: {0}. A domain data name must only consist of numbers, letters and underscore.' # <user input>, <validation item>
	'Validate.GPPermissionFilter'								    = 'Invalid GP Permission filter: {0}' # <user input>, <validation item>
	'Validate.GPPermissionFilter.InvalidIdentifiers'			    = 'Invalid filter elements (filter names): {1}. Filters can only consist of letters, numbers and underscore. Filter: {0}' # $_, ($invalidIdentifiers -join ', ')
	'Validate.GPPermissionFilter.InvalidParameters'				    = 'Invalid filter elements (parameters): {1}. Only the four basic logical parameters are allowed: -and, -or, -not, -xor! Filter: {0}' # $_, ($invalidParameters -join ', ')
	'Validate.GPPermissionFilter.InvalidTokenType'				    = 'Invalid filter element types: {1}. Only parenthesis, filter names and logical operators are allowed! Filter: {0}' # $_, ($invalidTokenTypes -join ', ')
	'Validate.GPPermissionFilter.SyntaxError'					    = 'General syntax error in your filter string: {0}' # $_
	'Validate.Identity'											    = 'Invalid identity: {0} - Either specify a SID, a name in the format "<domain>\<name>" or in the format "<name>@<domainfqdn>"' # <user input>, <validation item>
	'Validate.Name.Pattern'										    = 'Invalid input: {0}. The name tag must start with a "%", end in a "%" and contain only letters, underscore and numbers inbetween.' # <user input>, <validation item>
	'Validate.PermissionFilterName'								    = 'Invalid input: {0}. GP Permission Filter names may only consist of letters, numbers and underscore characters.' # <user input>, <validation item>
	'Validate.TypeName.AccessRule.Failed'						    = 'The input object {0} could not be verified as a "DomainManagement.AccessRule" object.' # <user input>, <validation item>
}