# Powershell
# C:\Program Files\PowerShell\7\pwsh.exe
# Powershell Preview
# C:\Program Files\PowerShell\7-preview\pwsh.exe
# Windows Terminal (These seem to be the same, I'm guessing the top level just directs to the correct nested exe)
# C:\Users\alexa\AppData\Local\Microsoft\WindowsApps\wt.exe
# C:\Users\alexa\AppData\Local\Microsoft\WindowsApps\Microsoft.WindowsTerminal_8wekyb3d8bbwe\wt.exe

function Write-InitOutput {    
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Text
    )

    Write-Host "$Text"
}

function Import-VcpkgPosh {
    # VcPkg Profile
    $VcpkgPosh = "$env:VCPKG_ROOT\scripts\posh-vcpkg\0.0.1\posh-vcpkg.psm1"
    if (Test-Path($VcpkgPosh)) {
        Import-Module "$VcpkgPosh"
    }
}

function Test-ModuleUpdate {
    Write-InitOutput "Running Test-ModuleUpdate"
    $update_marker = (Get-ChildItem -Path "$PROFILE_DIR\.update_marker" -File -Force -ErrorAction SilentlyContinue)
    if ($null -eq $update_marker) {
        Write-InitOutput "Unable to find update_marker, creating now..."
        New-Item -Path "$PROFILE_DIR\.update_marker" -ItemType File
        Update-Module
    } else {
        Write-InitOutput "update_marker found..."
        # $lastupdate = (Get-Date).Subtract($update_marker.CreationTime).Day
        # $host.UI.WriteLine([string]::Format("{0} days since last update...", $lastupdate))
        if ((Get-Date).Subtract($update_marker.CreationTime).Days -gt 0) {
            Write-InitOutput "More than one day since last module update, running update..."
            Update-Module
            $update_marker.CreationTime = (Get-Date)
        } else {
            Write-InitOutput "Modules up to date..."
        }
    }
}

# $DIR_LISTING_TYPE = 'lsd'
$DIR_LISTING_TYPE = 'default'
$PROFILE_DIR = (Split-Path $PROFILE)

$_isterm = $host.Name -eq 'ConsoleHost'
$_isvscode = $env:TERM_PROGRAM -eq 'vscode'
$_isnoni = [System.Environment]::GetCommandLineArgs() -icontains "-noni" -or [System.Environment]::GetCommandLineArgs() -icontains "-NonInteractive"
$_shouldinit = !$_isnoni -and $_isterm

#use PSReadLine only for PowerShell and VS Code
if ($_shouldinit) {
    Write-InitOutput "====================="
    Write-InitOutput "Should Init is True."
    Write-InitOutput ("IsTerm = {0} | IsVSCode = {1} | IsNonInteractive = {2}" -f $_isterm, $_isvscode, $_isnoni)
    Write-InitOutput ("Host = {0} | Args = {1}." -f $host.Name, ([System.Environment]::GetCommandLineArgs() -join ','))
    Write-InitOutput "====================="
    $_now = (Get-Date)
    $PROFILE_DIR = (Split-Path $PROFILE)
    Write-InitOutput ("Starting profile init at {0} in directory {1} with host {2}" -f $_now.ToString(), $PROFILE_DIR, $host.Name)

    #ensure the correct version is loaded
    if ($DIR_LISTING_TYPE -eq 'default' -or $DIR_LISTING_TYPE -eq '' -or $null -eq $DIR_LISTING_TYPE) {
        Write-InitOutput ("DIR_LISTING_TYPE = '{0}', importing Terminal-Icons" -f $DIR_LISTING_TYPE)
        Import-Module Terminal-Icons
    }

    Import-Module posh-git
    Import-Module PSReadline -MinimumVersion 2.2.0

    Write-InitOutput "Sourcing PSReadline config..."
    . "$PROFILE_DIR\PSReadlineDefaults.ps1"

    Write-InitOutput "Sourcing completions..."
    Get-ChildItem "$PROFILE_DIR\Completions" -Filter '*.ps1' | ForEach-Object {
        Write-InitOutput ("Sourcing {0} completions." -f $_.BaseName)
        . $_
    }

    Write-InitOutput "Sourcing additional config..."
    Get-ChildItem "$PROFILE_DIR\Sources" -Filter '*.ps1' | ForEach-Object {
        Write-InitOutput ("Sourcing {0}." -f $_.Name)
        . $_
    }

    Invoke-Expression (&starship init powershell)

    Test-ModuleUpdate

    if (! $_isvscode) {
        Invoke-Fetch
    }
} else {
    Write-InitOutput "====================="
    Write-InitOutput "Should Init is False."
    Write-InitOutput ("IsTerm = {0} | IsVSCode = {1} | IsNonInteractive = {2}" -f $_isterm, $_isvscode, $_isnoni)
    Write-InitOutput ("Host = {0} | Args = {1}." -f $host.Name, ([System.Environment]::GetCommandLineArgs() -join ','))
    Write-InitOutput "====================="
}

# Remove-Item -Path Function:Write-InitOutput