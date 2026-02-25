$server = "192.168.0.3\SQL2008"
$databases = @("furmanetclone", "vedbondifeclone")
$username = "sa"
$password = "stream"

$tables = @(
    "MA_PurchaseOrd",
    "MA_PurchaseOrdDetails",
    "MA_SuppQuotas",
    "MA_SuppQuotasdetail",
    "MA_PurchaseDoc",
    "MA_PurchaseDocDetail",
    "MA_CustQuotas",
    "MA_CustQuotasDetail",
    "MA_SaleOrd",
    "MA_SaleOrdDetails",
    "MA_SaleDoc",
    "MA_SaleDocDetail",
    "MA_InventoryEntriesDetail",
    "IM_DeliveryRequest",
    "IM_DeliveryReqDetails",
    "IM_WorkingReports",
    "IM_WorkingReportsDetails",
    "IM_WorksProgressReport",
    "IM_WPRDetails",
    "IM_SubcontractQuotasDetails",
    "IM_SubcontractOrd",
    "IM_SubcontractOrdDetails",
    "IM_SubcontractWorksProgressReport",
    "IM_SubcontractWPRDetails",
    "IM_MeasuresBooks",
    "IM_MeasuresBooksDetails"
)

foreach ($database in $databases) {
    Write-Host "Processing database: $database" -ForegroundColor Cyan
    
    $connectionString = "Server=$server;Database=$database;User Id=$username;Password=$password;"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString

    try {
        $connection.Open()
        
        foreach ($table in $tables) {
            try {
                $updateQuery = @"
                UPDATE dbo.$table
                SET Job = m.NuovoCodice
                FROM dbo.$table t
                INNER JOIN dbo.MM4_MappaJobsCodes m ON t.Job = m.VecchioCodice
                WHERE m.VecchioCodice IS NOT NULL AND m.NuovoCodice IS NOT NULL;
                SELECT @@ROWCOUNT as RowsAffected;
"@
                $command = New-Object System.Data.SqlClient.SqlCommand
                $command.CommandText = $updateQuery
                $command.Connection = $connection
                
                $reader = $command.ExecuteReader()
                
                if ($reader.Read()) {
                    $rowsAffected = $reader["RowsAffected"]
                    Write-Host "  - Table $table : Updated $rowsAffected rows" -ForegroundColor Green
                }
                
                $reader.Close()
            }
            catch {
                Write-Host "  - Error updating table $table" -ForegroundColor Red
                Write-Host "    " $_.Exception.Message -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error connecting to database $database" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

Write-Host "Script completed" -ForegroundColor Green