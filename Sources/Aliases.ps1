function Invoke-Batcat {
    Write-Log -Level INFO -Message 'Invoke-Batcat called' -Body @{Args = $args }
    bat.exe --theme Dracula $args
}

function Invoke-DefaultLs {
    Write-Log -Level INFO -Message 'Invoke-DefaultLs called' -Body @{Args = $args }
    Get-ChildItem @args
}

function Invoke-DefaultLl {
    Write-Log -Level INFO -Message 'Invoke-DefaultLs called' -Body @{Args = $args }
    Get-ChildItem -Verbose @args
}

function Invoke-LsdLs {
    Write-Log -Level INFO -Message 'Invoke-LsdLs called' -Body @{Args = $args }
    lsd --almost-all --group-dirs first --icon-theme fancy $args
}

function Invoke-LsdLl {
    Write-Log -Level INFO -Message 'Invoke-LsdLl called' -Body @{Args = $args }
    lsd --almost-all -lL --size short --date relative --group-dirs first --icon-theme fancy --blocks 'permission,size,date,name' $args
}

function Invoke-Ls {
    Write-Log -Level INFO -Message 'Invoke-Ls called'

    if ($DIR_LISTING_TYPE -eq '' -or $null -eq $DIR_LISTING_TYPE) {
        Write-Log -Level WARNING -Message 'DIR_LISTING_TYPE is not set! Using default method.'
        Invoke-DefaultLs @args
    }
    elseif ($DIR_LISTING_TYPE -eq 'lsd') {
        Invoke-LsdLs $args
    }
    elseif ($DIR_LISTING_TYPE -eq 'default') {
        Invoke-DefaultLs @args
    }
    else {
        Write-Log -Level ERROR -Message "Unknown value for DIR_LISTING_TYPE: '{0}'" -Arguments $DIR_LISTING_TYPE
    }
}

function Invoke-Which {
    Write-Log -Level INFO -Message 'Invoke-Ll called. Args: {0}' -Arguments @args
    Get-Command @args
}

function Invoke-Ll {
    Write-Log -Level INFO -Message 'Invoke-Ll called'
    if ($DIR_LISTING_TYPE -eq '' -or $null -eq $DIR_LISTING_TYPE) {
        Write-Log -Level WARNING -Message 'DIR_LISTING_TYPE is not set! Using default method.'
        Invoke-DefaultLl @args
    }
    elseif ($DIR_LISTING_TYPE -eq 'lsd') {
        Invoke-LsdLl $args
    }
    elseif ($DIR_LISTING_TYPE -eq 'default') {
        Invoke-DefaultLl @args
    }
    else {
        Write-Log -Level ERROR -Message "Unknown value for DIR_LISTING_TYPE: '{0}'" -Arguments $DIR_LISTING_TYPE
    }
}

