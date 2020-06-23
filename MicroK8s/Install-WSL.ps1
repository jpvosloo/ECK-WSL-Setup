$ErrorActionPreference = "Stop"; #Set this in every script
Set-StrictMode -Version 'Latest'; #Set this in every script

echo "Install WSL if needed."
if (Get-Command "wsl.exe" -errorAction SilentlyContinue)
{
    echo "WSL.exe is available, setting default version 2.";
    wsl --set-default-version 2;
} else {
    echo "WSL.exe is not available, checking if Microsoft-Windows-Subsystem-Linux feature is enabled.";
    if((Get-WindowsOptionalFeature -FeatureName "Microsoft-Windows-Subsystem-Linux" -Online).State -eq "Enabled")
    {
        echo "There is a problem, Microsoft-Windows-Subsystem-Linux is enabled but WSL.exe is not working."
        echo "Please restart your computer and retry, if that still fails, use Uninstall-WSL.ps1 and then try to re-install it."
    }
    echo "Enabling Microsoft-Windows-Subsystem-Linux feature.";
    pause
    Enable-WindowsOptionalFeature -FeatureName "Microsoft-Windows-Subsystem-Linux" -Online -NoRestart:$True;
    Enable-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online -NoRestart:$True;
    echo "WSL has been enabled, you must restart Windows for it to work."
}


