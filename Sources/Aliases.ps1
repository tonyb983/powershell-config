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

Set-Alias -Name cat -Value Invoke-Batcat
Set-Alias -Name ls -Value Invoke-Ls
Set-Alias -Name ll -Value Invoke-Ll