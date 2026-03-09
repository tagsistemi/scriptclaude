# =============================================================================
# 03_ClonaDatabaseDMS.ps1 - FASE 0
# Clona i 4 database DMS per lavorare in sicurezza
# Usa RESTORE FILELISTONLY per gestire tutti i file (inclusi Full-Text)
# Backup su O:\BackupDMS con sovrascrittura singolo file per risparmiare spazio
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

$BackupDir = "O:\BackupDMS"
# Singolo file .bak riutilizzato per tutti i clone (WITH INIT sovrascrive)
$BackupFile = "$BackupDir\dms_clone_temp.bak"

$DmsClones = @(
    @{ Source = "vedcontabdms";  Target = "vedcontabdmsclone" }
    @{ Source = "gpxnetdms";     Target = "gpxnetdmsclone" }
    @{ Source = "furmanetdms";   Target = "furmanetdmsclone" }
    @{ Source = "vedbondifedms"; Target = "vedbondifedmsclone" }
)

Add-Type -AssemblyName System.Data

function Execute-SqlNonQuery {
    param([string]$Query, [string]$Database = "master")
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 0
        $cmd.ExecuteNonQuery() | Out-Null
        return $true
    }
    catch {
        Write-Host "  ERRORE: $_" -ForegroundColor Red
        return $false
    }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

function Get-RestoreFileList {
    param([string]$BackupPath)
    # Usa RESTORE FILELISTONLY per ottenere TUTTI i file nel backup (data, log, fulltext, ecc.)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=master;User Id=$SqlUsername;Password=$SqlPassword;"
    $conn.Open()
    $query = "RESTORE FILELISTONLY FROM DISK = N'$BackupPath'"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
    $cmd.CommandTimeout = 300
    $reader = $cmd.ExecuteReader()
    $files = @()
    while ($reader.Read()) {
        $files += @{
            LogicalName  = $reader["LogicalName"].ToString()
            PhysicalName = $reader["PhysicalName"].ToString()
            Type         = $reader["Type"].ToString()  # D=data, L=log, S=fulltext
        }
    }
    $conn.Close()
    return $files
}

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "FASE 0: CLONAZIONE DATABASE DMS" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# La directory O:\BackupDMS deve esistere sul server SQL
Write-Host "  Directory backup (server-side): $BackupDir" -ForegroundColor DarkGray
Write-Host "  File backup condiviso: $BackupFile (sovrascrittura ad ogni clone)" -ForegroundColor DarkGray

$successCount = 0

foreach ($clone in $DmsClones) {
    Write-Host "`n--- Clonazione $($clone.Source) -> $($clone.Target) ---" -ForegroundColor Yellow

    # Verifica se il target esiste gia
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=master;User Id=$SqlUsername;Password=$SqlPassword;"
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand("SELECT COUNT(*) FROM sys.databases WHERE name = '$($clone.Target)'", $conn)
    $dbExists = [int]$cmd.ExecuteScalar() -gt 0
    $conn.Close()

    if ($dbExists) {
        Write-Host "  Il database $($clone.Target) esiste gia. Eliminazione..." -ForegroundColor Yellow
        Execute-SqlNonQuery -Query "ALTER DATABASE [$($clone.Target)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$($clone.Target)]"
    }

    # Backup su O: (sovrascrive il file precedente con WITH INIT)
    Write-Host "  Backup di $($clone.Source) su $BackupFile..." -ForegroundColor White
    $backupOk = Execute-SqlNonQuery -Query "BACKUP DATABASE [$($clone.Source)] TO DISK = N'$BackupFile' WITH INIT"
    if (-not $backupOk) {
        Write-Host "  FALLITO: impossibile creare backup. Salto questo clone." -ForegroundColor Red
        continue
    }

    # Leggi lista file dal backup (include fulltext, ecc.)
    Write-Host "  Lettura file list dal backup..." -ForegroundColor White
    $fileList = Get-RestoreFileList -BackupPath $BackupFile

    if ($fileList.Count -eq 0) {
        Write-Host "  FALLITO: nessun file trovato nel backup." -ForegroundColor Red
        continue
    }

    Write-Host "  File trovati nel backup: $($fileList.Count)" -ForegroundColor DarkGray
    foreach ($f in $fileList) {
        Write-Host "    [$($f.Type)] $($f.LogicalName) -> $($f.PhysicalName)" -ForegroundColor DarkGray
    }

    # Costruisci i MOVE per ogni file, sostituendo il nome sorgente col target nel path
    $moveClauses = @()
    foreach ($f in $fileList) {
        $targetPath = $f.PhysicalName -replace [regex]::Escape($clone.Source), $clone.Target
        $moveClauses += "    MOVE N'$($f.LogicalName)' TO N'$targetPath'"
    }
    $moveString = $moveClauses -join ",`n"

    # Restore come clone
    Write-Host "  Restore come $($clone.Target)..." -ForegroundColor White
    $restoreQuery = @"
RESTORE DATABASE [$($clone.Target)]
FROM DISK = N'$BackupFile'
WITH
$moveString,
    REPLACE
"@
    $restoreOk = Execute-SqlNonQuery -Query $restoreQuery
    if ($restoreOk) {
        $successCount++
        Write-Host "  OK: $($clone.Source) -> $($clone.Target)" -ForegroundColor Green
    } else {
        Write-Host "  FALLITO: restore non riuscito per $($clone.Target)" -ForegroundColor Red
    }
}

Write-Host "`n"
Write-Host "  NOTA: Il file $BackupFile rimane sul server." -ForegroundColor Yellow
Write-Host "  Eliminarlo manualmente da O:\BackupDMS dopo il completamento." -ForegroundColor Yellow
Write-Host "`n"
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "FASE 0 COMPLETATA - $successCount/$($DmsClones.Count) cloni DMS creati" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
