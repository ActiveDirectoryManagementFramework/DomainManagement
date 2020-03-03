function Get-DMContentMode
{
	<#
	.SYNOPSIS
		Returns the current domain content mode / content handling policy.
	
	.DESCRIPTION
		Returns the current domain content mode / content handling policy.
		For more details on the content mode and how it behaves, see the description on Set-DMContentMode
	
	.EXAMPLE
		PS C:\> Get-DMContentMode

		Returns the current domain content mode / content handling policy.
	#>
	[CmdletBinding()]
	Param ()
	
	process
	{
		$script:contentMode
	}
}
