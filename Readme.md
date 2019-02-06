
## Intro

Coming from unix world, I really enjoj so-called one liners - easy to remember commands that do some useful bootstraping.

Few examples from my dotfiles: https://github.com/voronenko/dotfiles

Saying, if I want to configure my favorite shell on some new VPS


```sh

curl -sSL https://bit.ly/getmyshell > getmyshell.sh && chmod +x getmyshell.sh && ./getmyshell.sh
# might be shortened to, if I do not need to inspect shell file contents
curl -sSL https://bit.ly/getmyshell | bash -s

```

or configure my dotfiles configuration on a more permanent box

```sh

curl -sSL https://bit.ly/slavkodotfiles > bootstrap.sh && chmod +x bootstrap.sh
./bootstrap.sh  <optional: simple | full | docker>
```

That approach works pretty well on linux, thus when I have windows related work. I am trying to reuse similar approach.
Few examples from my winfiles:  script below configures my powershell profile on a new windows server, and optionally installs my "swiss knife" set of tools for the windows system.

```ps

Set-ExecutionPolicy Bypass -Scope Process -Force; 
iex ((New-Object System.Net.WebClient).DownloadString('https://bit.ly/winfiles'))
```

Sometimes on Windows it is needed to additionally pre-configure bootstrap script. This article is actually note for myself how to do it quick next time :)

## Challenge definition

Assume we have some bootstrap logic implemented in powershell, uploaded to some public location and we need oneliner for easier install.
For purposes of the demo - that might be script, that installs some custom MSI artifact:

```ps

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
    $logFile = 'somelog-{0}.log' -f $DataStamp
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
```

user can tune following script parameters:

```ps

    [Parameter(Mandatory = $true)]
    [string]$requiredParam = "THIS_PARAM_IS_REQUIRED",
    [string]$optionalParamWithDefault = "https://github.com/Voronenko/ps_oneliners",
    [string]$optionalParamFromEnvironment = $env:computername

```

## Option A - almost manual "bootstrap.ps1 -param value"


```ps

# optional download
(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/Voronenko/ps_oneliners/master/bootstrap.ps1','c:\bootstrap.ps1')
# install with optional overrides
c:\bootstrap.ps1 -requiredParam AAA -optionalParamWithDefault BBB -optionalParamFromEnvironment CCC

```

Validation - no overrides

```
PS C:\> c:\bootstrap.ps1

cmdlet bootstrap.ps1 at command pipeline position 1
Supply values for the following parameters:
requiredParam: RRR
About to execute some bootstrap logic with params RRR https://github.com/Voronenko/ps_oneliners on EC2AMAZ-9A8TRAV
For example, we download smth from internet
About to install msifile with arguments  /i "c:\some.msi" /qn /norestart /L*v c:\some.msi-20190205T221234.log  REQUIRED_PARAM=RRR OPTIONAL_PARAM_WITH_DEFAULT=https://github.com/Voronenko/ps_oneliners OPTIONAL_PARAM_FROM_ENVIRONMENT=EC2AMAZ-9A8TRAV
```

Validation - with overrides

```
PS C:\> c:\bootstrap.ps1 -requiredParam AAA -optionalParamWithDefault BBB -optionalParamFromEnvironment CCC
About to execute some bootstrap logic with params AAA BBB on CCC
For example, we download smth from internet
About to install msifile with arguments  /i "c:\some.msi" /qn /norestart /L*v c:\some.msi-20190205T221400.log  REQUIRED_PARAM=AAA OPTIONAL_PARAM_WITH_DEFAULT=BBB OPTIONAL_PARAM_FROM_ENVIRONMENT=CCC
```

Acceptance: PASSED




## Option B - X-Liner from pre-downloaded script


Put overrides only into $overrideParams , other will be picked up from default values in install script.
Pros - you can detect and programmatically amend override params.


```ps

$overrideParams = @{
    requiredParam = 'AAAA'
    optionalParamWithDefault='BBB'
    optionalParamFromEnvironment='CCC'
}

$ScriptPath = 'c:\bootstrap.ps1'
$sb = [scriptblock]::create(".{$(get-content $ScriptPath -Raw)} $(&{$args} @overrideParams)")
Invoke-Command -ScriptBlock $sb

# ...

# Validation:
About to execute some bootstrap logic with params RRR https://github.com/Voronenko/ps_oneliners on EC2AMAZ-9A8TRAV

# Validation - no overrides

$overrideParamsNone = @{
    requiredParam = 'RRR'
}
$sb = [scriptblock]::create(".{$(get-content $ScriptPath -Raw)} $(&{$args} @overrideParamsNone)")
Invoke-Command -ScriptBlock $sb
# ...
About to execute some bootstrap logic with params AAAA BBB on CCC


```

Acceptance: PASSED


## Option C - X-Liner executing script from remote location

Put overrides only into $overrideParams , other will be picked up from default values in install script, downloaded from the remote location
Pros - you can detect and programmatically amend override params, bootstrap script can be located on your download location.

```ps

$overrideParams = @{
    requiredParam = 'AAAA'
    optionalParamWithDefault='BBB'
    optionalParamFromEnvironment='CCC'
}


$ScriptPath = ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/Voronenko/ps_oneliners/master/bootstrap.ps1'))
$sb = [scriptblock]::create(".{$($ScriptPath)} $(&{$args} @overrideParams)")
Invoke-Command -ScriptBlock $sb

# output of the ^ command
About to execute some bootstrap logic with params AAAA BBB on CCC

$overrideParamsNone = @{
    requiredParam = 'RRR'
}

$ScriptPath = ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/Voronenko/ps_oneliners/master/bootstrap.ps1'))
$sb = [scriptblock]::create(".{$($ScriptPath)} $(&{$args} @overrideParamsNone)")
Invoke-Command -ScriptBlock $sb

# output of the ^ command
About to execute some bootstrap logic with params RRR https://github.com/Voronenko/ps_oneliners on EC2AMAZ-9A8TRAV
For example, we download smth from internet

```

Acceptance: PASSED


# Option D - Real one liner using powershell module and iwr + iex

As stated, requiries installation logic packed as a powershell module (see `bootstrap-module.ps1`)

`. { iwr -useb https://path/to/bootsrap.ps1 } | iex; function -param value`

```ps

. { iwr -useb https://raw.githubusercontent.com/Voronenko/ps_oneliners/master/bootstrap-module.ps1 } | iex; install -requiredParam AAA -optionalParamWithDefault BBB -optionalParamFromEnvironment CCC

# output of the ^ command

ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     0.0        CustomInstaller                     {Install-Project, install}
About to execute some bootstrap logic with params AAA BBB on CCC

# Validation - no overrides

. { iwr -useb https://raw.githubusercontent.com/Voronenko/ps_oneliners/master/bootstrap-module.ps1 } | iex; install

# output of the ^ command

ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     0.0        CustomInstaller                     {Install-Project, install}

cmdlet Install-Project at command pipeline position 1
Supply values for the following parameters:
requiredParam: RRR

```

Acceptance: PASSED

where bootstrap-module.ps1 is our original bootstrap file, but packed/wrapped into a module.

```ps

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


```

So far option D is the most one-linish :)

Check out  https://github.com/Voronenko/ps_oneliners for examples from article.

# Summary

We now have few approaches to choose from, to implement short "one liners" to bootstrap some logic with powershell
