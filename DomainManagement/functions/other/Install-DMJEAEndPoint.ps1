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
		Name of remote endpoint computer name.
	
	.PARAMETER ConfigurationName
        JEA Endpoint configuration name
        
    .PARAMETER JEAIdentity
        Group/user/gMSA account used in configuration.
		
	.EXAMPLE
		PS C:\> Install-DMJEAEndpoint -ComputerName JEAServer.contoso.com

		Returns the default permissions for a user.
	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [CmdletBinding()]
    Param (
        [PSFComputer] $ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Mandatory = $true)]
        [string] $JEAIdentity,

        [PSCredential]
        $Credential
    )

    begin {
        #region: Utility functions
        function New-Session {
            [CmdletBinding()]
            param ([PSFComputer] $ComputerName, [PSCredential] $Credential)
            
            [PSFComputer] $result = $null
            # Are we working on local host?
            if ($ComputerName.IsLocalhost) {
                $result = $ComputerName
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
        function CopyZipFile {
            [CmdletBinding()]
            Param ([PSFComputer] $ComputerName, $SourceZipFilePath)
            
            if ($ComputerName.IsLocalhost) {
                #Running on localhost 
                $result = $SourceZipFilePath
            }
            else {              
                $result = Invoke-Command -Session $ComputerName.InputObject -ScriptBlock { "$env:windir\Temp\JEA_DMJEAModule.zip" }
                Copy-Item -ToSession $ComputerName.InputObject -Path $SourceZipFilePath -Destination $result -ErrorAction Stop
            } 
            $result
        }
        function Register-JEAEndpoint {
            [CmdletBinding()]
            Param ([PSFComputer] $ComputerName, $JEAIdentity, $ZipFileLocation)
    
            $installResult = [PSCustomObject]@{
                Success = $true
                Error   = $null
            }
            $installResult = Invoke-PSFCommand -ComputerName $ComputerName -ArgumentList $ZipFileLocation, $JEAIdentity  -scriptblock {                
                Param(
                    $ZipFilePath, $JEAIdentity
                )
                $result = [PSCustomObject]@{
                    Success = $true
                    Error   = $null
                }
                try {
                            
                    $jeaModuleDestination = "$env:ProgramFiles\WindowsPowerShell\Modules\"
                    $jeaModuleSessionConfigurationPath = "$jeaModuleDestination\JEA_DMJEAModule\1.0.0\sessionconfiguration.pssc"
                            
                    Expand-Archive -Path $ZipFilePath  -DestinationPath $jeaModuleDestination -Force -ErrorAction 'Stop'
                            
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
                Write-PSFMessage -Level Verbose -Message "The bomb has been planted!"
                Remove-PSSession -Session $ComputerName.InputObject -ErrorAction Ignore            
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
                    
                    Remove-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_DMJEAModule" -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item "$env:windir\Temp\JEA_DMJEAModule.zip" -Force -ErrorAction SilentlyContinue
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
        $SourceZipFilePath = "$script:moduleroot\internal\JEAEndpoint\JEA_DMJEAModule.zip" 
    }
        
    process {
        $parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.NewSession' -ActionStringValues $ComputerName.InputObject -Target $ComputerName.InputObject -ScriptBlock {
            
            $parameters.ComputerName = New-Session @parameters
        
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -whatif:$false -Confirm:$false
        if (Test-PSFFunctionInterrupt) { return } 

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.CopyZippedModule' -Target $ComputerName.ComputerName -ScriptBlock {   
            $zipFileLocation = CopyZipFile -ComputerName $parameters.ComputerName -SourceZipFilePath $SourceZipFilePath 
   
        } -EnableException $EnableException -PSCmdlet $PSCmdlet
        if (Test-PSFFunctionInterrupt) { return } 

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.RunScript' -Target $ComputerName.ComputerName  -ScriptBlock {        
            Register-JEAEndpoint -ComputerName $parameters.ComputerName -JEAIdentity $JEAIdentity -ZipFileLocation $zipFileLocation
        } -EnableException $EnableException -PSCmdlet $PSCmdlet 
        if (Test-PSFFunctionInterrupt) { return } 

        $parameters.ComputerName = $ComputerName.ComputerName

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.NewSession' -ActionStringValues $ComputerName.InputObject -Target $ComputerName.InputObject -ScriptBlock {
            
            $parameters.ComputerName = New-Session @parameters
        
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -whatif:$false -Confirm:$false -RetryCount 3 -RetryWait 3s 
        if (Test-PSFFunctionInterrupt) { return } 

        Invoke-PSFProtectedCommand -ActionString 'Install-DMJEAEndPoint.ConfirmInstallation' -ActionStringValues $ComputerName.InputObject -Target $ComputerName.InputObject -ScriptBlock {
            
            $installResult = Test-Installation -ComputerName $parameters.ComputerName
        
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -whatif:$false -Confirm:$false
        if (Test-PSFFunctionInterrupt) { return } 
        
        
        if ($installResult.success) {
            # Output 
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
        if (-Not $ComputerName.IsLocalhost) { Remove-PSSession -Session $parameters.ComputerName.InputObject -ErrorAction Ignore -WhatIf:$false -Confirm:$false }
    }
}