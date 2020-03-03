function Unregister-DMOrganizationalUnit
{
	<#
	.SYNOPSIS
		Removes an organizational unit from the list of registered OUs.
	
	.DESCRIPTION
		Removes an organizational unit from the list of registered OUs.
		This effectively removes it from the definition of the desired OU state.
	
	.PARAMETER Name
		The name of the OU to unregister.
	
	.PARAMETER Path
		The path of the OU to unregister.
	
	.PARAMETER DistinguishedName
		The full Distinguished name of the OU to unregister.
	
	.EXAMPLE
		PS C:\> Get-DMOrganizationalUnit | Unregister-DMOrganizationalUnit

		Removes all registered organizational units from the configuration
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'DN')]
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true, ParameterSetName = 'NamePath')]
		[string]
		$Name,

		[Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true, ParameterSetName = 'NamePath')]
		[string]
		$Path,

		[Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true, ParameterSetName = 'DN')]
		[string]
		$DistinguishedName
	)
	
	process
	{
		if ($DistinguishedName) {
			$script:organizationalUnits.Remove($DistinguishedName)
		}
		if ($Name) {
			$distName = 'OU={0},{1}' -f $Name, $Path
			$script:organizationalUnits.Remove($distName)
		}
	}
}
