function Initialize-Settings {
    #This function runs only the first time this file is loaded.
    if (!(Test-Path Variables:Global:isSettingsLoaded) -or (!$Global:isSettingsLoaded)) {
        Set-Location -ErrorAction Continue $(Split-Path -Path $PSCommandPath -Parent); #Make sure the working folder is the script folder.

        #Transcript logging is enabled when run from console (not ISE), remember to test using the console because powershell acts differently under transcript.
        if ($host.name -eq 'ConsoleHost')
        { try{
            Start-Transcript -Append -path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("..\Temp\$(split-path $PSCommandPath -Leaf).log");#Hardcode log path to start logging asap with minimal dependencies.
            } catch {} 
        } else {
            try { cmd.exe /? |Out-Null } catch {}; #Workaround for ISE to create console, otherwise [Console] commands will fail.
        }
        setUtf8Encoding;
        setLogWindowSize;
        setDefaultSettings; #This is defined in the calling script.
        #Verify input parameter and call the correct Environment settings file. These files are used to override default settings.
        #isSettingsLoaded flag must be set at the end of the relevant file to confirm it loaded correctly.
        switch ($EnvironmentName) {
            "DEV" { ./Import-Settings_DEV.ps1 }
            "UAT" { ./Import-Settings_UAT.ps1 }
            "PRD" { ./Import-Settings_PRD.ps1 }
            Default { Write-Error "The EnvironmentName parameter must be DEV, UAT or PRD. You provided:$EnvironmentName" }
        }
        #Verify that init completed properly...
        if (!$Global:isSettingsLoaded) { throw [System.Exception] "Settings not loaded correctly, cancelling script."; }
    }
}

function Finalize-Settings {
    try{ Stop-Transcript -ErrorAction Continue; } catch {} #Stop transcript logging.
    keepLogfiles; #Timestamp log file if needed.
}

function setUtf8Encoding() {
    #For WSL Linux compatibility use unicode.
    $OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8; 
}

function setLogWindowSize() {
    #To allow better readability in log files.
    Write-Verbose "Setting log window width to 3000 characters."; 
    $pshost = get-host;
    $pswindow = $pshost.ui.rawui;
    $newsize = $pswindow.buffersize;
    $newsize.width = 3000;
    $pswindow.buffersize = $newsize;
}

function exitWithCode {
    #Used in the main scipt to return the exit code to the calling application.
    param($exitcode)
    if ($Host.Name -eq 'ConsoleHost') { $host.SetShouldExit($exitcode); }
    exit $exitcode;
}

function setRawSetting([string]$Name, [string]$Value) {
    #Used in the Settings_???.ps1 files to set global variables.
    try {
        Set-Variable -Name $Name -Value $Value -Scope global;
    }
    catch { throw( New-Object System.Exception( "Failed to configure global setting:{0} with value:{1}" -f $Name, $Value, $_.Exception ) ); }
    Write-Output ("`$Global:{0}=`"{1}`"" -f $Name, $Value);
}

function setPathSetting([string]$SettingName, [string]$Path) {
    #Used in the Settings_???.ps1 files to set global variables.
    try {
        $tmppath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path); #This should get the full path for most relative paths.
    }
    catch {
        $tmppath = $Path; #Ignore the error and use the path as-is.
    }
    setRawSetting -Name $SettingName -Value $tmppath;
}

function keepLogfiles() {
    #Add timestamp to transcript log so next run won't append to the same file.
    if ($keeplogfiles) {
        $logold="..\Temp\" + $(split-path $PSCommandPath -Leaf) + ".log"
        $lognew="..\Temp\" + $(split-path $PSCommandPath -Leaf) + "." + $((Get-Date).tostring('yyyyMMdd_hhmmss')) + ".log";
        Rename-Item "$logold" "$lognew";
    }
}

function Test-Debug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$IgnorePSBoundParameters
        ,
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreDebugPreference
        ,
        [Parameter(Mandatory = $false)]
        [switch]$IgnorePSDebugContext
    )
    process {
        ((-not $IgnoreDebugPreference.IsPresent) -and ($DebugPreference -ne "SilentlyContinue")) -or
        ((-not $IgnorePSBoundParameters.IsPresent) -and $PSBoundParameters.Debug.IsPresent) -or
        ((-not $IgnorePSDebugContext.IsPresent) -and ($PSDebugContext))
    }
}

Initialize-Settings; #Prepare anything that needs to be prepared.