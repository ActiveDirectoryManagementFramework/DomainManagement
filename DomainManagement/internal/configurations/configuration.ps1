<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'DomainManagement' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'DomainManagement' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'DomainManagement' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -Module 'DomainManagement' -Name 'ServiceAccount.SkipKdsCheck' -Value $false -Initialize -Validation bool -Description 'Whether the check for a KDS Root Key should be skipped. By default, Invoke-DMServiceAccount will validate the necessary key exists before creating gMSA. However, reading the key requires Domain Admin privileges, which may not always be available. Skipping the check will cause gMSA creation to fail with an error, if the KDSRootKey does not yet exist.'
Set-PSFConfig -Module 'DomainManagement' -Name 'AccessRules.Remove.Option2' -Value $false -Initialize -Validation bool -Description 'In some environments, the default way of removing access rules have proved to not work out. Using this option enables a second way for removing access rules.'

#$coreCount = $env:NUMBER_OF_PROCESSORS
#if (-not $coreCount) { $coreCount = 4 }
# Should not use more than 4 for now, until retries are configurable
Set-PSFConfig -Module 'DomainManagement' -Name 'AccessRules.Threads' -Value 4 -Initialize -Validation integerpositive -Description 'The number of runspaces to use for access rule processing. This is an in-memory operation, using more cores than available is disadviced.'
# Should be disabled by default, as runspace feature not quite stable yet
Set-PSFConfig -Module 'DomainManagement' -Name 'AccessRules.Parallelize' -Value $false -Initialize -Validation bool -Description 'Whether to process AccessRules with multiple runspaces (recommended for performance reasons).'