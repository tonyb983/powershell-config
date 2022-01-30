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

    if ($args.Contains('--help') -or $args.Contains('-h') -or $CommitMessage.StartsWith('--help')) {
        PrintUsage
        return
    }

    if ($null -eq $CommitMessage -or '' -eq $CommitMessage) {
        Write-Host -ForegroundColor Red "Please specify a commit message.`n"
        PrintUsage
        return
    }

    
    $bracket_reg = [regex]'\[([^\[]*)\]'
    $line = (git branch -vv) | where { $_.StartsWith('*')}
    $Branch = $line.Trim().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[1].Trim()
    $Remote_temp = $bracket_reg.Match($line).Groups[1].Value
    $Remote = $Remote_temp.Split('/', [StringSplitOptions]::RemoveEmptyEntries)[0]
    $RemoteBranch = $Remote_temp.Split('/', [StringSplitOptions]::RemoveEmptyEntries)[1]
    Write-Output "Calling GACP with:`n`tCommit Message = $CommitMessage`n`tBranch = $Branch`n`tRemote = $Remote`n`tRemote Branch = $RemoteBranch"

    try {
        git add .    
    }
    catch {
        Write-Error "An error has occurred while running 'git add .'!`n"
        Write-Error -ErrorRecord $_
        return
    }
    try {
        git commit -m $CommitMessage
    }
    catch {
        Write-Error "An error has occurred while running 'git commit -m $CommitMessage'!`n"
        Write-Error -ErrorRecord $_
        return
    }
    try {
        if ($Remote -ne "" -and $RemoteBranch -ne "" -and $Branch -ne "") {
            git push -u $Remote $Branch 
        } else {
            Write-Output "Remote branch and local branch do not match!"
        }
    }
    catch {
        Write-Error "An error has occurred while running 'git push -u origin $(git config --get init.defaultBranch)'!`n"
        Write-Error -ErrorRecord $_
        return
    }
}

function Start-Brogue {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Params
    )

    $_params = ($Params -join ' ')
    Write-Log -Level INFO -Message 'Start-Brogue called. RawParams = {0}, FixedParams = {1}' -Arguments $Params, $_params
    $_broguepath = 'C:\Tony\Misc\BrogueCE-windows\brogue-cmd.bat'
    Invoke-Expression "$_broguepath $_params"
}

Set-Alias -Name cat -Value Invoke-Batcat # -PassThru
Set-Alias -Name ls -Value Invoke-Ls # -PassThru
Set-Alias -Name ll -Value Invoke-Ll # -PassThru
Set-Alias -Name gacp -Value Invoke-GitAddCommitPush # -PassThru
Set-Alias -Name brogue -Value Start-Brogue # -PassThru
Set-Alias -Name which -Value Invoke-Which # -PassThru