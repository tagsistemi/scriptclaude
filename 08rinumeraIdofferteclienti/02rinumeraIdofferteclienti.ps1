# Script per incrementare CustQuotaId in diversi database
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle da aggiornare
$tables = @(
    "MA_CustQuotasDetail",
    "MA_CustQuotasSummary",
    "MA_CustQuotas",
    "MA_CustQuotasShipping",
    "MA_CustQuotasTaxSummary",
    "MA_CustQuotasReference",
    "MA_CustQuotasNote"
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
function Update-CustQuotaId {
    param (
        $database,
        $increment
    )
    Write-Host "Processing database: $database with increment: $increment"
    
    foreach ($table in $tables) {
        $updateQuery = @"
        USE [$database]
        UPDATE $table WITH (ROWLOCK)
        SET CustQuotaId = CustQuotaId + $increment 
        WHERE CustQuotaId IS NOT NULL
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
    Update-CustQuotaId -database $dbConfig.Key -increment $dbConfig.Value
}
Write-Host "All database updates completed."