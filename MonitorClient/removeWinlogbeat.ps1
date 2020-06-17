#https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-7.7.1-windows-x86_64.msi

$filename = 'winlogbeat-7.7.1-windows-x86_64.msi';
$downloadlink = "https://artifacts.elastic.co/downloads/beats/winlogbeat/$filename";
$appname = 'Beats winlogbeat';

$apppackage = Get-Package -Name "$appname*"
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



msiexec /uninstall $tmp /qn;


echo "Check if $appname is installed.";
$appwmi = Get-WmiObject -Class Win32_Product -Filter "Name LIKE `'$appname`%'"

if ($appwmi -ne $null) {
    echo "$appname is installed.";
    $appwmi.Uninstall();

    $tmp = "$env:TEMP\$filename";
    [IO.FileInfo] $foo = $tmp;
    if (!$foo.Exists) {
        echo "Download to $tmp.";
        $client = New-Object System.Net.WebClient;
        $client.DownloadFile($downloadlink, $tmp);
    } else { 
        echo "Download file already exists."
    }
    pause
    msiexec /i $tmp /qn /norestart;
    del $tmp;
    echo "Tried installing $appname";

} else {
    echo "ERROR: $appname is already installed.";
    echo $appwmi;
    exit 1;
}

exit 0;