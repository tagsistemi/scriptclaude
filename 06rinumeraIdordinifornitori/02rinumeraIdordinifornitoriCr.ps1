# Script per incrementare PurchaseOrdId in diversi database
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle da aggiornare
$tables = @(
    "MA_PurchaseOrdDetails",
    "MA_PurchaseDocDetail", 
    "MA_PurchaseOrdReferences",
    "MA_PurchaseOrdPymtSched",
    "MA_SuppQuotas",
    "MA_PurchaseOrd",
    "MA_PurchaseOrdSummary",
    "MA_PurchaseOrdShipping", 
    "MA_PurchaseOrdTaxSummay",
    "MA_PurchaseOrdNotes",
    "MA_MOStepsDetailedQty",
    "MA_PurchaseReqDetail",
    "MA_PurchaseReqRequirements",
    "MA_PurchaseDocLinkOrders"
)

# Definizione dei database e relativi incrementi
$databaseConfigs = @{
    "gpxnetclone" = 100000
    "furmanetclone" = 200000
    "vedbondifeclone" = 300000
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
function Update-PurchaseOrdId {
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
    -- Prima elimina i record esistenti per il tipo documento specifico
    DELETE FROM TAG_CrMaps 
    WHERE DocumentType = 3801100;

    INSERT INTO TAG_CrMaps (OldId, DocumentType, NewDocId)
    SELECT 
        PurchaseOrdId as OldId,
        3801100 as DocumentType,
        PurchaseOrdId + $increment as NewDocId
    FROM MA_PurchaseOrd
    WHERE PurchaseOrdId IS NOT NULL
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
        SET PurchaseOrdId = PurchaseOrdId + $increment 
        WHERE PurchaseOrdId IS NOT NULL
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
    Update-PurchaseOrdId -database $dbConfig.Key -increment $dbConfig.Value
}
Write-Host "All database updates completed."