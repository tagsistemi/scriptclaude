# Script diagnostico per identificare i problemi di mapping colonne
param(
    [string]$TabellaProblema = "MA_PurchaseDocSummary",
    [string]$DatabaseSorgente = "gpxnetclone"
)

$serverInstance = "192.168.0.3\SQL2008"
$username = "sa"
$password = "stream"

function Get-ColumnMapping {
    param($sourceDb, $targetDb, $tableName)
    
    # Colonne sorgente
    $sourceQuery = @"
SELECT COLUMN_NAME, DATA_TYPE, ORDINAL_POSITION 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = '$tableName' 
ORDER BY ORDINAL_POSITION
"@
    
    $sourceColumns = @()
    $targetColumns = @()
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = "Server=$serverInstance;Database=$sourceDb;User Id=$username;Password=$password;TrustServerCertificate=True"
        $connection.Open()
        
        $command = New-Object System.Data.SqlClient.SqlCommand($sourceQuery, $connection)
        $reader = $command.ExecuteReader()
        
        while ($reader.Read()) {
            $sourceColumns += @{
                Name = $reader["COLUMN_NAME"].ToString()
                Type = $reader["DATA_TYPE"].ToString()
                Position = $reader["ORDINAL_POSITION"]
            }
        }
        $reader.Close()
        $connection.Close()
        
        # Colonne destinazione
        $connection.ConnectionString = "Server=$serverInstance;Database=$targetDb;User Id=$username;Password=$password;TrustServerCertificate=True"
        $connection.Open()
        
        $command = New-Object System.Data.SqlClient.SqlCommand($sourceQuery, $connection)
        $reader = $command.ExecuteReader()
        
        while ($reader.Read()) {
            $targetColumns += @{
                Name = $reader["COLUMN_NAME"].ToString()
                Type = $reader["DATA_TYPE"].ToString()
                Position = $reader["ORDINAL_POSITION"]
            }
        }
        $reader.Close()
        $connection.Close()
        
        Write-Host "=== MAPPING COLONNE: $tableName ===" -ForegroundColor Cyan
        Write-Host "Sorgente: $sourceDb -> Destinazione: $targetDb" -ForegroundColor Gray
        Write-Host ""
        
        for ($i = 0; $i -lt [Math]::Min($sourceColumns.Count, $targetColumns.Count); $i++) {
            $src = $sourceColumns[$i]
            $tgt = $targetColumns[$i]
            
            $status = if ($src.Type -eq $tgt.Type) { "✅" } else { "❌" }
            $color = if ($src.Type -eq $tgt.Type) { "Green" } else { "Red" }
            
            Write-Host "$($src.Position): $($src.Name) ($($src.Type)) -> $($tgt.Name) ($($tgt.Type)) $status" -ForegroundColor $color
        }
        
        if ($sourceColumns.Count -ne $targetColumns.Count) {
            Write-Host "⚠️  ATTENZIONE: Numero colonne diverso! Sorgente: $($sourceColumns.Count), Destinazione: $($targetColumns.Count)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "❌ Errore: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test della query di migrazione problematica
function Test-ProblematicQuery {
    param($sourceDb, $tableName)
    
    Write-Host "`n=== TEST QUERY PROBLEMATICA ===" -ForegroundColor Cyan
    
    # Costruisci query come nello script
    $sourceQuery = "SELECT * FROM $tableName"
    $targetColumns = @()
    
    try {
        # Ottieni struttura destinazione
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = "Server=$serverInstance;Database=VEDMaster;User Id=$username;Password=$password;TrustServerCertificate=True"
        $connection.Open()
        
        $structQuery = @"
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = '$tableName' 
ORDER BY ORDINAL_POSITION
"@
        
        $command = New-Object System.Data.SqlClient.SqlCommand($structQuery, $connection)
        $reader = $command.ExecuteReader()
        
        while ($reader.Read()) {
            $targetColumns += $reader["COLUMN_NAME"].ToString()
        }
        $reader.Close()
        $connection.Close()
        
        # Costruisci INSERT query
        $columnList = $targetColumns -join ", "
        $valuesList = ($targetColumns | ForEach-Object { "?" }) -join ", "
        
        $insertQuery = "INSERT INTO $tableName ($columnList) SELECT $columnList FROM [$sourceDb].dbo.$tableName"
        
        Write-Host "Query INSERT generata:" -ForegroundColor Gray
        Write-Host $insertQuery -ForegroundColor White
        
        # Test con pochi record
        $testQuery = "INSERT INTO $tableName ($columnList) SELECT TOP 1 $columnList FROM [$sourceDb].dbo.$tableName"
        
        Write-Host "`nTest con 1 record..." -ForegroundColor Yellow
        
        $connection.ConnectionString = "Server=$serverInstance;Database=VEDMaster;User Id=$username;Password=$password;TrustServerCertificate=True"
        $connection.Open()
        
        $command = New-Object System.Data.SqlClient.SqlCommand($testQuery, $connection)
        $result = $command.ExecuteNonQuery()
        
        Write-Host "✅ Test riuscito! Record inserito: $result" -ForegroundColor Green
        $connection.Close()
        
    } catch {
        Write-Host "❌ Errore nel test: $($_.Exception.Message)" -ForegroundColor Red
        if ($connection.State -eq 'Open') { $connection.Close() }
    }
}

# Esegui diagnostica
Write-Host "🔍 DIAGNOSTICA PROBLEMI MIGRAZIONE" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta

Get-ColumnMapping -sourceDb $DatabaseSorgente -targetDb "VEDMaster" -tableName $TabellaProblema
Test-ProblematicQuery -sourceDb $DatabaseSorgente -tableName $TabellaProblema
