Get-AppxPackage

$package=Get-AppxPackage -Name $packagename;
$isAppInstalled=(($package | Measure-Object).Count -gt 0);

Move-AppxPackage -Package "package1_1.0.0.0_neutral__8wekyb3d8bbwe" -Volume F:\


$apppackage = Get-Package -Name "$appname*"
if ($apppackage  -ne $null) {
    echo "Found installed $appname";
    if ($apppackage[0].ProviderName = "msi") {
        echo "Attempting to remove package, please approve admin permissions if requested.";
        $apppackage[0] | Uninstall-Package -v; #only works for msi and will self-elevate if needed.
    } else {


