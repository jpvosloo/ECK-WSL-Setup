Set-StrictMode -Version 'Latest'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8;


function Get-AppxFileManifest{
    param($appxPath)
    if(Test-Path $appxPath){
        Add-Type -Assembly "System.IO.Compression.FileSystem"
        $zip = [IO.Compression.ZipFile]::OpenRead($appxPath)
        $file = $zip.Entries | Where-Object { $_.Name -eq "AppxManifest.xml"}
        $stream = $file.Open()
        $reader = New-Object IO.StreamReader($stream)
        $xml = [XML]$reader.ReadToEnd()
        $reader.Close()
        $stream.Close()
        $zip.Dispose()
        $xml
    }
}

function Start-ProcessSync{
param($FilePath, $ArgumentList)
$pinfo = New-Object System.Diagnostics.ProcessStartInfo;
$pinfo.FileName = $FilePath;
$pinfo.Arguments = $ArgumentList;
$pinfo.RedirectStandardError = $true;
$pinfo.RedirectStandardOutput = $true;
$pinfo.UseShellExecute = $false;
$p = New-Object System.Diagnostics.Process;
$p.StartInfo = $pinfo;
$p.Start() | Out-Null;
$p.WaitForExit();
$stdout = $p.StandardOutput.ReadToEnd();
$stderr = $p.StandardError.ReadToEnd();
Write-Host "stdout: $stdout";
Write-Host "stderr: $stderr";
Write-Host "exit code: " + $p.ExitCode;
}


#Elevate UAC to admin
echo "Check that the script is running as admin.";
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
    echo "Check that the script is running as admin.";

    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    Exit
    }
}


