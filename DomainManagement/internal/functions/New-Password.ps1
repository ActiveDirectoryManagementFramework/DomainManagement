function New-Password
{
	<#
		.SYNOPSIS
			Generate a new, complex password.
		
		.DESCRIPTION
			Generate a new, complex password.
		
		.PARAMETER Length
			The length of the password calculated.
			Defaults to 32

		.PARAMETER AsSecureString
			Returns the password as secure string.
		
		.EXAMPLE
			PS C:\> New-Password

			Generates a new 32v character password.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
	[CmdletBinding()]
	Param (
		[int]
		$Length = 32,

		[switch]
		$AsSecureString
	)
	
	begin
	{
		$characters = @{
			0 = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
			1 = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
			2 = @(0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9)
			3 = @('#','$','%','&',"'",'(',')','*','+',',','-','.','/',':',';','<','=','>','?','@')
			4 = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
			5 = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
			6 = @(0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9)
			7 = @('#','$','%','&',"'",'(',')','*','+',',','-','.','/',':',';','<','=','>','?','@')
		}
	}
	process
	{
		$letters = foreach ($number in (5..$Length)) {
			$characters[(($number % 4) + (0..4 | Get-Random))] | Get-Random
		}
		0,1,2,3 | ForEach-Object {
			$letters += $characters[$_] | Get-Random
		}
		$letters = $letters | Sort-Object { Get-Random }
		if ($AsSecureString) { $letters -join "" | ConvertTo-SecureString -AsPlainText -Force }
		else { $letters -join "" }
	}
}
