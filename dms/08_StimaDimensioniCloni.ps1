# =============================================================================
# 08_StimaDimensioniCloni.ps1
# Mostra le dimensioni dei 4 DB DMS sorgente per stimare lo spazio
# necessario alla clonazione + vedDMS
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

$Databases = @(
    "vedcontabdms",
    "gpxnetdms",
    "furmanetdms",
    "vedbondifedms",
    "VedMasterDMS"
)

Add-Type -AssemblyName System.Data

function Invoke-SqlQuery {
    param([string]$Database, [string]$Query)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    $results = @()
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 300
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $obj = @{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) { $obj[$reader.GetName($i)] = $reader.GetValue($i) }
            $results += [PSCustomObject]$obj
        }
        $reader.Close()
    }
    catch { Write-Host "  ERRORE: $_" -ForegroundColor Red }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
    return $results
}

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "STIMA SPAZIO DISCO PER CLONAZIONE DATABASE DMS" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$totalDataMB = 0
$totalLogMB = 0
$totalBackupMB = 0

Write-Host ""
Write-Host ("{0,-20} {1,12} {2,12} {3,12} {4,15}" -f "Database", "Dati (MB)", "Log (MB)", "Totale (MB)", "Clone stimato") -ForegroundColor White
Write-Host ("-" * 75) -ForegroundColor DarkGray

foreach ($db in $Databases) {
    $sizeQuery = @"
SELECT
    SUM(CASE WHEN type_desc = 'ROWS' THEN CAST(size AS BIGINT) * 8 / 1024 ELSE 0 END) AS DataMB,
    SUM(CASE WHEN type_desc = 'LOG' THEN CAST(size AS BIGINT) * 8 / 1024 ELSE 0 END) AS LogMB,
    SUM(CAST(size AS BIGINT)) * 8 / 1024 AS TotalMB
FROM sys.master_files
WHERE database_id = DB_ID('$db')
"@

    $row = Invoke-SqlQuery -Database "master" -Query $sizeQuery
    if ($row) {
        $dataMB = [int64]$row[0].DataMB
        $logMB = [int64]$row[0].LogMB
        $totalMB = [int64]$row[0].TotalMB
        $cloneGB = [math]::Round($totalMB / 1024, 1)

        Write-Host ("{0,-20} {1,12:N0} {2,12:N0} {3,12:N0} {4,12:N1} GB" -f $db, $dataMB, $logMB, $totalMB, $cloneGB) -ForegroundColor Green

        $totalDataMB += $dataMB
        $totalLogMB += $logMB
        $totalBackupMB += $totalMB
    }
    else {
        Write-Host ("{0,-20} NON TROVATO" -f $db) -ForegroundColor Red
    }
}

Write-Host ("-" * 75) -ForegroundColor DarkGray

$totalGB = [math]::Round($totalBackupMB / 1024, 1)
Write-Host ("{0,-20} {1,12:N0} {2,12:N0} {3,12:N0} {4,12:N1} GB" -f "TOTALE SORGENTI", $totalDataMB, $totalLogMB, $totalBackupMB, $totalGB) -ForegroundColor Yellow

Write-Host ""
Write-Host "--- SPAZIO NECESSARIO ---" -ForegroundColor Yellow

# I cloni occupano circa lo stesso spazio dei sorgenti
# Il backup temporaneo occupa spazio aggiuntivo durante il processo
$cloniGB = $totalGB
$backupTempGB = [math]::Round(($totalBackupMB / 1024) * 0.7, 1)  # backup compresso circa 70%

Write-Host ""
Write-Host "  4 cloni DMS + vedDMS:           ~$cloniGB GB (stessa dimensione sorgenti)" -ForegroundColor White
Write-Host "  Backup temporanei (durante):    ~$backupTempGB GB (compressi, eliminabili dopo)" -ForegroundColor White
Write-Host "  ------------------------------------------------" -ForegroundColor DarkGray
$piccoGB = [math]::Round($cloniGB + $backupTempGB, 1)
Write-Host "  Spazio PICCO durante clonazione: ~$piccoGB GB" -ForegroundColor Cyan
Write-Host "  Spazio FINALE (solo cloni):      ~$cloniGB GB" -ForegroundColor Cyan

# Verifica spazio libero sul disco del server
Write-Host ""
Write-Host "--- SPAZIO LIBERO SUL SERVER ---" -ForegroundColor Yellow

$diskQuery = @"
EXEC master.dbo.xp_fixeddrives
"@

$drives = Invoke-SqlQuery -Database "master" -Query $diskQuery
foreach ($d in $drives) {
    $driveLetter = $d.drive
    $freeMB = [int64]$d."MB free"
    $freeGB = [math]::Round($freeMB / 1024, 1)
    $color = if ($freeGB -gt $piccoGB) { "Green" } else { "Red" }
    $status = if ($freeGB -gt $piccoGB) { "OK" } else { "INSUFFICIENTE" }
    Write-Host "  Drive ${driveLetter}: $freeGB GB liberi  [$status]" -ForegroundColor $color
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "STIMA COMPLETATA" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
