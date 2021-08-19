# Powershell
# C:\Program Files\PowerShell\7\pwsh.exe
# Powershell Preview
# C:\Program Files\PowerShell\7-preview\pwsh.exe
# Windows Terminal (These seem to be the same, I'm guessing the top level just directs to the correct nested exe)
# C:\Users\alexa\AppData\Local\Microsoft\WindowsApps\wt.exe
# C:\Users\alexa\AppData\Local\Microsoft\WindowsApps\Microsoft.WindowsTerminal_8wekyb3d8bbwe\wt.exe

function Import-VcpkgPosh {
    # VcPkg Profile
    $VcpkgPosh = "$env:VCPKG_ROOT\scripts\posh-vcpkg\0.0.1\posh-vcpkg.psm1"
    if (Test-Path($VcpkgPosh)) {
        Import-Module "$VcpkgPosh"
    }
}

function Test-ModuleUpdate {
    Write-Log -Level INFO -Message 'Running Test-ModuleUpdate'
    $update_marker = (Get-ChildItem -Path "$PROFILE_DIR\.update_marker" -File -Force -ErrorAction SilentlyContinue)
    if ($null -eq $update_marker) {
        Write-Log -Level INFO -Message 'Unable to find update_marker, creating now...'
        New-Item -Path "$PROFILE_DIR\.update_marker" -ItemType File
        Update-Module
    }
    else {
        Write-Log -Level INFO -Message 'update_marker found...'
        # $lastupdate = (Get-Date).Subtract($update_marker.CreationTime).Day
        # $host.UI.WriteLine([string]::Format("{0} days since last update...", $lastupdate))
        if ((Get-Date).Subtract($update_marker.CreationTime).Days -gt 0) {
            Write-Log -Level INFO -Message 'More than one day since last module update, running update...'
            Update-Module
            $update_marker.CreationTime = (Get-Date)
        }
        else {
            Write-Log -Level INFO -Message 'Modules up to date...'
        }
    }
}

function Initialize-LoggingFramework {
    Import-Module Logging
    Set-LoggingDefaultLevel -Level INFO
    Set-LoggingDefaultFormat -Format '%{timestamp:+yyyy/MM/dd HH:mm:ss.fff}|%{level}|%{pid}|%{caller}: %{message} %{body}'
}

function Register-ConsoleLoggingTarget {
    Add-LoggingTarget -Name Console -Configuration @{
        PrintException = $true
    }
}

function Register-FileLoggingTarget {
    Write-Output "Log File: $('{0}\main_{1}.log' -f $PS_LOG_DIR, '%{+%Y%m%d}')"
    Add-LoggingTarget -Name File -Configuration @{
        Path           = ('{0}\main_{1}.log' -f $PS_LOG_DIR, '%{+%Y%m%d}')
        PrintBody      = $true
        PrintException = $true
        Append         = $true
        Encoding       = 'ascii'
    }
}

# $DIR_LISTING_TYPE = 'lsd'
$DIR_LISTING_TYPE = 'default'
$PROFILE_DIR = (Split-Path $PROFILE)
$PS_LOG_DIR = (Resolve-Path "$PROFILE_DIR\Logs")

$_isterm = $host.Name -eq 'ConsoleHost'
$_isvscode = $env:TERM_PROGRAM -eq 'vscode'
$_isnoni = [System.Environment]::GetCommandLineArgs() -icontains '-noni' -or [System.Environment]::GetCommandLineArgs() -icontains '-NonInteractive'
$_shouldinit = !$_isnoni -and $_isterm

#use PSReadLine only for PowerShell and VS Code
if ($_shouldinit) {
    Initialize-LoggingFramework
    Register-ConsoleLoggingTarget
    Register-FileLoggingTarget
    Write-Log -Level INFO -Message '====================='
    Write-Log -Level INFO -Message 'Should Init is True.'
    Write-Log -Level INFO -Message 'IsTerm = {0} | IsVSCode = {1} | IsNonInteractive = {2}' -Arguments $_isterm, $_isvscode, $_isnoni
    Write-Log -Level INFO -Message 'Host = {0} | Args = {1}.' -Arguments $host.Name, ([System.Environment]::GetCommandLineArgs() -join ',')
    Write-Log -Level INFO -Message '====================='
    Write-Log -Level INFO -Message 'Starting profile init in directory {0} with host {1}' -Arguments $PROFILE_DIR, $host.Name

    #ensure the correct version is loaded
    if ($DIR_LISTING_TYPE -eq 'default' -or $DIR_LISTING_TYPE -eq '' -or $null -eq $DIR_LISTING_TYPE) {
        Write-Log -Level INFO -Message "DIR_LISTING_TYPE = '{0}', importing Terminal-Icons" -Arguments $DIR_LISTING_TYPE
        Import-Module Terminal-Icons
    }

    Import-Module posh-git
    Import-Module PSReadline -MinimumVersion 2.2.0

    Write-Log -Level INFO -Message 'Sourcing PSReadline config...'
    . "$PROFILE_DIR\PSReadlineDefaults.ps1"

    Write-Log -Level INFO -Message 'Sourcing completions...'
    Get-ChildItem "$PROFILE_DIR\Completions" -Filter '*.ps1' | ForEach-Object {
        Write-Log -Level INFO -Message 'Sourcing {0} completions.' -Arguments $_.BaseName
        . $_
    }

    Write-Log -Level INFO -Message 'Sourcing additional config...'
    Get-ChildItem "$PROFILE_DIR\Sources" -Filter '*.ps1' | ForEach-Object {
        Write-Log -Level INFO -Message 'Sourcing {0}.' -Arguments $_.Name
        . $_
    }

    Invoke-Expression (&starship init powershell)

    Test-ModuleUpdate

    if (! $_isvscode) {
        Invoke-Fetch
    }
}
else {
    Initialize-LoggingFramework
    Register-FileLoggingTarget
    Write-Log -Level INFO -Message '====================='
    Write-Log -Level INFO -Message 'Should Init is False.'
    Write-Log -Level INFO -Message 'IsTerm = {0} | IsVSCode = {1} | IsNonInteractive = {2}' -Arguments $_isterm, $_isvscode, $_isnoni
    Write-Log -Level INFO -Message 'Host = {0} | Args = {1}.' -Arguments $host.Name, ([System.Environment]::GetCommandLineArgs() -join ',')
    Write-Log -Level INFO -Message '====================='
}
