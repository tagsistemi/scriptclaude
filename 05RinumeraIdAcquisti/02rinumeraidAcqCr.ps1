# Script per incrementare PurchaseDocId in diversi database
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle da aggiornare
$tables = @(
    "MA_PurchaseDoc",
    "MA_PurchaseDocDetail",
    "MA_PurchaseDocReferences", 
    "MA_PurchaseDocTaxSummary",
    "MA_PurchaseDocShipping",
    "MA_PurchaseDocSummary",
    "MA_PurchaseDocPymtSched",
    "MA_PurchaseDocNotes",
    "MA_CostAccEntries",
    "MA_PurchaseDocLinkOrders",
    "MA_BRNotaFiscalForSupplier",
    "MA_BRNotaFiscalForSuppDetail",
    "MA_BRNotaFiscalForSuppSummary",
    "MA_BRNotaFiscalForSuppRef",
    "MA_BRNotaFiscalForSuppShipping"
)

# Definizione dei database e relativi incrementi
$databaseConfigs = @{
    "gpxnetclone"     = 100000
    "furmanetclone"   = 200000
    "vedbondifeclone" = 300000
}

function Execute-SqlQuery {
    param (
        [string]$server,
        [string]$query,
        [string]$username,
        [string]$password
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
        $result = $command.ExecuteNonQuery()
        Write-Host "Query executed. Rows affected: $result"
    }
    catch {
        Write-Host "Error executing query: $_" -ForegroundColor Red
        throw $_
    }
    finally {
        $connection.Close()
    }
}

# Funzione per generare e eseguire lo script SQL
function Update-PurchaseDocId {
    param (
        $database,
        $increment
    )

    Write-Host "Processing database: $database with increment: $increment"

    # Crea la tabella TAG_CrMaps se non esiste
    $createTableScript = @"
USE [$database];
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
        Execute-SqlQuery -server $sqlServer -query $createTableScript -username $username -password $password
    }
    catch {
        Write-Host "Error creating TAG_CrMaps table: $_" -ForegroundColor Red
        return
    }

    # Costruisci lo script SQL con l'inserimento dei mapping
    $sqlScript = @"
USE [$database];
BEGIN TRY
    BEGIN TRANSACTION;

     -- Elimina tutti i record esistenti da TAG_CrMaps
    DELETE FROM TAG_CrMaps;

    -- Inserisci i mapping per MA_PurchaseDoc
    INSERT INTO TAG_CrMaps (OldId, DocumentType, NewDocId)
    SELECT 
        PurchaseDocId as OldId,
        DocumentType,
        PurchaseDocId + $increment as NewDocId
    FROM MA_PurchaseDoc;

"@

    foreach ($table in $tables) {
        $sqlScript += "    UPDATE $table SET PurchaseDocId = PurchaseDocId + $increment;`n"
    }

    $sqlScript += @"
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
        Execute-SqlQuery -server $sqlServer -query $sqlScript -username $username -password $password
        Write-Host "Successfully processed $database" -ForegroundColor Green
    }
    catch {
        Write-Host "Error processing $database : $_" -ForegroundColor Red
    }
}

# Main execution
Write-Host "Starting database updates..."

foreach ($dbConfig in $databaseConfigs.GetEnumerator()) {
    Update-PurchaseDocId -database $dbConfig.Key -increment $dbConfig.Value
}

Write-Host "All database updates completed."