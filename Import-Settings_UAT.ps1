#This file overrides global settings and should not contain any code.
Write-Output "Start Script Settings_UAT.ps1 to set global settings for UAT Environment...";

setRawSetting 'isSettingsLoaded' $true; #This variable confirms that the settings completed loading and the script can proceed.
