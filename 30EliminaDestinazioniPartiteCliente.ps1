# ============================================
# SCRIPT: Elimina riferimenti destinazione a Partite Cliente
# ============================================
# Versione: 1.0
# Data: 2026-02-25
#
# PROBLEMA:
#   Su VEDMaster, MA_CrossReferences contiene record con:
#   - OriginDocType  = 27066387 (Fattura Immediata)
#   - DerivedDocType = 27066423 (Partita Cliente)
#   Questi record sono errati perche' sono i documenti contabili
#   a generare le partite, non le fatture direttamente.
#
# SOLUZIONE:
#   Eliminare tutti i record da MA_CrossReferences con quella
#   combinazione di OriginDocType/DerivedDocType.
# ============================================

$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"
$destinationDB = "VEDMaster"

$originDocType = 27066387   # Fattura Immediata
$derivedDocType = 27066423  # Partita Cliente

$connString = "Server=$serverName;Database=$destinationDB;User ID=$userName;Password=$password;"

# ============================================
# FUNZIONI HELPER
# ============================================

function Execute-SqlNonQuery {
    param (
        [string]$query,
        [string]$connString,
        [int]$timeout = 600
    )
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = $timeout
        $rows = $cmd.ExecuteNonQuery()
        $conn.Close()
        return $rows
    }
    catch {
        Write-Host "  ERRORE: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return -1
    }
}

function Execute-SqlScalar {
    param ([string]$query, [string]$connString, [int]$timeout = 600)
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = $timeout
        $result = $cmd.ExecuteScalar()
        $conn.Close()
        return $result
    }
    catch {
        Write-Host "  ERRORE: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return $null
    }
}

# ============================================
# INIZIO OPERAZIONE
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ELIMINA DESTINAZIONI PARTITE CLIENTE" -ForegroundColor Cyan
Write-Host "  OriginDocType  = $originDocType (Fattura Immediata)" -ForegroundColor Cyan
Write-Host "  DerivedDocType = $derivedDocType (Partita Cliente)" -ForegroundColor Cyan
Write-Host "  Database: $destinationDB" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# ============================================
# FASE 1: Conteggio record da eliminare
# ============================================
Write-Host "--- FASE 1: Conteggio record da eliminare ---" -ForegroundColor Cyan
Write-Host ""

$countToDelete = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences
WHERE OriginDocType = $originDocType
  AND DerivedDocType = $derivedDocType
"@ -connString $connString

Write-Host "  Record trovati con Fattura Immediata -> Partita Cliente: $countToDelete" -ForegroundColor Yellow

if ($countToDelete -eq 0) {
    Write-Host ""
    Write-Host "  Nessun record da eliminare. Uscita." -ForegroundColor Green
    exit
}

# Mostra un campione
Write-Host ""
Write-Host "  Campione dei primi 5 record:" -ForegroundColor Gray

$sampleConn = New-Object System.Data.SqlClient.SqlConnection($connString)
$sampleConn.Open()
$sampleCmd = New-Object System.Data.SqlClient.SqlCommand(@"
SELECT TOP 5 cr.OriginDocID, cr.DerivedDocID, cr.OriginDocSubID, cr.DerivedDocSubID
FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
ORDER BY cr.OriginDocID
"@, $sampleConn)
$sampleCmd.CommandTimeout = 300
$reader = $sampleCmd.ExecuteReader()
while ($reader.Read()) {
    Write-Host "    OriginDocID=$($reader['OriginDocID']), DerivedDocID=$($reader['DerivedDocID']), OriginSubID=$($reader['OriginDocSubID']), DerivedSubID=$($reader['DerivedDocSubID'])" -ForegroundColor Gray
}
$reader.Close()
$sampleConn.Close()

# ============================================
# FASE 2: Conferma utente
# ============================================
Write-Host ""
Write-Host "--- FASE 2: Conferma ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Verranno ELIMINATI $countToDelete record da MA_CrossReferences" -ForegroundColor Red
Write-Host "  con OriginDocType=$originDocType (Fattura Immediata)" -ForegroundColor Red
Write-Host "  e DerivedDocType=$derivedDocType (Partita Cliente)" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "  Procedere? (S/N)"
if ($confirm -ne 'S' -and $confirm -ne 's') {
    Write-Host "  Operazione annullata." -ForegroundColor Yellow
    exit
}

# ============================================
# FASE 3: Eliminazione
# ============================================
Write-Host ""
Write-Host "--- FASE 3: Eliminazione ---" -ForegroundColor Cyan
Write-Host ""

$deleted = Execute-SqlNonQuery -query @"
DELETE FROM $destinationDB.dbo.MA_CrossReferences
WHERE OriginDocType = $originDocType
  AND DerivedDocType = $derivedDocType
"@ -connString $connString -timeout 1200

if ($deleted -ge 0) {
    Write-Host "  Record eliminati: $deleted" -ForegroundColor Green
} else {
    Write-Host "  Eliminazione fallita!" -ForegroundColor Red
    exit
}

# ============================================
# FASE 4: Verifica finale
# ============================================
Write-Host ""
Write-Host "--- FASE 4: Verifica finale ---" -ForegroundColor Cyan
Write-Host ""

$remaining = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences
WHERE OriginDocType = $originDocType
  AND DerivedDocType = $derivedDocType
"@ -connString $connString

Write-Host "  Record residui Fattura Immediata -> Partita Cliente: $remaining" -ForegroundColor $(if ($remaining -eq 0) { "Green" } else { "Red" })

# ============================================
# RIEPILOGO
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RIEPILOGO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "  Durata: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host "  Record trovati:    $countToDelete" -ForegroundColor White
Write-Host "  Record eliminati:  $deleted" -ForegroundColor Green
Write-Host "  Record residui:    $remaining" -ForegroundColor $(if ($remaining -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Operazione completata!" -ForegroundColor Green
