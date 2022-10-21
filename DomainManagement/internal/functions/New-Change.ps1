function New-Change {
	<#
	.SYNOPSIS
		Create a new change object.
	
	.DESCRIPTION
		Create a new change object.
		Used for test results in cases where no specialized change objects are intended.
		Mostly used from the internal Compare-Property command.
	
	.PARAMETER Property
		The property being updated
	
	.PARAMETER OldValue
		The previous value the property had
	
	.PARAMETER NewValue
		The new value the property should receive
	
	.PARAMETER Identity
		Identity of the object being updated
	
	.PARAMETER Type
		The object/component type of the object being changed
	
	.EXAMPLE
		PS C:\> New-Change -Property Path -OldValue $adObject.DistinguishedName -NewValue $path -Identity $adObject -Type Object

		Creates a new change object for the path of an object
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Property,

		$OldValue,

		$NewValue,

		[string]
		$Identity,
		
		[string]
		$Type = 'Unknown'
	)

	$change = [PSCustomObject]@{
		PSTypeName = "DomainManagement.$Type.Change"
		Property   = $Property
		Old        = $OldValue
		New        = $NewValue
		Identity   = $Identity
	}
	Add-Member -InputObject $change -MemberType ScriptMethod -Name ToString -Value { '{0} -> {1}' -f $this.Property, $this.New } -Force -PassThru
}