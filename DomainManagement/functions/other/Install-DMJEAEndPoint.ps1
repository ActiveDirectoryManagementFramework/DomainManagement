function Install-DMJEAEndPoint {
    <#
	.SYNOPSIS
		Installs a new JEA EndPoint.

	.DESCRIPTION
        Installs a new JEA EndPoint on a target computer.
        This is used when checking AD Object default permissions from different
        forest with a non-domain admin account.
        The EndPoint can be a dedicated computer or a domain controller.

	.PARAMETER ComputerName
        Name of remote endpoint computer name. Default is localhost.
        Although it is supported to provide a WinRM session, during installation the session is broken
        and a new one is created, therefore you need to be using an account with admin privilages on
        remote computer or supply proper credential.

    .PARAMETER Credential
        Credential to use. Must have local administrator permissions.

    .PARAMETER JEAIdentity
        Group/user/gMSA account used in configuration.

	.EXAMPLE
        PS C:\> Install-DMJEAEndpoint -JEAIdentity Domain\username

        Installs JEA endpoint on localhost.

    .EXAMPLE
        PS C:\> Install-DMJEAEndPoint -ComputerName jeaendpoint.contoso.com -JEAIdentity Domain\username -Credential $creds

        Installs JEA endpoint on remote computer using supplied credentials.

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding()]
    Param (
        [PSFComputer] $ComputerName = (Get-CimInstance -ClassName 'win32_computersystem').DNSHostName+"."+(Get-CimInstance -ClassName 'win32_computersystem').Domain, #FQDN

        [PSCredential] $Credential,

        [Parameter(Mandatory = $true)]
        [string] $JEAIdentity

    )

    begin {
        #region: Utility functions
        function New-Session {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
            [CmdletBinding()]
            param ([PSFComputer] $ComputerName, [PSCredential] $Credential)

            [PSFComputer] $result = $null
            # Are we working on local host?
            if ($ComputerName.IsLocalhost) {
                $result = $ComputerName
                Write-PSFMessage -Level Verbose -String 'Install-DMJEAEndPoint.NewSession.LocalHost'
            }
            else {
                if ($ComputerName.Type -ne 'PSSession') {
                    $parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
                    $parameters['ComputerName'] = $ComputerName.InputObject

                    $result = New-PSSession @parameters -ErrorAction Stop
                }
                else { $result = $ComputerName }
            }
            $result
        }
        function Copy-JEAModule {
            [CmdletBinding()]
            Param ([PSFComputer] $ComputerName, $SourceFolderPath)

            if ($ComputerName.IsLocalhost) {
                #Running on localhost
                $modulesRootPath = "$env:ProgramFiles\WindowsPowerShell\Modules\"
                Copy-Item -Path $SourceFolderPath -Destination $modulesRootPath -Recurse -Force -ErrorAction Stop
            }
            else { # Running on remote computer
                $modulesRootPath = Invoke-Command -Session $ComputerName.InputObject -ScriptBlock { "$env:ProgramFiles\WindowsPowerShell\Modules\" }
                Copy-Item -ToSession $ComputerName.InputObject -Path $SourceFolderPath -Destination $modulesRootPath -Recurse -Force  -ErrorAction Stop
            }

        }
        function Register-JEAEndpoint {
            [CmdletBinding()]
            Param ([PSFComputer] $ComputerName, $JEAIdentity)

            $installResult = [PSCustomObject]@{
                Success = $true
                Error   = $null
            }
            $installResult = Invoke-PSFCommand -ComputerName $ComputerName -ArgumentList $JEAIdentity  -scriptblock {
                Param(
                    $JEAIdentity
                )
                $result = [PSCustomObject]@{
                    Success = $true
                    Error   = $null
                }
                try {

                    $jeaModulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\"
                    $jeaModuleSessionConfigurationPath = "$jeaModulePath\JEA_DMJEAModule\1.0.0\sessionconfiguration.pssc"

                    $SessionConfiguration = Get-Content -Path $jeaModuleSessionConfigurationPath -ErrorAction 'Stop'
                    $SessionConfiguration -replace '%JEAIdentity%', $JEAIdentity | Set-Content $jeaModuleSessionConfigurationPath -Force -ErrorAction 'Stop'

                    Import-Module -Name JEA_DMJEAModule -ErrorAction 'Stop'
                    Register-JeaEndpoint_JEA_DMJEAModule -ErrorAction 'Stop' -WarningAction SilentlyContinue

                }
                catch {
                    $result.Success = $false
                    $result.Error = $_
                }
                $result
            } -ErrorAction SilentlyContinue # We expect null output from here if all goes well and the session is broken

            Start-Sleep -Seconds 3 # Wait for the session to report as broken

            if($installResult.Success -or $ComputerName.InputObject.State -eq "Broken"){

                if (-Not $ComputerName.IsLocalhost -and $ComputerName.Type -eq 'PSSession') { #Close any open sessions
                    Write-PSFMessage -Level Verbose -String 'Install-DMJEAEndPoint.RunScript.SessionBroken'
                    Remove-PSSession -Session $ComputerName.InputObject -ErrorAction Ignore -WhatIf:$false -Confirm:$false
                }
            }
            else {throw $installResult.Error}
        }
        function Test-Installation {
            [CmdletBinding()]
            Param ([PSFComputer] $ComputerName)

            $installResult = Invoke-PSFCommand -ComputerName $ComputerName -scriptblock {
                $result = [PSCustomObject]@{
                    Success = $true
                    Error   = $null
                }
                try {
                    if (Get-PSSessionConfiguration -Name 'JEA_DMJEAModule' -ErrorAction Stop) {
                        # Nothing to do, just leave it result.success as $true
                    }

                }
                catch {
                    $result.Success = $false
                    $result.Error = $_
                }
                $result
            }
            if (-Not $installResult.Success) {
                throw $installResult.Error
            }
            $installResult
        }
        #endregion: Utility functions
        $sourceFolderPath = "$script:moduleroot\internal\JEAEndpoint\JEA_DMJEAModule"
    }

    process {
        $parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential

        if ($ComputerName.IsLocalhost) {$parameters.ComputerName = $ComputerName}

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.NewSession' -ActionStringValues $ComputerName.InputObject -Target $ComputerName.InputObject -ScriptBlock {

            $parameters.ComputerName = New-Session @parameters

        } -EnableException $EnableException -PSCmdlet $PSCmdlet -whatif:$false -Confirm:$false
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.CopyModule' -Target $ComputerName.ComputerName -ScriptBlock {
            Copy-JEAModule -ComputerName $parameters.ComputerName -SourceFolderPath $sourceFolderPath

        } -EnableException $EnableException -PSCmdlet $PSCmdlet
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.RunScript' -Target $ComputerName.ComputerName  -ScriptBlock {
            Register-JEAEndpoint -ComputerName $parameters.ComputerName -JEAIdentity $JEAIdentity
        } -EnableException $EnableException -PSCmdlet $PSCmdlet
        if (Test-PSFFunctionInterrupt) { return }

        $parameters.ComputerName = $ComputerName.ComputerName

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.NewSession' -ActionStringValues $ComputerName.InputObject -Target $ComputerName.InputObject -ScriptBlock {

            $parameters.ComputerName = New-Session @parameters

        } -EnableException $EnableException -PSCmdlet $PSCmdlet -whatif:$false -Confirm:$false -RetryCount 3 -RetryWait 3s
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.TestInstallation' -ActionStringValues $ComputerName.InputObject -Target $ComputerName.InputObject -ScriptBlock {

            $installResult = Test-Installation -ComputerName $parameters.ComputerName

        } -EnableException $EnableException -PSCmdlet $PSCmdlet -whatif:$false -Confirm:$false
        if (Test-PSFFunctionInterrupt) { return }


        if ($installResult.success) {
            Write-PSFMessage -Level Verbose -String 'Install-DMJEAEndPoint.Success'
            [PSCustomObject]@{
                PSTypeName             = 'DomainManagement.WinRM.Mode'
                "Mode"                 = 'JEA'
                "JEAConfigurationName" = 'JEA_DMJEAModule'
                "JEAEndpointServer"    = "$ComputerName"
            }
        }
        else {
            throw $installResult.Error
        }

    }

    End {
        if (-Not $ComputerName.IsLocalhost -and $parameters.ComputerName.Type -eq 'PSSession') { #Close any open sessions
            Remove-PSSession -Session $parameters.ComputerName.InputObject -ErrorAction Ignore -WhatIf:$false -Confirm:$false
        }
    }
}