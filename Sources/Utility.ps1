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
    Write-Log -Level INFO -Message 'Test-Variable called, Name = {0}' -Arguments $Name

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
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to one or more locations.')]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )
    Write-Log -Level INFO -Message 'Test-FileExists called, Path = {0}' -Arguments $Path

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
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to one or more locations.')]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )
    Write-Log -Level INFO -Message 'Test-DirExists called, Path = {0}' -Arguments $Path

    if (Test-Path -Path $Path -PathType Container) {
        $true
    }
    else {
        $false
    }
}

function Get-DownloadFolder {
    Write-Log -Level INFO -Message 'Get-DownloadFolder called'
    (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
}

function Edit-Profile {
    Write-Log -Level INFO -Message 'Edit-Profile called'
    Write-Host 'Opening profile in VSCode...'
    $_target = (Test-Variable PROFILE_DIR) ? $PROFILE_DIR : (Split-Path $PROFILE)
    Write-Log -Level INFO -Message 'Target = {0}' -Arguments $_target

    $_wkspace = Get-ChildItem -Path "$_target" -Filter '*.code-workspace' -File -ErrorAction SilentlyContinue
    Write-Log -Level INFO -Message 'Workspace = {0}' -Arguments $_wkspace

    if ($null -eq $_wkspace) {
        Write-Host 'code-workspace not found, opening profile directory.'
        code -n $PROFILE_DIR
    }
    else {
        Write-Host ('Workspace Found: {0}' -f $_wkspace.FullName)
        code -n $_wkspace
    }
    
}

function Invoke-Fetch {
    Write-Log -Level INFO -Message 'Invoke-Fetch called'
    # Runs slow...
    # winfetch
    macchina -c $PROFILE_DIR/Configs/macchina.config
}

function Get-FileEncoding {
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string]
        $Path
    )

    Process {
        $bom = New-Object -TypeName System.Byte[](4)
        
        $file = New-Object System.IO.FileStream($Path, 'Open', 'Read')
    
        $null = $file.Read($bom, 0, 4)
        $file.Close()
        $file.Dispose()
    
        $enc = [Text.Encoding]::ASCII
        if ($bom[0] -eq 0x2b -and $bom[1] -eq 0x2f -and $bom[2] -eq 0x76) 
        { $enc = [Text.Encoding]::UTF7 }
        if ($bom[0] -eq 0xff -and $bom[1] -eq 0xfe) 
        { $enc = [Text.Encoding]::Unicode }
        if ($bom[0] -eq 0xfe -and $bom[1] -eq 0xff) 
        { $enc = [Text.Encoding]::BigEndianUnicode }
        if ($bom[0] -eq 0x00 -and $bom[1] -eq 0x00 -and $bom[2] -eq 0xfe -and $bom[3] -eq 0xff) 
        { $enc = [Text.Encoding]::UTF32 }
        if ($bom[0] -eq 0xef -and $bom[1] -eq 0xbb -and $bom[2] -eq 0xbf) 
        { $enc = [Text.Encoding]::UTF8 }
        
        [PSCustomObject]@{
            Encoding = $enc
            Path     = $Path
        }
    }
}

function Protect-String {
    <#
  .SYNOPSIS
    Convert String to textual form of SecureString
  .PARAMETER String
    String to convert
  .OUTPUTS
    String
  .NOTES
    Author: MVKozlov
#>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$String
    )
    PROCESS {
        $String | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
    }
}

function Unprotect-String {
    <#
  .SYNOPSIS
    Convert SecureString to string
  .PARAMETER String
    String to convert (textual form of SecureString)
  .PARAMETER SecureString
    SecureString to convert
  .OUTPUTS
    String
  .NOTES
    Author: MVKozlov
#>
    [CmdletBinding(DefaultParameterSetName = 's')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 's')]
        [string]$String,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'ss')]
        [SecureString]$SecureString
    )
    PROCESS {
        if ($String) {
            $SecureString = $String | ConvertTo-SecureString
        }
        if ($SecureString) {
            (New-Object System.Net.NetworkCredential '', ($SecureString)).Password
        }
    }
}

