# =============================================================================
# 29FixMAFixAssetEntries.ps1
# Reinserisce i record di MA_FixAssetEntries e MA_FixAssetEntriesDetail
# da vedcontab in VEDMaster (persi durante Migrate-StockData.ps1)
# vedcontab e' la base (offset 0), EntryId non rinumerato
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$SourceDB = "vedcontab"
$TargetDB = "VEDMaster"

$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;"

Add-Type -AssemblyName System.Data

function Invoke-SqlScalar {
    param([string]$Query, [string]$Database)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 300
        return $cmd.ExecuteScalar()
    }
    catch { Write-Host "  ERRORE: $_" -ForegroundColor Red; return $null }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

function Execute-SqlNonQuery {
    param([string]$Query, [string]$Database = "master")
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 600
        $result = $cmd.ExecuteNonQuery()
        return $result
    }
    catch {
        Write-Host "  ERRORE: $_" -ForegroundColor Red
        return -1
    }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "FIX: Reinserimento MA_FixAssetEntries da vedcontab in VEDMaster" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# --- Verifica stato attuale ---
Write-Host "`n--- Stato attuale ---" -ForegroundColor Yellow

$targetEntries = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.MA_FixAssetEntries" -Database $TargetDB
$targetDetails = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.MA_FixAssetEntriesDetail" -Database $TargetDB
$sourceEntries = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.MA_FixAssetEntries" -Database $SourceDB
$sourceDetails = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.MA_FixAssetEntriesDetail" -Database $SourceDB

Write-Host "  $TargetDB  - MA_FixAssetEntries: $targetEntries | MA_FixAssetEntriesDetail: $targetDetails" -ForegroundColor White
Write-Host "  $SourceDB  - MA_FixAssetEntries: $sourceEntries | MA_FixAssetEntriesDetail: $sourceDetails" -ForegroundColor White

if ($sourceEntries -eq 0) {
    Write-Host "`n  Nessun record da recuperare in vedcontab. Nulla da fare." -ForegroundColor Yellow
    exit
}

# --- Disabilita FK ---
Write-Host "`n--- Disabilitazione FK ---" -ForegroundColor Yellow
Execute-SqlNonQuery -Query "ALTER TABLE [$TargetDB].dbo.MA_FixAssetEntriesDetail NOCHECK CONSTRAINT ALL" | Out-Null
Execute-SqlNonQuery -Query "ALTER TABLE [$TargetDB].dbo.MA_FixAssetEntries NOCHECK CONSTRAINT ALL" | Out-Null
Write-Host "  FK disabilitate" -ForegroundColor Green

# --- Svuota tabelle su VEDMaster (rimuove dati errati dei 3 cloni) ---
Write-Host "`n--- Svuotamento tabelle su $TargetDB ---" -ForegroundColor Yellow

$deleted = Execute-SqlNonQuery -Query "DELETE FROM [$TargetDB].dbo.MA_FixAssetEntriesDetail"
Write-Host "  MA_FixAssetEntriesDetail: $deleted record eliminati" -ForegroundColor White
$deleted = Execute-SqlNonQuery -Query "DELETE FROM [$TargetDB].dbo.MA_FixAssetEntries"
Write-Host "  MA_FixAssetEntries: $deleted record eliminati" -ForegroundColor White

# --- Inserimento solo da vedcontab ---
Write-Host "`n--- Inserimento da $SourceDB (unica sorgente) ---" -ForegroundColor Yellow

$insertEntries = @"
INSERT INTO [$TargetDB].dbo.MA_FixAssetEntries
SELECT * FROM [$SourceDB].dbo.MA_FixAssetEntries
"@

$result = Execute-SqlNonQuery -Query $insertEntries
Write-Host "  MA_FixAssetEntries: $result record inseriti" -ForegroundColor $(if ($result -ge 0) { "Green" } else { "Red" })

$insertDetails = @"
INSERT INTO [$TargetDB].dbo.MA_FixAssetEntriesDetail
SELECT * FROM [$SourceDB].dbo.MA_FixAssetEntriesDetail
"@

$result = Execute-SqlNonQuery -Query $insertDetails
Write-Host "  MA_FixAssetEntriesDetail: $result record inseriti" -ForegroundColor $(if ($result -ge 0) { "Green" } else { "Red" })

# --- Riabilita FK ---
Write-Host "`n--- Riabilitazione FK ---" -ForegroundColor Yellow
Execute-SqlNonQuery -Query "ALTER TABLE [$TargetDB].dbo.MA_FixAssetEntries WITH CHECK CHECK CONSTRAINT ALL" | Out-Null
Execute-SqlNonQuery -Query "ALTER TABLE [$TargetDB].dbo.MA_FixAssetEntriesDetail WITH CHECK CHECK CONSTRAINT ALL" | Out-Null
Write-Host "  FK riabilitate" -ForegroundColor Green

# --- Verifica finale ---
Write-Host "`n--- Verifica finale ---" -ForegroundColor Yellow
$finalEntries = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.MA_FixAssetEntries" -Database $TargetDB
$finalDetails = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.MA_FixAssetEntriesDetail" -Database $TargetDB

$okEntries = [int]$finalEntries -eq [int]$sourceEntries
$okDetails = [int]$finalDetails -eq [int]$sourceDetails

Write-Host "  MA_FixAssetEntries:       $finalEntries record (attesi: $sourceEntries)" -ForegroundColor $(if ($okEntries) { "Green" } else { "Red" })
Write-Host "  MA_FixAssetEntriesDetail: $finalDetails record (attesi: $sourceDetails)" -ForegroundColor $(if ($okDetails) { "Green" } else { "Red" })

Write-Host "`n"
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "FIX COMPLETATO" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
