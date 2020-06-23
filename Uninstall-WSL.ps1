echo "Remove WSL."
pause
echo "Check if Microsoft-Windows-Subsystem-Linux feature is enabled.";
if((Get-WindowsOptionalFeature -FeatureName "Microsoft-Windows-Subsystem-Linux" -Online).State -eq "Enabled")
{
    echo "Disable Microsoft-Windows-Subsystem-Linux feature.";
    Disable-WindowsOptionalFeature -FeatureName "Microsoft-Windows-Subsystem-Linux" -Online -NoRestart:$False ;
} else {
    echo "Microsoft-Windows-Subsystem-Linux feature is disabled.";
}