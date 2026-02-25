# Script per riabilitare i vincoli
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle interessate
$tables = @(
    "MA_SaleDocDetail",
    "MA_CostAccEntries",
    "MA_SaleDocReferences",
    "MA_SaleDocPymtSched",
    "MA_SaleDocTaxSummary",
    "MA_SaleDoc",
    "MA_SaleDocSummary",
    "MA_SaleDocShipping",
    "MA_PurchaseDocDetail",
    "MA_SaleDocManufReasons",
    "MA_SaleDocNotes",
    "MA_SaleDocComponents",
    "IM_Schedules",
    "IM_SaleDocJobs",
    "MA_WMPreShippingDetails",
    "MA_BRNotaFiscalForCustomer",
    "MA_BRNotaFiscalForCustDetail",
    "MA_BRNotaFiscalForCustSummary",
    "MA_BRNotaFiscalForCustRef",
    "MA_BRNotaFiscalForCustShipping"
)

# Definizione dei database
#$databases = @("gpxnetclone","furmanetclone","vedbondifeclone")
$databases = @("vedbondifeclone")

function Invoke-SqlQuery {
    param (
        [string]$server,
        [string]$query,
        [string]$username,
        [string]$password,
        [switch]$returnResults
    )
   
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=$server;User Id=$username;Password=$password;"
   
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = $query
    $command.CommandTimeout = 300
   
    try {
        $connection.Open()
        Write-Host "Executing query..."
        
        if ($returnResults) {
            $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $adapter.SelectCommand = $command
            $dataSet = New-Object System.Data.DataSet
            $adapter.Fill($dataSet) | Out-Null
            
            # Display results
            foreach ($table in $dataSet.Tables) {
                foreach ($row in $table.Rows) {
                    $output = ""
                    foreach ($column in $table.Columns) {
                        $output += "$($column.ColumnName): $($row[$column]) | "
                    }
                    Write-Host $output.TrimEnd(" | ")
                }
            }
        } else {
            $result = $command.ExecuteNonQuery()
            Write-Host "Query executed. Rows affected: $result"
        }
    }
    catch {
        Write-Host "Error executing query: $_" -ForegroundColor Red
        throw $_
    }
    finally {
        $connection.Close()
    }
}

function Test-DataIntegrity {
    param (
        $database
    )

    Write-Host "Checking data integrity for database: $database"

    $integrityCheckScript = @"
USE [$database];

-- Check per MA_SaleDocSummary
SELECT 'MA_SaleDocSummary integrity issues:' as CheckType, COUNT(*) as IssueCount
FROM MA_SaleDocSummary s
LEFT JOIN MA_SaleDoc d ON s.SaleDocId = d.SaleDocId
WHERE d.SaleDocId IS NULL;

-- Check per MA_SaleDocNotes
SELECT 'MA_SaleDocNotes integrity issues:' as CheckType, COUNT(*) as IssueCount
FROM MA_SaleDocNotes n
LEFT JOIN MA_SaleDoc d ON n.SaleDocId = d.SaleDocId
WHERE d.SaleDocId IS NULL;

-- Check per MA_SaleDocDetail
SELECT 'MA_SaleDocDetail integrity issues:' as CheckType, COUNT(*) as IssueCount
FROM MA_SaleDocDetail det
LEFT JOIN MA_SaleDoc d ON det.SaleDocId = d.SaleDocId
WHERE d.SaleDocId IS NULL;

-- Check per altre tabelle correlate
SELECT 'MA_SaleDocReferences integrity issues:' as CheckType, COUNT(*) as IssueCount
FROM MA_SaleDocReferences r
LEFT JOIN MA_SaleDoc d ON r.SaleDocId = d.SaleDocId
WHERE d.SaleDocId IS NULL;
"@

    try {
        Invoke-SqlQuery -server $sqlServer -query $integrityCheckScript -username $username -password $password -returnResults
        Write-Host "Data integrity check completed for $database" -ForegroundColor Green
    }
    catch {
        Write-Host "Error checking data integrity for $database : $_" -ForegroundColor Red
    }
}

