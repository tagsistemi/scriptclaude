# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$Database = "Vedmaster"

# Funzione per eseguire una query SQL
function Execute-SqlQuery {
    param (
        [string]$tableName,
        [string]$query
    )
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
        $conn.Open()
        
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 0  # No timeout
        
        $rowsAffected = $cmd.ExecuteNonQuery()
        Write-Host "Tabella $tableName pulita con successo. Righe eliminate: $rowsAffected" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Errore durante la pulizia della tabella $tableName" -ForegroundColor Red
        Write-Error $_.Exception.Message
        return $false
    }
    finally {
        if ($conn -and $conn.State -eq 'Open') {
            $conn.Close()
        }
    }
}

# Array delle tabelle da pulire (ordinate per rispettare le foreign key)
$tables = @(
    "IM_JobsBalance",
    "IM_JobsComponents",
    "IM_JobsCostsRevenuesSummary",
    "IM_JobsDetails",
    "IM_JobsDetailsVCL",
    "IM_JobsDocuments",
    "IM_JobsHistoryStates",
    "IM_JobsItems",
    "IM_JobsNotes",
    "IM_JobsSections",
    "IM_JobsSummary",
    "IM_JobsSummaryByCompType",
    "IM_JobsSummaryByCompTypeByWorkingStep",
    "IM_JobsStatOfAccount",
    "IM_JobsTaxSummary",
    "IM_JobsWithholdingTax",
    "IM_JobsWorkingStep",
    "ma_jobs",
    "IM_WorksProgressReport",
    "IM_WorkingReportsDetails",
    "IM_SubcontractWorksProgressReport",
    "IM_SubcontractOrdDetails",
    "IM_SubcontractQuotasDetails",
    "IM_WorkingReports",
    "IM_SubcontractWPRDetails",
    "IM_WPRDetails",
    "IM_MeasuresBooksDetails",
    "IM_DeliveryReqDetails",
    "IM_SpecificationsItems",
    "IM_Specifications",
    "IM_SubcontractOrd",
    "IM_MeasuresBooks",
    "IM_DeliveryRequest"
)

Write-Host "Inizio operazione di pulizia database $Database" -ForegroundColor Yellow
Write-Host "---------------------------------------------"

$successCount = 0
$failureCount = 0

# Esegui le delete per ogni tabella
foreach ($table in $tables) {
    Write-Host "`nProcessando tabella: $table..."
    $query = "DELETE FROM $table"
    
    if (Execute-SqlQuery -tableName $table -query $query) {
        $successCount++
    }
    else {
        $failureCount++
    }
}

Write-Host "`n---------------------------------------------"
Write-Host "Operazione completata!" -ForegroundColor Yellow
Write-Host "Tabelle processate con successo: $successCount" -ForegroundColor Green
if ($failureCount -gt 0) {
    Write-Host "Tabelle con errori: $failureCount" -ForegroundColor Red
}