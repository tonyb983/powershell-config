$Script:_TrackerCsv = (Resolve-Path 'C:\Tony\Job\JobTracker2.csv' -ErrorAction SilentlyContinue)

function Script:CheckValue($Value) {
    if ($null -eq $Value -or '' -eq $Value) {
        $false
    }
    else {
        $true
    }
}

function Script:EnsureValue($Value, $Default) {
    if (Script:CheckValue($Value)) {
        $Value
    }
    else {
        $Default
    }
}

function New-JobTrackerEntry {
    <#
    .SYNOPSIS
    Adds a new entry to the job tracker csv.
    
    .DESCRIPTION
    Adds a new entry to my job tracker csv which will then be imported into the excel version.
    
    .PARAMETER Source
    The job listing source.
    
    .PARAMETER Location
    The location of the job.
    
    .PARAMETER Company
    The company that posted the job listing.
    
    .PARAMETER Position
    The official title of the job offering.
    
    .PARAMETER Notes
    Any applicable notes for the listing.
    
    .PARAMETER Link
    A link to the job listing.
    
    .EXAMPLE
    Traditional Call:
    ❯ New-JobTrackerEntry `
        -Source 'Indeed' `
        -Location 'Rockville, MD' `
        -Company 'SomeCorp, LLC' `
        -Position 'Grunt'

    Pipeline Call:
    @{
        Source = 'Indeed'
        Location = 'Rockville, MD'
        Company = 'SomeCorp, LLC'
        Position = 'Grunt'
    } | New-JobTrackerEntry
    #>
    [CmdletBinding()]
    param (
        # The website that the job posting was found on.
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $false)]
        [ValidateSet('Indeed', 'LinkedIn', 'Glassdoor', 'Google Jobs', 'CareerBuilder', 'Monster', 'ZipRecruiter', 'Other')]
        [Alias('src')]
        [Alias('s')]
        [string]
        $Source = 'Other',
        # The website that the job posting was found on.
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $false)]
        [Alias('L')]
        [string]
        $Location = 'Unknown',
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $false)]
        [Alias('c')]
        [string]
        $Company = 'Confidential',
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $false)]
        [Alias('p')]
        [Alias('JobTitle')]
        [string]
        $Position = 'Not specified.',
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $false)]
        [Alias('n')]
        [string]
        $Notes = '',
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $false)]
        [Alias('h')]
        [string]
        $Link = ''
    )
    Begin {
        Write-Log -Level INFO -Message 'New-JobTrackerEntry Begin Block'

        if ($null -eq $Script:_TrackerCsv -or '' -eq $Script:_TrackerCsv -or ! (Test-Path $Script:_TrackerCsv -ErrorAction SilentlyContinue)) {
            $_excep = New-Object System.InvalidOperationException -ArgumentList '_TrackerCsv variable is not set or not valid, aborting New-JobTrackerEntry.'
            Write-Log -Level ERROR -Message 'JobTrackerCsv not found or _TrackerCsv variable not set! Terminating New-JobTrackerEntry.' -Body @{
                Error = $_excep
            }
            $PSCmdlet.ThrowTerminatingError($_excep)
        }
    }

    Process {
        Write-Log -Level INFO -Message 'New-JobTrackerEntry Process Block'  
        $_entry = [PSCustomObject]@{
            Timestamp = (Get-Date -UFormat '%m/%d/%Y %R')
            Source    = $Source
            Location  = $Location
            Company   = $Company
            Position  = $Position
            Notes     = $Notes
            Link      = $Link
        }
        Write-Log -Level INFO -Message 'Appending {0} to tracker.' -Arguments ($_entry.ToString()) -Body @{ Entry = $_entry }
        $_entry | Export-Csv -Path "$Script:_TrackerCsv" -Append
    }

    End {
        Write-Log -Level INFO -Message 'New-JobTrackerEntry End Block'
    }
}