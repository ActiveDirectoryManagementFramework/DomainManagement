function Register-DMGPLink
{
	<#
	.SYNOPSIS
		Registers a group policy link as a desired state.
	
	.DESCRIPTION
		Registers a group policy link as a desired state.
	
	.PARAMETER PolicyName
		The name of the group policy being linked.
		Supports string expansion.
	
	.PARAMETER OrganizationalUnit
		The organizational unit (or domain root) being linked to.
		Supports string expansion.
	
	.PARAMETER Precedence
		Numeric value representing the order it is linked in.
		The lower the number, the higher on the list, the more relevant the setting.
	
	.EXAMPLE
		PS C:\> Get-Content $configPath | ConvertFrom-Json | Write-Output | Register-DMGPLink

		Import all GPLinks stored in the json file located at $configPath.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$PolicyName,

		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('OU')]
		[string]
		$OrganizationalUnit,

		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[int]
		$Precedence
	)
	
	process
	{
		if (-not $script:groupPolicyLinks[$OrganizationalUnit]) {
			$script:groupPolicyLinks[$OrganizationalUnit] = @{ }
		}
		$script:groupPolicyLinks[$OrganizationalUnit][$PolicyName] = [PSCustomObject]@{
			PSTypeName = 'DomainManagement.GPLink'
			PolicyName = $PolicyName
			OrganizationalUnit = $OrganizationalUnit
			Precedence = $Precedence
		}
	}
}
