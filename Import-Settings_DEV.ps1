#This file overrides global settings and should not contain any code.
Write-Output "Start Script Settings_DEV.ps1 to set global settings for DEV Environment...";
setRawSetting 'VerbosePreference' 'continue' #Enable verbose logging

setRawSetting 'isSettingsLoaded' $true; #This variable confirms that the settings completed loading and the script can proceed.
