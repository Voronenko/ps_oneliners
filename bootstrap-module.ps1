#Download and Run MSI package for Automated install
new-module -name CustomInstaller -scriptblock {
    [Console]::OutputEncoding = New-Object -typename System.Text.ASCIIEncoding
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'

    function Install-Project {
        param (
            [Parameter(Mandatory = $true)]
            [string]$requiredParam = "THIS_PARAM_IS_REQUIRED",
            [string]$optionalParamWithDefault = "https://github.com/Voronenko/ps_oneliners",
            [string]$optionalParamFromEnvironment = $env:computername
        )


        Write-Host "About to execute some bootstrap logic with params $requiredParam $optionalParamWithDefault on $optionalParamFromEnvironment"

        Function Download_MSI_Installer {
            Write-Host  "For example, we download smth from internet"    
            # Write-Host "About to download $uri to $out"
            # Invoke-WebRequest -uri $uri -OutFile $out
            # $msifile = Get-ChildItem -Path $out -File -Filter '*.ms*'
            # Write-Host  MSI $msifile "
        }

        Function Install_Script {
            # $msifile = Get-ChildItem -Path $out -File -Filter '*.ms*'
            # $FileExists = Test-Path $msifile -IsValid

            $DataStamp = get-date -Format yyyyMMddTHHmmss
            $logFile = '{0}-{1}.log' -f $msifile.fullname, $DataStamp
            $MSIArguments = @(
                "/i"
                ('"{0}"' -f $msifile)
                "/qn"
                "/norestart"
                "/L*v"
                $logFile
                " REQUIRED_PARAM=$requiredParam OPTIONAL_PARAM_WITH_DEFAULT=$optionalParamWithDefault OPTIONAL_PARAM_FROM_ENVIRONMENT=$optionalParamFromEnvironment"
            )
            write-host "About to install msifile with arguments "$MSIArguments
            # If ($FileExists -eq $True) {
            #     Start-Process "msiexec.exe" -ArgumentList $MSIArguments -passthru | wait-process
            #     Write-Host "Finished msi "$msifile
            # }

            # Else {Write-Host "File $out doesn't exists - failed to download or corrupted. Please check."}
        }

        Download_MSI_Installer
        Install_Script        

    }

    set-alias install -value Install-Project

    export-modulemember -function 'Install-Project' -alias 'install'

}
