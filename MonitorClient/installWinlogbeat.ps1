#https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-7.7.1-windows-x86_64.msi


$file = 'winlogbeat-7.7.1-windows-x86_64.msi';
$link = "https://artifacts.elastic.co/downloads/beats/winlogbeat/$file";
$soft_name = 'Beats winlogbeat';

echo "Check if $soft_name is installed.";
$find = Get-WmiObject -Class Win32_Product -Filter "Name LIKE `'$soft_name`%'"

if ($find -eq $null) {
    echo "$soft_name not installed.";
    $tmp = "$env:TEMP\$file";
    [IO.FileInfo] $foo = $tmp;
    if (!$foo.Exists) {
        echo "Download to $tmp.";
        $client = New-Object System.Net.WebClient;
        $client.DownloadFile($link, $tmp);
    } else { 
        echo "Download file already exists."
    }
    pause
    msiexec /i $tmp /qn /norestart;
    del $tmp;
    echo "Tried installing $soft_name";

} else {
    echo "ERROR: $soft_name is already installed.";
    echo $find;
    exit 1;
}

exit 0;