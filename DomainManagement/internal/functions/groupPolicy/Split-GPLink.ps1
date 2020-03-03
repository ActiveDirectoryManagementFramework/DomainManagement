function Split-GPLink {
    <#
    .SYNOPSIS
        Splits up the gPLink string on an AD object.
    
    .DESCRIPTION
        Splits up the gPLink string on an AD object.
        Returns the distinguishedname of the linked policies in the order they are linked.
    
    .PARAMETER LinkText
        The text from the gPLink property
    
    .EXAMPLE
        PS C:\> $adObject.gPLink | Split-GPLink

        Returns the distinguishednames of all linked group policies.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]
        $LinkText
    )
    process
    {
        foreach ($line in $LinkText) {
            $lines = $line -split "\]\[" -replace '\]|\[' -replace '^LDAP://|;\d$'
            foreach ($lineItem in $lines) {
                if ([string]::IsNullOrWhiteSpace($lineItem)) { continue }
                $lineItem
            }
        }
    }
}