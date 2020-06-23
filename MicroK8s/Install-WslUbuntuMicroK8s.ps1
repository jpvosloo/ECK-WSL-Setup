#This script install WSL then Ubuntu then MicroK8s.
#Documentation is provided in Readme.md on Github: 

#Usage example:

#Dependencies
#This script has a number of sub scripts in this folder that are needed for it to work e.g:
# Import-Settings_Dev.ps1, Import-Settings_UAT.ps1, Import-Settings_PRD.ps1


param (
    #[Parameter(mandatory = $true)][string] $EnvironmentName
    [string] $EnvironmentName = "DEV"
)
$ErrorActionPreference = "Stop"; #Set this in every script.
Set-StrictMode -Version 'Latest'; #Set this in every script.

function main() {
    param (
        [Parameter(mandatory = $true)][string] $EnvironmentName
    )
    Write-Output "Start script: $PSCommandPath";
    try {
        . .\Initialize-Settings.ps1; #Paired with Finalize-Settings;
        #= MAIN FUNCTIONAL CODE START ======================
        elevateUAC;
        . .\Install-WSL.ps1;
        . .\Install-UbuntuOnWsl.ps1;
        #Install Kubernetes, Dependencies:
        #$wsldistroname="Ubuntu-20.04";
        #$serverinstallfolder pointing to ubuntu2004.exe for example: $serverinstallfolder=$Env:USERPROFILE + "\.wsl\distro\Ubuntu";
        if ($host.name -eq 'ConsoleHost') { #commands differ if it's being run in ISE or on console.
            . wsl.exe -d $wsldistroname -e "/bin/bash" -- "install-microK8sOnUbuntu.sh"
        } else {
            . "$serverinstallfolder\Ubuntu2004.exe" run '/bin/bash "install-microK8sOnUbuntu.sh"';
        }
        #https://www.youtube.com/watch?time_continue=457&v=DmfuJzX6vJQ&feature=emb_logo
        #Install Kubernetes Helm CLI

        #= MAIN FUNCTIONAL CODE END ========================
        Write-Output 'Script completed without error.';
        exitWithCode 0; #All good, we can exit with success.
    }
    catch { 
        Write-Host "Script failed with error: $_" -ForegroundColor RED;
        exitWithCode -1; #There was an error, notify upstream process.
    }
    finally {
        try { Finalize-Settings; } catch {} 
    }
}

function setDefaultSettings() {
    #This is called from Initialize-Settings and may be overridden in the Settings_DEV.ps1 Settings_UAT.ps1 and Settings_PRD.ps1 file.
    setRawSetting 'EnvironmentName' $EnvironmentName;
    setRawSetting 'ScriptTimestamp' (Get-Date).tostring('yyyyMMdd_hhmmss');
    setPathSetting 'HomePath' '..';
    setPathSetting 'LogFile' "..\Temp\" + $(split-path $PSCommandPath -Leaf) + ".log"; #If this change, remember to update the transcript command in Initialize-Settings.
    setPathSetting 'TempFolder' "$($HomePath)\Temp\Temp$(split-path $PSCommandPath -Leaf)";
    setPathSetting 'TempFolderBackup' "$($TempFolder)Backup";
}


function elevateUAC() {
    #Elevate UAC to admin
    echo "Check that the script is running as admin.";
    pause
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
            if ($host.name -eq 'ConsoleHost') {
                echo "Not running as admin, attempting to request UAC elevation.";
                $CommandLine = "-File `"" + $PSCommandPath + "`" " + $MyInvocation.UnboundArguments
                Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
                Exit
            } else {        
                Write-Error "This script must be run as administrator and can only self-elevate UAC when run in a console, not ISE. Please re-try as administrator.";
            }
        }
    }
}




#https://docs.microsoft.com/en-us/windows/wsl/install-on-server
#https://microk8s.io/
#https://ubuntu.com/blog/kubernetes-on-windows-with-microk8s-and-wsl-2




main $EnvironmentName; #When the file is fully loaded, run the main function.