function Remove-OrphanedRecords {
    param (
        $database
    )

    Write-Host "Cleaning orphaned records for database: $database"

    $cleanupScript = @"
USE [$database];
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Elimina record orfani da MA_SaleDocSummary
    DELETE s FROM MA_SaleDocSummary s
    LEFT JOIN MA_SaleDoc d ON s.SaleDocId = d.SaleDocId
    WHERE d.SaleDocId IS NULL;
    
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' orphaned records from MA_SaleDocSummary';
    
    -- Elimina record orfani da MA_SaleDocNotes
    DELETE n FROM MA_SaleDocNotes n
    LEFT JOIN MA_SaleDoc d ON n.SaleDocId = d.SaleDocId
    WHERE d.SaleDocId IS NULL;
    
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' orphaned records from MA_SaleDocNotes';
    
    -- Elimina record orfani da MA_SaleDocDetail
    DELETE det FROM MA_SaleDocDetail det
    LEFT JOIN MA_SaleDoc d ON det.SaleDocId = d.SaleDocId
    WHERE d.SaleDocId IS NULL;
    
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' orphaned records from MA_SaleDocDetail';
    
    -- Elimina record orfani da MA_SaleDocReferences
    DELETE r FROM MA_SaleDocReferences r
    LEFT JOIN MA_SaleDoc d ON r.SaleDocId = d.SaleDocId
    WHERE d.SaleDocId IS NULL;
    
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' orphaned records from MA_SaleDocReferences';
    
    -- Elimina record orfani da MA_SaleDocPymtSched
    DELETE p FROM MA_SaleDocPymtSched p
    LEFT JOIN MA_SaleDoc d ON p.SaleDocId = d.SaleDocId
    WHERE d.SaleDocId IS NULL;
    
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' orphaned records from MA_SaleDocPymtSched';
    
    -- Elimina record orfani da MA_SaleDocTaxSummary
    DELETE t FROM MA_SaleDocTaxSummary t
    LEFT JOIN MA_SaleDoc d ON t.SaleDocId = d.SaleDocId
    WHERE d.SaleDocId IS NULL;
    
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' orphaned records from MA_SaleDocTaxSummary';
    
    -- Elimina record orfani da MA_SaleDocShipping
    DELETE sh FROM MA_SaleDocShipping sh
    LEFT JOIN MA_SaleDoc d ON sh.SaleDocId = d.SaleDocId
    WHERE d.SaleDocId IS NULL;
    
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' orphaned records from MA_SaleDocShipping';
    
    COMMIT TRANSACTION;
    PRINT 'Cleanup completed successfully for $database';
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    RAISERROR (@ErrorMessage, 16, 1)
END CATCH
"@

    try {
        Invoke-SqlQuery -server $sqlServer -query $cleanupScript -username $username -password $password
        Write-Host "Successfully cleaned orphaned records for $database" -ForegroundColor Green
    }
    catch {
        Write-Host "Error cleaning orphaned records for $database : $_" -ForegroundColor Red
    }
}

function Enable-Constraints {
    param (
        $database
    )

    Write-Host "Processing database: $database"

    $tablesList = $tables -join "','"
    $sqlScript = @"
USE [$database];
BEGIN TRY
   -- Trova e riabilita tutti i vincoli FK relativi alle tabelle specificate
   DECLARE @sql nvarchar(max) = ''
   SELECT @sql = @sql + 
       'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))
       + '.' + QUOTENAME(OBJECT_NAME(parent_object_id)) 
       + ' WITH CHECK CHECK CONSTRAINT '
       + QUOTENAME(name) + ';' + CHAR(13)
   FROM sys.foreign_keys
   WHERE OBJECT_NAME(parent_object_id) IN 
       ('$tablesList')
   OR OBJECT_NAME(referenced_object_id) IN 
       ('$tablesList')

   EXEC sp_executesql @sql
   PRINT 'Successfully enabled constraints for $database'
END TRY
BEGIN CATCH
   DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
   RAISERROR (@ErrorMessage, 16, 1)
END CATCH
"@

    try {
        Invoke-SqlQuery -server $sqlServer -query $sqlScript -username $username -password $password
        Write-Host "Successfully enabled constraints for $database" -ForegroundColor Green
    }
    catch {
        Write-Host "Error enabling constraints for $database : $_" -ForegroundColor Red
        return $false
    }
    return $true
}

# Main execution
Write-Host "Starting constraint enable process..."

foreach ($database in $databases) {
    Write-Host "`n=== Processing Database: $database ===" -ForegroundColor Yellow
    
    # Step 1: Check data integrity
    Write-Host "`nStep 1: Checking data integrity..." -ForegroundColor Cyan
    Test-DataIntegrity -database $database
    
    # Step 2: Try to enable constraints first
    Write-Host "`nStep 2: Attempting to enable constraints..." -ForegroundColor Cyan
    $success = Enable-Constraints -database $database
    
    # Step 3: If failed, clean orphaned records and retry
    if (-not $success) {
        Write-Host "`nStep 3: Constraint enable failed, cleaning orphaned records..." -ForegroundColor Yellow
        Remove-OrphanedRecords -database $database
        
        Write-Host "`nStep 4: Retrying constraint enable after cleanup..." -ForegroundColor Cyan
        $success = Enable-Constraints -database $database
        
        if (-not $success) {
            Write-Host "Failed to enable constraints for $database even after cleanup" -ForegroundColor Red
            
            # Final integrity check to see what's still wrong
            Write-Host "`nFinal integrity check for database $database" -ForegroundColor Magenta
            Test-DataIntegrity -database $database
        }
    }
}

Write-Host "`nConstraint enable process completed." -ForegroundColor Green