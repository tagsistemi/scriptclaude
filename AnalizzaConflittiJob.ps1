<#
.SYNOPSIS
    Analyzes the "Job" field across multiple databases to identify potential conflicts.
.DESCRIPTION
    This script connects to SQL Server and examines the "Job" field in MA_Jobs tables
    across gpxnetclone, vedbondifeclone, and furmanetclone databases to detect any
    conflicting job IDs that could cause problems during data migration to Vedmaster.
.NOTES
    Author: System Administrator
    Date: September 9, 2025
    Requirement: SQL Server 2008 compatibility
#>

# SQL Server connection parameters
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$connectionTimeout = 30
$queryTimeout = 300

# Source database names
$sourceDBs = @("gpxnetclone", "vedbondifeclone", "furmanetclone")

# Prepare SQL connection string with SQL authentication
$connectionString = "Server=$ServerInstance;User Id=$SqlUsername;Password=$SqlPassword;Connect Timeout=$connectionTimeout"

function Test-TableExists {
    param (
        [System.Data.SqlClient.SqlConnection]$Connection,
        [string]$Database,
        [string]$Table
    )
    
    $sql = "SELECT COUNT(*) FROM [$Database].INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$Table' AND TABLE_TYPE = 'BASE TABLE'"
    $command = New-Object System.Data.SqlClient.SqlCommand($sql, $Connection)
    $result = $command.ExecuteScalar()
    
    return ($result -gt 0)
}

function Get-JobValues {
    param (
        [System.Data.SqlClient.SqlConnection]$Connection,
        [string]$Database
    )
    
    Write-Host "Retrieving Job values from [$Database]..." -ForegroundColor Cyan
    
    $sql = "SELECT ISNULL(Job, '') as Job FROM [$Database].[dbo].[MA_Jobs]"
    $command = New-Object System.Data.SqlClient.SqlCommand($sql, $Connection)
    $command.CommandTimeout = $queryTimeout
    
    $dataTable = New-Object System.Data.DataTable
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    
    try {
        $adapter.Fill($dataTable) | Out-Null
        Write-Host "  - Retrieved $($dataTable.Rows.Count) job records from [$Database]" -ForegroundColor Green
        
        # Force empty strings for NULL values
        foreach ($row in $dataTable.Rows) {
            if ($null -eq $row["Job"] -or $row["Job"] -eq [System.DBNull]::Value) {
                $row["Job"] = "<NULL>"
            }
        }
        
        return $dataTable
    }
    catch {
        Write-Warning "Failed to retrieve data from [$Database]: $_"
        return New-Object System.Data.DataTable
    }
}