function Confirm-YesOrNo {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter()]
        [string]
        $Title = 'Confirm Operation',
        [Parameter()]
        [string]
        $Description = 'Are you sure you would like to continue?',
        [Parameter()]
        [string]
        $PositiveOption = '&Yes',
        [Parameter()]
        [string]
        $PositiveDescription = 'Proceed with operation',
        [string]
        $NegativeOption = '&No',
        [Parameter()]
        [string]
        $NegativeDescription = 'Abort operation',
        [bool]
        $DefaultNegative = $true
    )

    $_yes = New-Object System.Management.Automation.Host.ChoiceDescription "$PositiveOption", "$PositiveDescription"
    $_no = New-Object System.Management.Automation.Host.ChoiceDescription "$NegativeOption", "$NegativeDescription"
    $_default = $DefaultNegative ? 1 : 0

    $_answer = $Host.UI.PromptForChoice($Title, $Description, @($_yes, $_no), $_default)

    if ($_answer -eq 0) {
        return $true
    }
    else {
        return $false
    }
}

function Test-IsPromptElevated {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Host 'This prompt seems NOT ELEVATED.'
    }
    else {
        Write-Host 'This prompt seems super ELEVATED.'
    }
}

function Get-CoinFlip {
    $_res = @(0, 1) | Get-Random

    if ($_res -eq 0) {
        return $false
    }
    else {
        return $true
    }
}

function Test-EarlyReturn {
    Write-Host 'Starting Test-EarlyReturn'

    $_a = Get-CoinFlip
    Write-Host 'Coin Flip 1'
    if ($_a) {
        Write-Host 'Coin flip was heads, returning early'
        return
    }
    else {
        Write-Host 'Coin flip was tails, continuing'
    }

    $_a = Get-CoinFlip
    Write-Host 'Coin Flip 2'
    if ($_a) {
        Write-Host 'Coin flip was heads, returning early'
        return
    }
    else {
        Write-Host 'Coin flip was tails, continuing'
    }

    $_a = Get-CoinFlip
    Write-Host 'Coin Flip 3'
    if ($_a) {
        Write-Host 'Coin flip was heads, returning early'
        return
    }
    else {
        Write-Host 'Coin flip was tails, continuing'
    }

    $_a = Get-CoinFlip
    Write-Host 'Coin Flip 4'
    if ($_a) {
        Write-Host 'Coin flip was heads, returning early'
        return
    }
    else {
        Write-Host 'Coin flip was tails, continuing'
    }

    $_a = Get-CoinFlip
    Write-Host 'Coin Flip 5'
    if ($_a) {
        Write-Host 'Coin flip was heads, returning early'
        return
    }
    else {
        Write-Host 'Coin flip was tails, continuing'
    }

    Write-Host 'Wow, this only happens in 3.125% of runs!'
}

<#
.SYNOPSIS
    Runs a cargo command in this and all sub-projects.
.DESCRIPTION
    Runs a cargo command in the current directory and any sub directories that are cargo projects.
.EXAMPLE
    Invoke-CargoOnAll { cargo build }
    Runs cargo build in the current directory and any sub-directories that contain a Cargo.toml.
    Alias: carga
.INPUTS
    Block - A block of code to run in each cargo project.
.OUTPUTS
    Output from the cargo executions.
.NOTES
    Simple function that gathers any directories that contain a Cargo.toml file and runs the
    given block of code in it. It is safe in that it uses 
#>
function Invoke-CargoOnAll {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ScriptBlock]
        $Block,
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [uint16]
        $Depth = [uint16]::MaxValue
    )

    $all_dirs = (Get-ChildItem $pwd -Directory -Recurse -Depth $Depth -Exclude 'target', '.*')
    # Write-Output "Found $($all_dirs.Count) total dirs."
    $sub_dirs = $all_dirs | Where-Object -FilterScript { Test-Path (Join-Path $_ 'Cargo.toml') }
    $dirs = @()
    $dirs += $sub_dirs
    if (Test-Path .\Cargo.toml) {
        $dirs += (Get-Item $pwd)
    }
    # Write-Output "Found $($dirs.Count) Cargo dirs:"
    # $dirs | Out-String

    $dirs | ForEach-Object {
        Push-Location $_
        try {
            Write-Output @"

=======================$('=' * $_.Name.Length)=====
    Running command for $($_.Name)
=======================$('=' * $_.Name.Length)=====

"@
            & $Block
        }
        finally {
            Pop-Location
        }
    }
}

Set-Alias -Name carga -Value Invoke-CargoOnAll # -PassThru