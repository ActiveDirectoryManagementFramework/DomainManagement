function New-GpoWorkingDirectory
{
	<#
	.SYNOPSIS
		Creates a new temporary folder for GPO import.
	
	.DESCRIPTION
		Creates a new temporary folder for GPO import.
		Used during Invoke-DMGroupPolicy  to ennsure a local working directory.
	
	.PARAMETER Session
		The powershell session to the target server operations are performed on.
	
	.EXAMPLE
		PS C:\> $workingFolder = New-GpoWorkingDirectory -Session $session

		Ensures the working folder exists and stores the session-local path in the $workingFolder variable.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([string])]
	[CmdletBinding()]
	Param (
		[System.Management.Automation.Runspaces.PSSession]
		$Session
	)
	
	process
	{
		try
		{
			Invoke-Command -Session $Session -ScriptBlock {
				if ($env:temp) {
					try {
						$item = New-Item -Path $env:temp -Name DM_GPOImport -ItemType Directory -ErrorAction Stop -Force
						$item.FullName
					}
					catch { throw "Failed to create folder in %temp%: $_" }
				}
				elseif (Test-Path C:\temp) {
					try {
						$item = New-Item -Path C:\temp -Name DM_GPOImport -ItemType Directory -ErrorAction Stop -Force
						$item.FullName
					}
					catch { throw "Failed to create folder in C:\temp: $_" }
				}
				else {
					try {
						$item = New-Item -Path C:\ -Name temp_DM_GPOImport -ItemType Directory -ErrorAction Stop -Force
						$item.FullName
					}
					catch { throw "Failed to create folder in C:\: $_" }
				}
			} -ErrorAction Stop
		}
		catch { throw }
	}
}
