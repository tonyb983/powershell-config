function Invoke-Batcat {
    bat.exe --theme Dracula $args
}

function Invoke-DefaultLs {
    Get-ChildItem @args
}

function Invoke-DefaultLl {
    Get-ChildItem -Verbose @args
}

function Invoke-LsdLs {
    lsd --almost-all --group-dirs first --icon-theme fancy $args
}

function Invoke-LsdLl {
    lsd --almost-all -lL --size short --date relative --group-dirs first --icon-theme fancy --blocks 'permission,size,date,name' $args
}

function Invoke-Ls {
    if ($DIR_LISTING_TYPE -eq '' -or $null -eq $DIR_LISTING_TYPE) {
        Write-Host 'DIR_LISTING_TYPE is not set! Using default method.'
        Invoke-DefaultLs @args
    }
    elseif ($DIR_LISTING_TYPE -eq 'lsd') {
        Invoke-LsdLs $args
    }
    elseif ($DIR_LISTING_TYPE -eq 'default') {
        Invoke-DefaultLs @args
    }
    else {
        Write-Host "Unknown value for DIR_LISTING_TYPE: '$DIR_LISTING_TYPE'"
    }
}

function Invoke-Ll {
    if ($DIR_LISTING_TYPE -eq '' -or $null -eq $DIR_LISTING_TYPE) {
        Write-Host 'DIR_LISTING_TYPE is not set! Using default method.'
        Invoke-DefaultLl @args
    }
    elseif ($DIR_LISTING_TYPE -eq 'lsd') {
        Invoke-LsdLl $args
    }
    elseif ($DIR_LISTING_TYPE -eq 'default') {
        Invoke-DefaultLl @args
    }
    else {
        Write-Host "Unknown value for DIR_LISTING_TYPE: '$DIR_LISTING_TYPE'"
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

    Write-Output "gacp called, CommitMessage = $CommitMessage, Args Count = ${args.Count()}, Args = $args"

    function PrintUsage {
        Write-Host -ForegroundColor White "gacp - git add, commit and push"

        Write-Host -ForegroundColor Yellow "USAGE:"
        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan "gacp " -NoNewline
        Write-Host -ForegroundColor Blue "<CommitMsg>`n"

        Write-Host -ForegroundColor Yellow "This will run:"
        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan "git " -NoNewline
        Write-Host -ForegroundColor White "add ."

        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan "git " -NoNewline
        Write-Host -ForegroundColor White "commit -m " -NoNewline
        Write-Host -ForegroundColor Blue "<CommitMsg>"

        Write-Host -ForegroundColor Green "`t❯ " -NoNewline
        Write-Host -ForegroundColor Cyan "git " -NoNewline
        Write-Host -ForegroundColor White "push -u origin " -NoNewline
        Write-Host -ForegroundColor Magenta "$(git config --get init.defaultBranch) " -NoNewline
        Write-Host -Foreground Yellow "(this is pulled from git config --get init.defaultBranch)"
    }

    if ($args.Contains('--help') -or $args.Contains('-h') -or $CommitMessage.StartsWith('--help')) {
        PrintUsage
        return
    }

    if ($null -eq $CommitMessage -or '' -eq $CommitMessage) {
        Write-Host -ForegroundColor Red "Please specify a commit message.`n"
        PrintUsage
        return
    }

    git add .
    git commit -m "$CommitMessage"
    git push -u origin "$(git config --get init.defaultBranch)"
}

Set-Alias -Name cat -Value Invoke-Batcat
Set-Alias -Name ls -Value Invoke-Ls
Set-Alias -Name ll -Value Invoke-Ll
Set-Alias -Name gacp -Value Invoke-GitAddCommitPush