# Powershell
# C:\Program Files\PowerShell\7\pwsh.exe
# Powershell Preview
# C:\Program Files\PowerShell\7-preview\pwsh.exe
# Windows Terminal (These seem to be the same, I'm guessing the top level just directs to the correct nested exe)
# C:\Users\tonyb\AppData\Local\Microsoft\WindowsApps\wt.exe
# C:\Users\tonyb\AppData\Local\Microsoft\WindowsApps\Microsoft.WindowsTerminal_8wekyb3d8bbwe\wt.exe

function Initialize-VcpkgPosh {
    Write-Log -Level INFO -Message 'Initialize-VcpkgPosh called'

    $VcpkgPosh = "$Env:VCPKG_ROOT\scripts\posh-vcpkg"
    if (Test-Path $VcpkgPosh) {
        Import-Module "$VcpkgPosh"
    }
    else {
        Write-Log -Level ERROR -Message 'Error importing posh-vcpkg module! $VcpkgPosh = {0}' -Arguments $VcpkgPosh
    }
}

function Test-ModuleLoaded($ModuleName) {
    Write-Log -Level INFO -Message 'Test-ModuleLoaded called'
    if ($null -eq $ModuleName -or $ModuleName -eq '') {
        Write-Log -Level ERROR -Message 'Test-ModuleLoaded called with null module name'
        return $false
    }

    return $null -ne (Get-Module | Where-Object -Property Name -EQ $ModuleName)
}

function Update-Vcpkg {
    Write-Log -Level INFO -Message 'Update-Vcpkg called, checking for updates to vcpkg'

    Push-Location $Env:VCPKG_ROOT
    
    if (!(Test-Path .\.vcpkg-root)) {
        $_currpath = (Get-Location).Path
        Write-Log -Level ERROR -Message 'Unable to find .vcpkg-root marker, check your code! pwd = {0}' -Arguments $_currpath
        Pop-Location
        return
    }

    $_output = (git status -uno)
    $_combined = [string]::Join('\n', $_output)
    Write-Log -Level INFO -Message 'git status run' -Body @{Output = $_output; JoinedOutput = $_combined }
    if ($_combined.Contains('up to date')) {
        Write-Log -Level INFO -Message 'local branch is up-to-date, no update is necessary'
    }
    else {
        Write-Log -Level INFO -Message 'local branch is not up-to-date, pulling remote'
        git pull
        .\bootstrap-vcpkg.bat
        Write-Log -Level INFO -Message 'vcpkg has been updated'
    }
    Pop-Location
}

function Invoke-OncePerDay {
    Update-Module
    # Update-Vcpkg
}