function Invoke-GitAddCommitPush {
    <#
    .SYNOPSIS
    Invoke git add, commit, and push.
    
    .DESCRIPTION
    Invokes:
        git add .
        git commit -m <CommitMessage>
        git push -u origin <git config --get init.defaultBranch>
    
    .PARAMETER CommitMessage
    The message to use for the commit.
    
    .EXAMPLE
    gacp "Setting up new repo."
    Runs:
        git add .
        git commit -m "Setting up new repo"
        git push -u origin main
    
    .NOTES
    Planning to add functionality to modify remote name and branch, and better detection
    for actual current branch name instead of using value from general git config.
    #>

    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $CommitMessage
    )

    Write-Log -Level INFO -Message 'gacp called, CommitMessage = {0}, Args = {1}' -Arguments $CommitMessage, $args

    function PrintUsage {
        Write-Host -ForegroundColor White 'gacp - git add, commit and push'

        Write-Host -ForegroundColor Yellow 'USAGE:'
        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan 'gacp ' -NoNewline
        Write-Host -ForegroundColor Blue "<CommitMsg>`n"

        Write-Host -ForegroundColor Yellow 'This will run:'
        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan 'git ' -NoNewline
        Write-Host -ForegroundColor White 'add .'

        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan 'git ' -NoNewline
        Write-Host -ForegroundColor White 'commit -m ' -NoNewline
        Write-Host -ForegroundColor Blue '<CommitMsg>'

        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan 'git ' -NoNewline
        Write-Host -ForegroundColor White 'push -u origin ' -NoNewline
        Write-Host -ForegroundColor Magenta "$(git config --get init.defaultBranch) " -NoNewline
        Write-Host -Foreground Yellow '(this is pulled from git config --get init.defaultBranch)'
    }

    if ($args.Contains('--help') -or $args.Contains('-h') -or $CommitMessage.StartsWith('--help') -or $args.Contains('-?')) {
        Write-Log -Level INFO -Message 'help or h or -? found in args, printing usage' -Arguments $status_check
        PrintUsage
        return
    }

    if ($null -eq $CommitMessage -or '' -eq $CommitMessage) {
        Write-Log -Level WARNING -Message 'CommitMessage is empty or null' -Arguments $status_check
        Write-Host -ForegroundColor Yellw "You must specify a commit message.`n"
        PrintUsage
        return
    }

    $CommitMessage | commitlint
    if ($? -ne $true) {
        Write-Log -Level WARNING -Message 'commitlint failed, early out' -Arguments $status_check
        Write-Host -ForegroundColor Yellow "Commit message failed commitlint.`n"
        if ((Confirm-YesOrNo -Description 'Commit message has failed commitlint, would you like to override and continue anyways?') -eq $false) {
            Write-Log -Level WARNING -Message 'User chose to abort' -Arguments $status_check
            Write-Host -ForegroundColor Red "Aborting GitAddCommitPush.`n"
            return
        }
        else {
            Write-Log -Level INFO -Message 'User chose to continue' -Arguments $status_check
            Write-Host -ForegroundColor Green "Continuing GitAddCommitPush with `"invalid`" commit message.`n"
        }
    }

    $status_check = (git status)
    Write-Log -Level INFO -Message 'Git status: {0}' -Arguments "$status_check"
    if ([string]::Join(' ', $status_check).Contains('nothing to commit')) {
        Write-Host -ForegroundColor Cyan "`n`nNO CHANGES FOUND TO COMMIT!`n"
        Write-Log -Level WARNING -Message 'git status reports nothing to commit, early out. status = {0}' -Arguments $status_check
        return
    }

    $bracket_reg = [regex]'\[([^\[]*)\]'
    $line = (git branch -vv) | Where-Object { $_.StartsWith('*') }
    $Branch = $line.Trim().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[1].Trim()
    $RemoteTotal = $bracket_reg.Match($line).Groups[1].Value
    $Remote = $RemoteTotal.Split('/', [StringSplitOptions]::RemoveEmptyEntries)[0]
    $RemoteBranch = $RemoteTotal.Split('/', [StringSplitOptions]::RemoveEmptyEntries)[1]
    $_msg = "Calling GACP with:`n`tCommit Message = $CommitMessage`n`tBranch = $Branch`n`tRemote = $Remote`n`tRemote Branch = $RemoteBranch`n`tRemoteTotal = $RemoteTotal"
    Write-Output $_msg
    Write-Log -Level INFO -Message "$_msg"


    git add .
        
    if (! $?) {
        Write-Error "An error has occurred while running 'git add .'!`n"
        Write-Error -ErrorRecord $_
        Write-Log -Level ERROR -Message "Error caught during 'git add .': {0}" -Arguments $_
        return
    }

    $status_check = (git status)
    Write-Log -Level INFO -Message 'Git status: {0}' -Arguments "$status_check"
    if ([string]::Join(' ', $status_check).Contains('nothing to commit')) {
        Write-Host -ForegroundColor Cyan "`n`nNO CHANGES FOUND TO COMMIT!`n"
        Write-Log -Level WARNING -Message 'git status reports nothing to commit, early out. status = {0}' -Arguments $status_check
        return
    }

    git commit -m $CommitMessage
    if (! $?) {
        Write-Error "An error has occurred while running 'git commit -m $CommitMessage'!`n"
        Write-Error -ErrorRecord $_
        Write-Log -Level ERROR -Message "Error caught during 'git commit': {0}" -Arguments $_
        return
    }

    if ($Remote -ne '' -and $RemoteBranch -ne '' -and $Branch -ne '') {
        Write-Log -Level INFO -Message 'Running git push -u Remote = {0} Branch = {1}' -Arguments "$Remote", "$Branch"
        git push -u "$Remote" "$Branch"
    }
    else {
        Write-Host -ForegroundColor Red 'Remote branch and local branch do not match!'
        Write-Log -Level ERROR -Message 'Remote branch and local branch do not match Remote = {0} Branch = {1}' -Arguments "$Remote", "$Branch"
    }
        
    if (! $?) {
        Write-Error "An error has occurred while running 'git push -u $Remote $Branch'!`n"
        Write-Error -ErrorRecord $_
        Write-Log -Level ERROR -Message "Error caught during 'git commit': {0}" -Arguments $_
        return
    }
}

Set-Alias -Name cat -Value Invoke-Batcat # -PassThru
Set-Alias -Name ls -Value Invoke-Ls # -PassThru
Set-Alias -Name ll -Value Invoke-Ll # -PassThru
Set-Alias -Name gacp -Value Invoke-GitAddCommitPush # -PassThru
Set-Alias -Name brogue -Value Start-Brogue # -PassThru
Set-Alias -Name which -Value Invoke-Which # -PassThru