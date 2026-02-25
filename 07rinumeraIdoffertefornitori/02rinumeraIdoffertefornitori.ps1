# Script per incrementare SuppQuotaId in diversi database
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle da aggiornare
$tables = @(
    "MA_PurchaseOrdDetails",
    "MA_SuppQuotasDetail",
    "MA_PurchaseDocDetail",
    "MA_SuppQuotasReference",
    "MA_SuppQuotasTaxSummary",
    "MA_SuppQuotas",
    "MA_SuppQuotasSummary",
    "MA_SuppQuotasShipping",
    "MA_SuppQuotasNote",
    "IM_PurchReqDetails"
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
function Update-SuppQuotaId {
    param (
        $database,
        $increment
    )
    Write-Host "Processing database: $database with increment: $increment"
    
    foreach ($table in $tables) {
        $updateQuery = @"
        USE [$database]
        UPDATE $table WITH (ROWLOCK)
        SET SuppQuotaId = SuppQuotaId + $increment 
        WHERE SuppQuotaId IS NOT NULL
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
    Update-SuppQuotaId -database $dbConfig.Key -increment $dbConfig.Value
}
Write-Host "All database updates completed."