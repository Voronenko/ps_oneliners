#Automated bootstrap file for some activity
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
    $msifile = "c:\some.msi"

    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $msifile, $DataStamp
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
