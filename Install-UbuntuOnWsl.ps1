$ErrorActionPreference = "Stop"; #Set this in every script
Set-StrictMode -Version 'Latest'; #Set this in every script

echo "Install Ubuntu on WSL if needed."
#https://kiazhi.github.io/blog/The-easy-way-to-get-Ubuntu-18.04-distro-environment-on-Windows/
$wsldistroname="Ubuntu-20.04";
$ubuntudownloadurl="https://aka.ms/wslubuntu2004"; #From: https://docs.microsoft.com/en-us/windows/wsl/install-manual
echo "Check if $wsldistroname is installed on WSL";
$isDistroInstalled=$(wsl.exe --list) -contains "$wsldistroname";
if ($isDistroInstalled) {
    echo "$wsldistroname is installed on WSL.";
} else {
    echo "Install $wsldistroname on WSL 2 from: $ubuntudownloadurl";
    pause
    #This is a workaround for compressed drives, how do we fix the script so it will work regardless?
    if (((Get-Item -Path c:\ | Select-Object -ExpandProperty Attributes) -band [IO.FileAttributes]::Compressed) -eq [IO.FileAttributes]::Compressed)
    {
        echo "The c: drive is compressed, therefore the windows app install won't work. Switching to server install mode."
        $installmode=3;
    } else {
        $installmode=(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType #Get OS type. 1=workstation,2=domaincontroller,3=server. #Alternative method: (Get-ComputerInfo).OsProductType
    }
    switch ($installmode)
    {
    1 {
        echo "Working on a desktop OS.";
        $packagename="*Ubuntu20.04*";
        $package=Get-AppxPackage -Name $packagename;
        #$package | Remove-AppxPackage
        $isAppInstalled=(($package | Measure-Object).Count -gt 0);
        if ($isAppInstalled) {
            echo "App is installed and will be used from: $package.InstallLocation";
            $package=$package[0];
        } else {
            echo "Installing app through windows store.";
            Add-AppxPackage "$ubuntudownloadurl";
            $package=Get-AppxPackage -Name $packagename; #update the variable for later use.
        }
        $packageExename=($package | Get-AppxPackageManifest).package.applications.application.Executable;
        $packageExe=$package.InstallLocation + '\' + $packageExename;
        $appdatapath=$env:LOCALAPPDATA + "`\Packages`\" + $package.PackageFamilyName
        echo "Disable compression on the app data folder: $appdatapath"
        compact.exe /U /S $appdatapath
        echo "Launch the distro setup: $packageExe install --root";
        & $packageExe --% install --root
        #Start-ProcessSync -FilePath $packageExe -ArgumentList "install --root";
        #$process=Start-Process  -FilePath $packageExe -ArgumentList "install --root"  -PassThru -Wait
        #$process.ExitCode
        
        echo "Updating Ubuntu.";
        pause
        echo wsl.exe -d $wsldistroname -e 'run sudo apt update && sudo apt upgrade && $SHELL';
        #Start-Process  -FilePath $packageExe -ArgumentList 'run sudo apt update && sudo apt upgrade && $SHELL';
        }
    2 { echo "This machine is a Domain Controller, unable to install package automatically.";}
    3 {
        $serverinstallfolder=$Env:USERPROFILE + "\.wsl\distro\Ubuntu";
        if (Test-Path $serverinstallfolder) {
            echo "The package has already been installed to the target folder: $serverinstallfolder"
        } else {
            echo "Installing package for server OS at: $serverinstallfolder";
            $tmpappx="$env:temp\Ubuntu.appx.zip" #use .zip to support extracting it later.
            Invoke-WebRequest -Uri $ubuntudownloadurl -OutFile $tmpappx -UseBasicParsing
            echo "Unzip App: $tmpappx to folder: $serverinstallfolder";
            Expand-Archive -Path $tmpappx -DestinationPath $serverinstallfolder;
            }
        echo "Disable compression on the app folder: $serverinstallfolder";
        compact.exe /U /S $serverinstallfolder
        echo "Launch the distro setup";
        . "$serverinstallfolder\Ubuntu2004.exe" --% install --root
        echo "Updating Ubuntu."
        . "$serverinstallfolder\Ubuntu2004.exe" run 'sudo apt-get update';
        . "$serverinstallfolder\Ubuntu2004.exe" run 'sudo apt-get upgrade -y';
        echo "Ubuntu upgrade complete.";
        }
    }
}