function Test-JobConflicts {
    param (
        [System.Data.SqlClient.SqlConnection]$Connection,
        [string[]]$Databases
    )
    
    Write-Host "`n=== JOB CONFLICT ANALYSIS ===" -ForegroundColor Yellow
    
    # Create dictionaries to store jobs from each database
    $allJobs = @{}
    $jobCounts = @{}
    $ErrorActionPreference = 'Continue'  # Don't stop on errors
    
    foreach ($db in $Databases) {
        if (Test-TableExists -Connection $Connection -Database $db -Table "MA_Jobs") {
            $jobData = Get-JobValues -Connection $Connection -Database $db
            $allJobs[$db] = $jobData
            $jobCounts[$db] = $jobData.Rows.Count
        }
        else {
            Write-Warning "Table [MA_Jobs] does not exist in database [$db]. Skipping."
        }
    }
    
    # Create a combined dictionary of all job values across all databases
    $combinedJobList = @{}
    $conflictingJobs = @{}
    
    foreach ($db in $allJobs.Keys) {
        if ($null -eq $allJobs[$db] -or $null -eq $allJobs[$db].Rows) {
            Write-Warning "No rows found or null data returned for database [$db]"
            continue
        }
        
        foreach ($row in $allJobs[$db].Rows) {
            try {
                # Handle null Job value
                if ($null -eq $row -or $null -eq $row["Job"] -or $row["Job"] -eq [System.DBNull]::Value) {
                    $jobValue = "<NULL>"
                } else {
                    $jobValue = $row["Job"].ToString()
                }
                
                # Skip empty values
                if ([string]::IsNullOrWhiteSpace($jobValue)) {
                    $jobValue = "<EMPTY>"
                }
                
                if (-not $combinedJobList.ContainsKey($jobValue)) {
                    $combinedJobList[$jobValue] = @($db)
                }
                else {
                    $combinedJobList[$jobValue] += $db
                    $conflictingJobs[$jobValue] = $combinedJobList[$jobValue]
                }
            }
            catch {
                Write-Warning "Error processing row in database [$db]: $_"
                continue
            }
        }
    }
    
    # Report total job counts
    Write-Host "`nTotal Job Counts by Database:" -ForegroundColor Cyan
    foreach ($db in $jobCounts.Keys | Sort-Object) {
        Write-Host "  - $db : $($jobCounts[$db]) jobs" -ForegroundColor White
    }
    
    # Report conflicts
    Write-Host "`nConflict Analysis:" -ForegroundColor Cyan
    $conflictCount = $conflictingJobs.Count
    
    if ($conflictCount -eq 0) {
        Write-Host "  No conflicts detected! All Job values are unique across databases." -ForegroundColor Green
    }
    else {
        Write-Host "  Detected $conflictCount conflicting Job values!" -ForegroundColor Red
        Write-Host "  The following Job values exist in multiple databases:" -ForegroundColor Red
        
        $i = 1
        foreach ($jobValue in $conflictingJobs.Keys | Sort-Object) {
            $dbs = $conflictingJobs[$jobValue] -join ", "
            Write-Host "    $i. Job = '$jobValue' exists in: $dbs" -ForegroundColor Yellow
            $i++
            
            # Show which databases contain the conflicting job
            foreach ($db in $conflictingJobs[$jobValue]) {
                Write-Host "       - Found in database: [$db]" -ForegroundColor DarkYellow
            }
        }
        
        # Export conflict details to CSV for further analysis
        $conflictRecords = New-Object System.Collections.ArrayList
        
        foreach ($jobValue in $conflictingJobs.Keys) {
            foreach ($db in $conflictingJobs[$jobValue]) {
                $record = [PSCustomObject]@{
                    Job = $jobValue
                    Database = $db
                }
                [void]$conflictRecords.Add($record)
            }
        }
        
        $csvPath = "e:\MigrazioneVed\Scripts\JobConflicts_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $conflictRecords | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Host "`nConflict details exported to: $csvPath" -ForegroundColor Cyan
        
        Write-Host "`nSuggested Prefixes for Migration:" -ForegroundColor Cyan
        Write-Host "  - gpxnetclone: 'GPX_'" -ForegroundColor White
        Write-Host "  - vedbondifeclone: 'BDF_'" -ForegroundColor White
        Write-Host "  - furmanetclone: 'FRM_'" -ForegroundColor White
        
        Write-Host "`nThese prefixes should be applied to all Job values during migration to prevent conflicts." -ForegroundColor Yellow
    }
    
    # Check for potential conflicts after adding prefixes
    Write-Host "`nChecking for potential conflicts after adding recommended prefixes..." -ForegroundColor Cyan
    
    $prefixedJobs = @{}
    $prefixConflicts = $false
    
    foreach ($db in $allJobs.Keys) {
        $prefix = switch ($db) {
            "gpxnetclone" { "GPX_" }
            "vedbondifeclone" { "BDF_" }
            "furmanetclone" { "FRM_" }
            default { "UNK_" }
        }
        
        if ($null -eq $allJobs[$db] -or $null -eq $allJobs[$db].Rows) {
            Write-Warning "No rows found or null data returned for database [$db] during prefix analysis"
            continue
        }
        
        foreach ($row in $allJobs[$db].Rows) {
            try {
                # Handle null Job value
                if ($null -eq $row -or $null -eq $row["Job"] -or $row["Job"] -eq [System.DBNull]::Value) {
                    $jobValue = "<NULL>"
                } else {
                    $jobValue = $row["Job"].ToString()
                }
                
                # Skip empty values
                if ([string]::IsNullOrWhiteSpace($jobValue)) {
                    $jobValue = "<EMPTY>"
                }
                
                $prefixedJob = $prefix + $jobValue
                
                if (-not $prefixedJobs.ContainsKey($prefixedJob)) {
                    $prefixedJobs[$prefixedJob] = $db
                }
                else {
                    $prefixConflicts = $true
                    Write-Host "  WARNING: Prefixed job '$prefixedJob' would still conflict between databases!" -ForegroundColor Red
                }
            }
            catch {
                Write-Warning "Error processing prefixed job in database [$db]: $_"
                continue
            }
        }
    }
    
    if (-not $prefixConflicts) {
        Write-Host "  All conflicts would be resolved by adding the recommended prefixes." -ForegroundColor Green
    }
}

try {
    Write-Host "Connecting to SQL Server 2008 on server '$ServerInstance'..." -ForegroundColor Cyan
    
    # Create SQL connection
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "Connection established successfully." -ForegroundColor Green
    
    # Check if all source databases exist
    $databasesExist = $true
    foreach ($db in $sourceDBs) {
        $checkDbSql = "SELECT COUNT(*) FROM sys.databases WHERE name = '$db'"
        $command = New-Object System.Data.SqlClient.SqlCommand($checkDbSql, $connection)
        $dbExists = ($command.ExecuteScalar() -gt 0)
        
        if (-not $dbExists) {
            Write-Error "Source database '$db' does not exist!"
            $databasesExist = $false
        }
    }
    
    if ($databasesExist) {
        # Analyze job conflicts
        Test-JobConflicts -Connection $connection -Databases $sourceDBs
    }
    
    # Check if there's a need to analyze conflicts with existing records in Vedmaster
    $checkVedmasterSql = "SELECT COUNT(*) FROM sys.databases WHERE name = 'Vedmaster'"
    $command = New-Object System.Data.SqlClient.SqlCommand($checkVedmasterSql, $connection)
    $vedmasterExists = ($command.ExecuteScalar() -gt 0)
    
    if ($vedmasterExists) {
        Write-Host "`nWould you like to check for conflicts with existing jobs in Vedmaster? (Y/N)" -ForegroundColor Yellow
        $checkVedmaster = Read-Host
        
        if ($checkVedmaster -eq 'Y') {
            # Add Vedmaster to the list of databases to analyze
            $allDbs = $sourceDBs + @("Vedmaster")
            Test-JobConflicts -Connection $connection -Databases $allDbs
        }
    }
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Close the connection
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
        Write-Host "Database connection closed." -ForegroundColor DarkGray
    }
}

Write-Host "`nAnalysis complete. Review the results to identify and address potential conflicts before migration." -ForegroundColor Green
