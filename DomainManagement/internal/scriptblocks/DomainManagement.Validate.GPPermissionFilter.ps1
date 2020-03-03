Set-PSFScriptblock -Name 'DomainManagement.Validate.GPPermissionFilter' -Scriptblock {
	$tokens = $null
	$errors = $null
	$null = [System.Management.Automation.Language.Parser]::ParseInput($_, [ref]$tokens, [ref]$errors)

	if ($errors) {
		Write-PSFMessage -Level Warning -String 'Validate.GPPermissionFilter.SyntaxError' -StringValues $_ -ModuleName 'DomainManagement' -FunctionName 'Validate-GPPermissionFilter'
		return $false
	}

	$validTokenTypes = 'Identifier', 'Parameter', 'LParen', 'RParen', 'EndOfInput', 'And', 'Not', 'Or', 'Xor'
	$invalidTokenTypes = $tokens | Where-Object Kind -notin $validTokenTypes | Select-Object -ExpandProperty  Kind -Unique
	if ($invalidTokenTypes) {
		Write-PSFMessage -Level Warning -String 'Validate.GPPermissionFilter.InvalidTokenType' -StringValues $_, ($invalidTokenTypes -join ', ') -ModuleName 'DomainManagement' -FunctionName 'Validate-GPPermissionFilter'
		return $false
	}

	$validParameters = '-and', '-or', '-not', '-xor'
	$invalidParameters = $tokens | Where-Object Kind -eq Parameter | Where-Object Text -notin $validParameters | Select-Object -ExpandProperty Text -Unique
	if ($invalidParameters) {
		Write-PSFMessage -Level Warning -String 'Validate.GPPermissionFilter.InvalidParameters' -StringValues $_, ($invalidParameters -join ', ') -ModuleName 'DomainManagement' -FunctionName 'Validate-GPPermissionFilter'
		return $false
	}

	$validIdentifierPattern = '^[\w\d_]+$'
	$invalidIdentifiers = $tokens | Where-Object Kind -eq Identifier | Where-Object Text -notmatch $validIdentifierPattern | Select-Object -ExpandProperty Text -Unique
	if ($invalidIdentifiers) {
		Write-PSFMessage -Level Warning -String 'Validate.GPPermissionFilter.InvalidIdentifiers' -StringValues $_, ($invalidIdentifiers -join ', ') -ModuleName 'DomainManagement' -FunctionName 'Validate-GPPermissionFilter'
		return $false
	}
	return $true
}