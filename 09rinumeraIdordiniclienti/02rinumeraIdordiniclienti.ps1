# Script per incrementare SaleOrdId in diversi database
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle da aggiornare
$tables = @(
    "MA_SaleDocDetail",
    "MA_SaleOrdDetails",
    "MA_SaleOrdReferences",
    "MA_SaleOrdShipping",
    "MA_SaleOrd",
    "MA_SaleOrdSummary",
    "MA_SaleOrdTaxSummary",
    "MA_PurchaseOrdDetails",
    "MA_CustQuotas",
    "MA_SaleOrdNotes",
    "MA_SaleOrdPymtSched",
    "MA_ProductionPlansDetail",
    "MA_TmpSaleOrdFulfilment",
    "MA_TmpReorderingFromSuppRef",
    "MA_TmpBOMExplosions",
    "MA_MOComponents",
    "MA_SaleOrdComponents",
    "MA_MO",
    "MA_TmpReorderingFromSupp",
    "MA_TmpProdPlanGeneration",
    "MA_TmpProdPlanGenerationRef",
    "MA_CustContractsRef",
    "MA_TmpSaleOrdersAllocation"
)

# Definizione dei database e relativi incrementi
$databaseConfigs = @{
    # "gpxnetclone" = 100000  -- ESCLUSO: gli ordini clienti GPX non devono essere rinumerati (importati da gpxnet originale)
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
function Update-SaleOrdId {
    param (
        $database,
        $increment
    )
    Write-Host "Processing database: $database with increment: $increment"
    
    foreach ($table in $tables) {
        $updateQuery = @"
        USE [$database]
        UPDATE $table WITH (ROWLOCK)
        SET SaleOrdId = SaleOrdId + $increment 
        WHERE SaleOrdId IS NOT NULL
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