function Test-OncePerDay {
    Write-Log -Level INFO -Message 'Running Test-OncePerDay'
    $update_marker = (Get-ChildItem -Path "$PROFILE_DIR\.update_marker" -File -Force -ErrorAction SilentlyContinue)
    if ($null -eq $update_marker) {
        Write-Log -Level INFO -Message 'Unable to find update_marker, creating now...'
        New-Item -Path "$PROFILE_DIR\.update_marker" -ItemType File
        Invoke-OncePerDay
    }
    else {
        Write-Log -Level INFO -Message 'update_marker found...'
        # $lastupdate = (Get-Date).Subtract($update_marker.CreationTime).Day
        # $host.UI.WriteLine([string]::Format("{0} days since last update...", $lastupdate))
        if ((Get-Date).Subtract($update_marker.CreationTime).Days -gt 0) {
            Write-Log -Level INFO -Message 'More than one day since last module update, running update...'
            Invoke-OncePerDay
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

function Initialize-TonyDrive {
    Write-Log -Level INFO -Message 'Initialize-TonyDrive called'

    $_path = $Env:TONY_DIR
    if ($null -eq $_path) {
        Write-Log -Level ERROR -Message 'TONY_DIR is null! Aborting Initialize-TonyDrive!'
        return
    }

    if ('' -eq $_path) {
        Write-Log -Level ERROR -Message 'TONY_DIR is empty! Aborting Initialize-TonyDrive!'
        return
    }

    if (Test-Path $_path) {
        if (Get-PSDrive Tony -ErrorAction SilentlyContinue) {
            Write-Log -Level WARNING -Message 'TonyDrive already exists'
        }
        else {
            New-PSDrive -Name Tony -PSProvider FileSystem -Root $Env:TONY_DIR -Scope global > $null
        }
    }
    else {
        Write-Log -Level ERROR -Message 'TONY_DIR path is not valid! path = {0}' -Arguments $_path
    }    
}

function Initialize-Zoxide {
    Write-Log -Level INFO -Message 'Initialize-Zoxide called'
    # For zoxide v0.8.0+
    Invoke-Expression (& {
            $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
            (zoxide init --hook $hook powershell | Out-String)
        })
}

function Initialize-BurntToast {
    Write-Log -Level INFO -Message 'Initialize-BurnToast called'
    if (Test-ModuleLoaded 'BurntToast') {
        Show-QuickToast -Title 'Burnt Toast' -Content 'Burnt Toast is already loaded!'
        return
    }

    do {
        $_tmpbt = New-BTContentBuilder
        $_tmpbt.AddHeader((Get-Date -UFormat '%m/%d/%Y %R').ToString(), 'Burnt Toast', '') | Out-Null
        $_tmpbt.AddText('BurntToast Module Loaded!', [Microsoft.Toolkit.Uwp.Notifications.AdaptiveTextStyle]::Subheader) | Out-Null
        $_tmpbt.Show() 
    } while ($false)

    Import-Module BurntToast -MinimumVersion 1.0.0 
}

function Show-QuickToast($Title, $Content, $AppId = $null) {
    $_title = $null -eq $Title ? 'Quick Toast' : $Title
    $_content = $null -eq $Content ? 'Toast notification.' : $Content
    $_id = $null -eq $AppId ? (Get-Date -UFormat '%m/%d/%Y %R').ToString() : $AppId
    $_tmpbt = New-BTContentBuilder
    $_tmpbt.AddHeader($_id, $_title, '') | Out-Null
    $_tmpbt.AddText($_content) | Out-Null
    $_tmpbt.Show()
}

function Register-ConsoleLoggingTarget {
    Add-LoggingTarget -Name Console -Configuration @{
        PrintException = $true;
        Level          = 'WARNING'
    }
}

function Register-FileLoggingTarget {
    Add-LoggingTarget -Name File -Configuration @{
        Path           = ('{0}\main_{1}.log' -f $PS_LOG_DIR, '%{+%Y%m%d}');
        PrintBody      = $true;
        PrintException = $true;
        Append         = $true;
        Encoding       = 'ascii'
    }
}

function Register-OtherSources {
    Write-Log -Level INFO -Message 'Sourcing additional config...'
    foreach ($_it in Get-ChildItem "$PROFILE_DIR\Sources" -Filter '*.ps1') {
        Write-Log -Level INFO -Message 'Sourcing {0}.' -Arguments $_it.Name
        if ($_it.BaseName.StartsWith('_')) {
            Write-Log -Level INFO -Message 'Config {0} is marked incomplete, skipping.' -Arguments $_it.BaseName  
            continue 
        }
        . $_it
    }
}

function Register-Completions {
    Write-Log -Level INFO -Message 'Sourcing completions...'
    foreach ($_it in Get-ChildItem "$PROFILE_DIR\Completions" -Filter '*.ps1') {
        Write-Log -Level INFO -Message 'Sourcing {0} completions.' -Arguments $_it.BaseName
        if ($_it.BaseName.StartsWith('_')) {
            Write-Log -Level INFO -Message 'Completions for {0} are incomplete, skipping.' -Arguments $_it.BaseName  
            continue 
        }
        . $_it
    }
}

function Test-IsPromptElevatedManual {
    try {
        $_elevated = Get-ChildItem "$PROFILE_DIR\TestElevated.ps1"
        . $_elevated
        Write-Log -Level INFO -Message 'Powershell prompt found to be elevated'
        return $true
    }
    catch {
        Write-Log -Level INFO -Message 'Powershell prompt found to NOT be elevated'
        return $false
    }
}

function Initialize-PSReadline {
    Write-Log -Level INFO -Message 'Initialize-PSReadline called'
    Write-Log -Level INFO -Message 'Importing PSReadline'
    Import-Module PSReadline -MinimumVersion 2.2.0
    Write-Log -Level INFO -Message 'Sourcing PSReadline config...'
    . "$PROFILE_DIR\PSReadlineDefaults.ps1"
}

function Initialize-ProfileEnvironment {
    # $DIR_LISTING_TYPE = 'lsd'
    $Env:DIR_LISTING_TYPE = 'default'
    $DIR_LISTING_TYPE = $Env:DIR_LISTING_TYPE
    $Env:PROFILE_DIR = (Split-Path $PROFILE)
    $PROFILE_DIR = $Env:PROFILE_DIR
    # Read this from the ENV, that way dir path for other folders
    # is not hard-wired to any specific location.
    # $Env:TONY_DIR = (Resolve-Path C:\Tony)
    $TONY_DIR = $Env:TONY_DIR
    $Env:TONY_BIN_DIR = (Resolve-Path "$TONY_DIR\Bin\")
    $TONY_BIN_DIR = $Env:TONY_BIN_DIR
    $Env:TONY_CODE_DIR = (Resolve-Path "$TONY_DIR\Code\")
    $TONY_CODE_DIR = $Env:TONY_CODE_DIR
    $Env:TONY_REPOS_DIR = (Resolve-Path "$TONY_DIR\Repos\")
    $TONY_REPOS_DIR = $Env:TONY_REPOS_DIR
    $Env:PS_LOG_DIR = (Resolve-Path "$PROFILE_DIR\Logs")
    $PS_LOG_DIR = $Env:PS_LOG_DIR
    $Env:TONY_LIB_DIR = (Resolve-Path "$TONY_DIR\Lib\")
    $TONY_LIB_DIR = $Env:TONY_LIB_DIR

    # Vcpkg Options
    $Env:VCPKG_ROOT = "$TONY_DIR\Repos\vcpkg"
    $VCPKG_ROOT = $Env:VCPKG_ROOT
    $Env:VCPKG_DEFAULT_TRIPLET = 'x64-windows'
    $VCPKG_DEFAULT_TRIPLET = $Env:VCPKG_DEFAULT_TRIPLET

    # WasmEdge Setup
    $WASM_EDGE_VERSION = 'WasmEdge-0.9.0-Windows'
    $Env:WASM_ROOT = "$TONY_LIB_DIR\$WASM_EDGE_VERSION"
    $WASM_ROOT = $Env:WASM_ROOT

    # Get clang version & set CXX variable
    try {
        $tmp = (clang++ --version).Item(0).Split('version', 2)[1].Trim()
        $Env:CLANG_VERSION = $tmp
        $CXX = 'clang++'
        $Env:CXX = 'clang++'
    }
    catch {
        Write-Host -ForegroundColor Yellow 'Unable to get clang version!'
        $CLANG_VERSION = 'error'
        $CXX = ''
        $Env:CXX = ''
    }

    # Misc. Globals
    $Env:EDITOR = 'code'
    $EDITOR = $Env:EDITOR
}

function Initialize-MainProfile {
    $_isterm = $host.Name -eq 'ConsoleHost'
    $_isvscode = $env:TERM_PROGRAM -eq 'vscode'
    $_isnoni = [System.Environment]::GetCommandLineArgs() -icontains '-noni' -or [System.Environment]::GetCommandLineArgs() -icontains '-NonInteractive'
    $_shouldinit = !$_isnoni -and $_isterm

    $PS_IS_ELEVATED = (Test-IsPromptElevatedManual)

    # Logging is set up for any powershell session.
    # Console logging is only enabled for interactive sessions that are NOT run inside of VSCode.
    . Initialize-LoggingFramework
    . Register-ConsoleLoggingTarget
    . Register-FileLoggingTarget
    Write-Log -Level INFO -Message '====================='
    Write-Log -Level INFO -Message 'Powershell started at {0}' -Arguments (Get-Date)
    Write-Log -Level INFO -Message 'IsElevated = {0}' -Arguments $PS_IS_ELEVATED
    Write-Log -Level INFO -Message 'IsTerm = {0} | IsVSCode = {1} | IsNonInteractive = {2}' -Arguments $_isterm, $_isvscode, $_isnoni
    Write-Log -Level INFO -Message 'Host = {0} | Args = {1}.' -Arguments $host.Name, ([System.Environment]::GetCommandLineArgs() -join ',')
    Write-Log -Level INFO -Message 'ShouldInit = {0}' -Arguments $_shouldinit
    Write-Log -Level INFO -Message '====================='


    if (!($_shouldinit)) {
        return
    }

    . Initialize-ProfileInteractive
}

function Initialize-ProfileInteractive {
    #use PSReadLine only for PowerShell and VS Code
    Write-Log -Level INFO -Message 'Starting MainProfile init'

    #ensure the correct version is loaded
    if ($DIR_LISTING_TYPE -eq 'default' -or $DIR_LISTING_TYPE -eq '' -or $null -eq $DIR_LISTING_TYPE) {
        Write-Log -Level INFO -Message "DIR_LISTING_TYPE = '{0}', importing Terminal-Icons" -Arguments $DIR_LISTING_TYPE
        Import-Module Terminal-Icons
    }

    . Initialize-PSReadline
    Import-Module posh-git
    . Initialize-BurntToast
    . Initialize-VcpkgPosh
    . Initialize-TonyDrive
    
    . Register-Completions
    . Register-OtherSources

    Invoke-Expression (&starship init powershell)

    # Updating modules from an elevated prompt has issues, 
    #   so keep daily tasks confined to not elevated prompts.
    if ($PS_IS_ELEVATED) { 
        break
    }

    Test-OncePerDay

    # Don't clutter up the already small VSCode Console with fetch graphics
    if (! $_isvscode) {
        Invoke-Fetch
    }
}

. Initialize-ProfileEnvironment
. Initialize-MainProfile