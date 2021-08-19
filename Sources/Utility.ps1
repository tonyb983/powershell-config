function Test-Variable {
    <#
.SYNOPSIS
Tests if variable with 'Name' exists.

.DESCRIPTION
Quick way to run Get-Variable with -ErrorAction SilentlyContinue. Returns $true if variable is set, $false otherwise.

.PARAMETER Name
The name of the variable to test.

.EXAMPLE
$SomeVar = 100
Test-Variable SomeVar # Returns $true
Test-Variable NonExistentVariable # returns $false

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    if (Get-Variable -Name $Name -ErrorAction SilentlyContinue) {
        $true
    }
    else {
        $false
    }
}

function Test-FileExists {
    <#
.SYNOPSIS
Tests if file at 'Path' exists.

.DESCRIPTION
Quick way to run Test-Path with -PathType Leaf. Returns $true if file exists, $false otherwise.

.PARAMETER Path
The path to test.

.EXAMPLE
Test-FileExists .\FileThatExists.txt      # Returns $true
Test-FileExists .\FileThatDoesntExist.txt # returns $false
#>
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    if (Test-Path -Path $Path -PathType Leaf) {
        $true
    }
    else {
        $false
    }
}

function Test-DirExists {
    <#
.SYNOPSIS
Tests if directory at 'Path' exists.

.DESCRIPTION
Quick way to run Test-Path with -PathType Container. Returns $true if directory exists, $false otherwise.

.PARAMETER Path
The path to test.

.EXAMPLE
Test-DirExists .\DirThatExists       # Returns $true
Test-DirExists .\DirThatDoesntExist  # returns $false
#>
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    if (Test-Path -Path $Path -PathType Container) {
        $true
    }
    else {
        $false
    }
}

function Get-DownloadFolder {
    (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
}

function Edit-Profile {
    Write-Host 'Opening profile in VSCode...'
    $_target = (Test-Variable PROFILE_DIR) ? $PROFILE_DIR : (Split-Path $PROFILE)
    Write-Host ([string]::Format('Target: {0}', $_target))

    $_wkspace = Get-ChildItem -Path "$_target" -Filter '*.code-workspace' -File -ErrorAction SilentlyContinue

    if ($null -eq $_wkspace) {
        Write-Host 'code-workspace not found, opening directory.'
        code $PROFILE_DIR
    }
    else {
        Write-Host ([string]::Format('Workspace Found: {0}', $_wkspace.FullName))
        code $_wkspace
    }
    
}

function Invoke-Fetch {
    # Runs slow...
    # winfetch
    macchina -t (Get-Random Hydrogen, Helium, Lithium, Beryllium, Boron) --small-ascii -prR
}