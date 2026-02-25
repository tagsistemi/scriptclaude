# Script per incrementare SaleOrdId in diversi database
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle da aggiornare
$tables = @(
    "IM_WorkingReportsDetails",
    "IM_WorkingReportsActualities",
    "IM_WorkingReports", 
    "IM_WorkingReportsSummary",
    "IM_WorkingReportsStat",
    "IM_WorkingReportsDocuments",
    "IM_WorkingReportsReferences"
)

# Definizione dei database e relativi incrementi
$databaseConfigs = @{
    "gpxnetclone"     = 400000
    "furmanetclone"   = 500000
    "vedbondifeclone" = 600000
}

function Execute-SqlQuery {
    param (
        [string]$server,
        [string]$database,
        [string]$query,
        [string]$username,
        [string]$password
    )

    $connectionString = "Server=$server;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString

    $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $command.CommandTimeout = 300

    try {
        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
        $connection.Open()
        $command.ExecuteNonQuery()
    }
    catch {
        Write-Error $_.Exception.Message
        throw $_
    }
    finally {
        if ($connection.State -eq [System.Data.ConnectionState]::Open) {
            $connection.Close()
        }
    }
}

# Funzione per generare e eseguire lo script SQL
function Update-SaleOrdId {
    param (
        $database,
        $increment
    )
    Write-Host "Processing database: $database with increment: $increment"

    # Crea la tabella TAG_CrMaps se non esiste
    $createTableQuery = @"
   USE [$database]
   IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAG_CrMaps]') AND type in (N'U'))
   BEGIN
       CREATE TABLE [dbo].[TAG_CrMaps](
           [OldId] [int] NOT NULL,
           [DocumentType] [int] NOT NULL,
           [NewDocId] [int] NOT NULL
       )
   END
"@

    try {
        Execute-SqlQuery -server $sqlServer -database "master" -query $createTableQuery -username $username -password $password
        Write-Host "Successfully created or verified TAG_CrMaps table in $database" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating TAG_CrMaps table in $database : $_" -ForegroundColor Red
        return
    }

    # Inserisci i mapping prima dell'update
    $insertMappingQuery = @"
   USE [$database]
   BEGIN TRY
       BEGIN TRANSACTION;
       
       -- Prima elimina i record esistenti per il tipo documento specifico
       DELETE FROM TAG_CrMaps 
       WHERE DocumentType = 3801188;

       COMMIT TRANSACTION;
   END TRY
   BEGIN CATCH
       IF @@TRANCOUNT > 0
           ROLLBACK TRANSACTION;

       DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
       DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
       DECLARE @ErrorState INT = ERROR_STATE();

       RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
   END CATCH
"@

    try {
        Execute-SqlQuery -server $sqlServer -database "master" -query $insertMappingQuery -username $username -password $password
        Write-Host "Successfully inserted mappings in $database" -ForegroundColor Green
    }
    catch {
        Write-Host "Error inserting mappings in $database : $_" -ForegroundColor Red
        return
    }

    # Aggiorna le tabelle
    foreach ($table in $tables) {
        $updateQuery = @"
       USE [$database]
       UPDATE $table WITH (ROWLOCK)
       SET WorkingReportId = WorkingReportId - $increment 
       WHERE WorkingReportId IS NOT NULL AND WorkingReportId <= $increment
"@

        try {
            Execute-SqlQuery -server $sqlServer -database "master" -query $updateQuery -username $username -password $password
            Write-Host "Successfully updated table $table in $database" -ForegroundColor Green
        }
        catch {
            Write-Host "Error updating table $table in $database : $_" -ForegroundColor Red
            break
        }
        Start-Sleep -Seconds 1
    }
}

# Main execution
Write-Host "Starting database updates..."
[System.Data.SqlClient.SqlConnection]::ClearAllPools()
foreach ($dbConfig in $databaseConfigs.GetEnumerator()) {
    Update-SaleOrdId -database $dbConfig.Key -increment $dbConfig.Value
}
Write-Host "All database updates completed."