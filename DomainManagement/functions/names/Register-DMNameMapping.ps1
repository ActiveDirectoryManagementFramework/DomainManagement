function Register-DMNameMapping
{
	<#
		.SYNOPSIS
			Register a new name mapping.
		
		.DESCRIPTION
			Register a new name mapping.
			Mapped names are used for stringr replacement when invoking domain configurations.
		
		.PARAMETER Name
			The name of the placeholder to register.
			This label will be replaced with the content specified in -Value.
			Be aware that all labels must be enclosed in % and only contain letters, underscore and numbers.
		
		.PARAMETER Value
			The value to insert in place of the label.
		
		.EXAMPLE
			PS C:\> Register-DMNameMapping -Name '%ManagementGroup%' -Value 'Mgmt-Team-1234'

			Registers the string 'Mgmt-Team-1234' under the label '%ManagementGroup%'
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidatePattern('^%[\d\w_]+%$', ErrorString = 'DomainManagement.Validate.Name.Pattern')]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Value
	)
	
	process
	{
		$script:nameReplacementTable[$Name] = $Value
		Register-StringMapping -Name $Name -Value $Value
	}
}