#Install WSL 2
echo "Check if Microsoft-Windows-Subsystem-Linux feature is enabled.";
if((Get-WindowsOptionalFeature `
    -FeatureName "Microsoft-Windows-Subsystem-Linux" `
    -Online).State -ne "Enabled")
{
    echo "Enable Microsoft-Windows-Subsystem-Linux feature.";
    Enable-WindowsOptionalFeature `
        -FeatureName "Microsoft-Windows-Subsystem-Linux" `
        -Online `
        -NoRestart:$False ;
} else {
    echo "Microsoft-Windows-Subsystem-Linux feature is enabled.";
}

#Register WSL interop module.
#This only works for powershell core
#echo "Install WSL Interop powershell module. Please answer yes when asked to confirm this."
#https://github.com/mikebattista/PowerShell-WSL-Interop
#Install-Module WslInterop
#Import-WslCommand "ls"


#Install WSL 2 Ubuntu
$wsldistroname="Ubuntu-20.04";
echo "Check if $wsldistroname is installed on WSL";
$isDistroInstalled=$(wsl.exe --list) -contains "$wsldistroname";
if ($isDistroInstalled) {
    echo "$wsldistroname is installed on WSL and will be used.";
} else {
    $ubuntudownloadurl="https://aka.ms/wslubuntu2004"; #From: https://docs.microsoft.com/en-us/windows/wsl/install-manual
    echo "Install $wsldistroname on WSL 2 from: $ubuntudownloadurl";
    $ostype=(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType #Get OS type. 1=workstation,2=domaincontroller,3=server. #Alternative method: (Get-ComputerInfo).OsProductType
    switch ($ostype)
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
            $installCommand=$packageExe + " install --root";
            
            echo "Disable compression and encryption on the ??"
            pushd $package.InstallLocation
            compact.exe --% /U
            fsutil.exe --% behavior set disableencryption 1

            echo "Launch the distro setup at: $installCommand";
            & $packageExe --% install --root
            #Start-ProcessSync -FilePath $packageExe -ArgumentList "install --root";
            #$process=Start-Process  -FilePath $packageExe -ArgumentList "install --root"  -PassThru -Wait
            #$process.ExitCode

            echo "Updating Ubuntu.";
            pause
            echo wsl.exe -d $wsldistroname -e 'run sudo apt update && sudo apt upgrade && $SHELL';
            #Start-Process  -FilePath $packageExe -ArgumentList 'run sudo apt update && sudo apt upgrade && $SHELL';

        }
    2 {echo "This machine is a Domain Controller, unable to install package automatically.";}
    3 {


if ($installedUbuntu.Count -gt 0) {
    echo "Ubuntu is already installed and will be used for K8S."
    pause
} else {
    echo "Ubuntu is not yet installed, installing it now."
    echo "Downloading ubuntu package."
    $ubuntudownloadurl="https://aka.ms/wslubuntu2004"; #From: https://docs.microsoft.com/en-us/windows/wsl/install-manual
    $tmpappx="$env:temp\Ubuntu.appx.zip" #use .zip to support extracting it later if needed.
    Invoke-WebRequest -Uri $ubuntudownloadurl -OutFile $tmpappx -UseBasicParsing
    switch ($ostype)
    {
        1 {
            echo "Installing package for desktop OS.";
            Add-AppxPackage "$tmpappx";
            }
        2 {echo "This is a Domain Controller, unable to install package.";}
        3 {
            echo "Installing package for server OS.";
            $serverinstallfolder="~\.wsl\distro\Ubuntu";
            #Rename-Item .\Ubuntu.appx .\Ubuntu.zip
            #Expand-Archive $tmpappx $tmpappx
            #Rename the file extension to compressed file extension
            Rename-Item -Path $tmpappx -NewName "$tmpappx";
            # Expand the compressed file to destination
            echo Unzip App: $tmpappx to folder: $serverinstallfolder;
            Expand-Archive -Path $tmpappx -DestinationPath $serverinstallfolder;
            # Launch the distro setup
            Start-Process  -FilePath "$serverinstallfolder\Ubuntu2004.exe" -ArgumentList "install --root";
            echo "Updating Ubuntu."
            pause
            Start-Process  -FilePath "$serverinstallfolder\Ubuntu2004.exe" -ArgumentList 'run sudo apt update && sudo apt upgrade && $SHELL';
            }
    }
}


#https://kiazhi.github.io/blog/The-easy-way-to-get-Ubuntu-18.04-distro-environment-on-Windows/
#https://docs.microsoft.com/en-us/windows/wsl/install-on-server
#https://microk8s.io/
#https://ubuntu.com/blog/kubernetes-on-windows-with-microk8s-and-wsl-2
#https://www.youtube.com/watch?time_continue=457&v=DmfuJzX6vJQ&feature=emb_logo


$appname = 'ubuntu';

$apppackage = Get-Package -Name "*$appname*"
if ($apppackage  -ne $null) {
    echo "Found installed $appname";
    if ($apppackage[0].ProviderName = "msi") {
        echo "Attempting to remove package, please approve admin permissions if requested.";
        $apppackage[0] | Uninstall-Package -v; #only works for msi and will self-elevate if needed.
    } else {
    #elevate UAC
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $commandLine = "-Command `"`$(Get-Package '`$($apppackage[0].Name.ToString())').[0].Meta.Attributes['UninstallString']`"";

  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-Command `"`$(Get-Package '`$($apppackage[0].Name.ToString())').[0]`"; pause";
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-Command `"echo $apppackage[0].Name.ToString(); pause`"";

  $commandLine = "";
  $commandLine += "-Command `"";
  $commandLine += "`$(";
  $commandLine += "Get-Package `'$($apppackage[0].Name.ToString())`'";
  $commandLine += ").[0]";
  $commandLine += "; pause;";
  $commandLine += "`"";
  echo $commandLine;
  Start-Process -FilePath PowerShell.exe -Verb Runas -NoNewWindow -ArgumentList $commandLine
  Exit
 }
}

        $apppackage[0] |% { & $_.Meta.Attributes["UninstallString"]}; #workaround for non msi providers.
    }
}


#Install Kubernetes


#Install Kubernetes Helm CLI

