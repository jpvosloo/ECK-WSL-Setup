Set-StrictMode -Version 'Latest'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8;

echo "WARNING: This will remove Ubuntu folders and WSL distros and delete all relevant data."
pause

$wsldistroname="Ubuntu-20.04";
$isDistroInstalled=$(wsl.exe --list) -contains "$wsldistroname";
if ($isDistroInstalled) {
    echo "Unregister WSL distro: $wsldistroname";
    wsl.exe --unregister $wsldistroname
} else {
    echo "No WSL distro named: $wsldistroname";
}


$serverinstallfolder=$Env:USERPROFILE + "\.wsl\distro\Ubuntu";
if (Test-Path $serverinstallfolder) {
    echo "Deleting path: $serverinstallfolder";
    Remove-Item -Recurse -Force $serverinstallfolder
} else {
    echo "No folder named: $serverinstallfolder"
}


$packagename="*Ubuntu20.04*";
$package=Get-AppxPackage -Name $packagename;
$isAppInstalled=(($package | Measure-Object).Count -gt 0);
if ($isAppInstalled) {
    echo "Removing windows app: $packagename";
    $package | Remove-AppxPackage
} else {
    echo "No Windows app named: $packagename";
}

