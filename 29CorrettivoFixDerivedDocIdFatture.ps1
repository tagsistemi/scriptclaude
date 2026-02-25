# ============================================
# SCRIPT CORRETTIVO: Fix DerivedDocID Fattura→Doc Contabile su VEDMaster
# ============================================
# Versione: 5.0
#
# PROBLEMA:
#   I cross-references su VEDMaster con:
#   - OriginDocType  = 27066387 (Fattura Immediata)
#   - DerivedDocType = 27066419 (Documento Contabile Emesso)
#   hanno DerivedDocID errato. I movimenti contabili su VEDMaster NON sono stati
#   rinumerati (mantengono gli ID originali di vedcontab), ma i cross-references
#   puntano a ID sbagliati (probabilmente dai cloni).
#
# SOLUZIONE:
#   1. Mappa VEDMaster Fattura → vedcontab Fattura via business key su MA_SaleDoc
#   2. Legge i cross-ref originali da vedcontab.dbo.MA_CrossReferences (SOLA LETTURA!)
#   3. Aggiorna DerivedDocID su VEDMaster con il valore di vedcontab (quello corretto)
#
# IMPORTANTE: NESSUNA MODIFICA su vedcontab! Solo SELECT.
# ============================================

$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"
$destinationDB = "VEDMaster"

$originDocType = 27066387   # Fattura Immediata
$derivedDocType = 27066419  # Documento Contabile Emesso

# ============================================
# FUNZIONI HELPER
# ============================================

function Execute-SqlNonQuery {
    param (
        [string]$query,
        [string]$connString,
        [string]$msgOk,
        [string]$msgErr,
        [int]$timeout = 600
    )
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = $timeout
        $rows = $cmd.ExecuteNonQuery()
        $conn.Close()
        if ($msgOk) { Write-Host "$msgOk (righe: $rows)" -ForegroundColor Green }
        return $rows
    }
    catch {
        if ($msgErr) { Write-Host "$msgErr`: $_" -ForegroundColor Red }
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
        Write-Host "Errore: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return $null
    }
}

function Execute-SqlReader {
    param ([string]$query, [string]$connString, [int]$timeout = 600)
    $results = @()
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = $timeout
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $row = @{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $row[$reader.GetName($i)] = $reader.GetValue($i)
            }
            $results += [PSCustomObject]$row
        }
        $reader.Close()
        $conn.Close()
    }
    catch {
        Write-Host "Errore reader: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
    }
    return $results
}

$connString = "Server=$serverName;Database=$destinationDB;User ID=$userName;Password=$password;"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CORRETTIVO v5: Fix DerivedDocID" -ForegroundColor Cyan
Write-Host "  Fattura($originDocType) -> DocContabile($derivedDocType)" -ForegroundColor Cyan
Write-Host "  DerivedDocID da vedcontab (non rinumerati)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# ============================================
# FASE 0: Verifica prerequisiti
# ============================================
Write-Host "--- FASE 0: Verifica prerequisiti ---" -ForegroundColor Cyan
Write-Host ""

$vcTest = Execute-SqlScalar -query "SELECT COUNT(*) FROM vedcontab.dbo.MA_SaleDoc WHERE SaleDocId = 1 OR 1=0" -connString $connString
if ($null -eq $vcTest) {
    Write-Host "  ERRORE: impossibile leggere vedcontab.dbo.MA_SaleDoc" -ForegroundColor Red
    exit
}
Write-Host "  vedcontab.dbo.MA_SaleDoc: accessibile (sola lettura)" -ForegroundColor Green

$vcCrTest = Execute-SqlScalar -query "SELECT COUNT(*) FROM vedcontab.dbo.MA_CrossReferences WHERE OriginDocType = $originDocType AND DerivedDocType = $derivedDocType" -connString $connString
Write-Host "  vedcontab cross-ref Fattura->DocContabile: $vcCrTest record" -ForegroundColor Green

$backupExists = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.sys.objects WHERE object_id = OBJECT_ID(N'$destinationDB.dbo.MA_CrossReferencesBackup') AND type = 'U'" -connString $connString
Write-Host "  MA_CrossReferencesBackup: $(if ($backupExists -gt 0) { 'PRESENTE' } else { 'NON PRESENTE - ATTENZIONE!' })" -ForegroundColor $(if ($backupExists -gt 0) { "Green" } else { "Red" })
Write-Host ""

# ============================================
# FASE 1: Diagnostica stato attuale
# ============================================
Write-Host "--- FASE 1: Diagnostica stato attuale ---" -ForegroundColor Cyan
Write-Host ""

$totalCR = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences
WHERE OriginDocType = $originDocType AND DerivedDocType = $derivedDocType
"@ -connString $connString
Write-Host "  Cross-ref Fattura->DocContabile su VEDMaster: $totalCR" -ForegroundColor White

# Esempio 071SON
Write-Host ""
Write-Host "  Esempio DocNo '071SON' - stato attuale:" -ForegroundColor Gray
$exVm = Execute-SqlReader -query @"
SELECT cr.OriginDocID, cr.DerivedDocID, sd.DocNo, sd.DocumentDate
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.OriginDocID
WHERE cr.OriginDocType = $originDocType AND cr.DerivedDocType = $derivedDocType
  AND sd.DocNo = '071SON'
ORDER BY sd.DocumentDate
"@ -connString $connString
if ($exVm) {
    foreach ($r in $exVm) {
        Write-Host "    VEDMaster: Fattura $($r.OriginDocID) -> DocContabile $($r.DerivedDocID) (ATTUALE)" -ForegroundColor Yellow
    }
}

$exVc = Execute-SqlReader -query @"
SELECT cr.OriginDocID, cr.DerivedDocID, sd.DocNo, sd.DocumentDate
FROM vedcontab.dbo.MA_CrossReferences cr
INNER JOIN vedcontab.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.OriginDocID
WHERE cr.OriginDocType = $originDocType AND cr.DerivedDocType = $derivedDocType
  AND sd.DocNo = '071SON'
ORDER BY sd.DocumentDate
"@ -connString $connString
if ($exVc) {
    foreach ($r in $exVc) {
        Write-Host "    vedcontab: Fattura $($r.OriginDocID) -> DocContabile $($r.DerivedDocID) (CORRETTO)" -ForegroundColor Green
    }
}
Write-Host ""

# ============================================
# FASE 2: UPDATE DerivedDocID da vedcontab
# ============================================
# Per ogni cross-ref su VEDMaster (Fattura->DocContabile):
#   1. Da OriginDocID (Fattura VEDMaster) risalgo alla business key via MA_SaleDoc
#   2. Trovo la Fattura corrispondente su vedcontab via business key
#   3. Leggo il DerivedDocID corretto dal cross-ref di vedcontab
#   4. Aggiorno il DerivedDocID su VEDMaster
# ============================================
Write-Host "--- FASE 2: UPDATE DerivedDocID da vedcontab ---" -ForegroundColor Cyan
Write-Host ""

# UPDATE diretto (timeout 1200s = 20 min per JOIN cross-database)
Write-Host "  Esecuzione UPDATE (match preciso con SubID/Line)..." -ForegroundColor Yellow
$updated = Execute-SqlNonQuery -query @"
UPDATE cr
SET cr.DerivedDocID = vc_cr.DerivedDocID
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.MA_SaleDoc vm
    ON vm.SaleDocId = cr.OriginDocID
INNER JOIN vedcontab.dbo.MA_SaleDoc vc
    ON vc.DocNo = vm.DocNo
    AND vc.DocumentDate = vm.DocumentDate
    AND vc.CustSupp = vm.CustSupp
    AND vc.DocumentType = vm.DocumentType
INNER JOIN vedcontab.dbo.MA_CrossReferences vc_cr
    ON vc_cr.OriginDocType = $originDocType
    AND vc_cr.OriginDocID = vc.SaleDocId
    AND vc_cr.DerivedDocType = $derivedDocType
    AND vc_cr.OriginDocSubID = cr.OriginDocSubID
    AND vc_cr.DerivedDocSubID = cr.DerivedDocSubID
    AND vc_cr.OriginDocLine = cr.OriginDocLine
    AND vc_cr.DerivedDocLine = cr.DerivedDocLine
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND cr.DerivedDocID <> vc_cr.DerivedDocID
"@ -connString $connString `
    -msgOk "  UPDATE completato" `
    -msgErr "  ERRORE UPDATE" `
    -timeout 1200

# Se il match preciso non ha aggiornato nulla, prova senza SubID/Line
if ($updated -le 0) {
    Write-Host ""
    Write-Host "  Match preciso: $updated righe. Tentativo fallback senza SubID/Line..." -ForegroundColor Yellow
    $updated = Execute-SqlNonQuery -query @"
    UPDATE cr
    SET cr.DerivedDocID = vc_cr.DerivedDocID
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.MA_SaleDoc vm ON vm.SaleDocId = cr.OriginDocID
    INNER JOIN vedcontab.dbo.MA_SaleDoc vc
        ON vc.DocNo = vm.DocNo AND vc.DocumentDate = vm.DocumentDate
        AND vc.CustSupp = vm.CustSupp AND vc.DocumentType = vm.DocumentType
    INNER JOIN vedcontab.dbo.MA_CrossReferences vc_cr
        ON vc_cr.OriginDocType = $originDocType
        AND vc_cr.OriginDocID = vc.SaleDocId
        AND vc_cr.DerivedDocType = $derivedDocType
    WHERE cr.OriginDocType = $originDocType AND cr.DerivedDocType = $derivedDocType
      AND cr.DerivedDocID <> vc_cr.DerivedDocID
"@ -connString $connString `
        -msgOk "  UPDATE fallback completato" `
        -msgErr "  ERRORE UPDATE fallback" `
        -timeout 1200
}

Write-Host ""

# ============================================
# FASE 3: Verifica finale
# ============================================
Write-Host "--- FASE 3: Verifica finale ---" -ForegroundColor Cyan
Write-Host ""

# Quanti ancora diversi da vedcontab?
$stillWrong = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.MA_SaleDoc vm ON vm.SaleDocId = cr.OriginDocID
INNER JOIN vedcontab.dbo.MA_SaleDoc vc
    ON vc.DocNo = vm.DocNo AND vc.DocumentDate = vm.DocumentDate
    AND vc.CustSupp = vm.CustSupp AND vc.DocumentType = vm.DocumentType
INNER JOIN vedcontab.dbo.MA_CrossReferences vc_cr
    ON vc_cr.OriginDocType = $originDocType
    AND vc_cr.OriginDocID = vc.SaleDocId
    AND vc_cr.DerivedDocType = $derivedDocType
WHERE cr.OriginDocType = $originDocType AND cr.DerivedDocType = $derivedDocType
  AND cr.DerivedDocID <> vc_cr.DerivedDocID
"@ -connString $connString -timeout 1200

Write-Host "  Cross-ref aggiornati:           $updated" -ForegroundColor Green
Write-Host "  Ancora diversi da vedcontab:    $stillWrong" -ForegroundColor $(if ($stillWrong -eq 0) { "Green" } else { "Red" })

# Verifica 071SON
Write-Host ""
Write-Host "  Verifica '071SON' dopo fix:" -ForegroundColor Yellow
$checkCR = Execute-SqlReader -query @"
SELECT cr.OriginDocID, cr.DerivedDocID, sd.DocNo, sd.DocumentDate
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.OriginDocID
WHERE cr.OriginDocType = $originDocType AND cr.DerivedDocType = $derivedDocType
  AND sd.DocNo = '071SON'
ORDER BY sd.DocumentDate
"@ -connString $connString
if ($checkCR) {
    foreach ($row in $checkCR) {
        Write-Host "    Fattura $($row.OriginDocID) -> DocContabile $($row.DerivedDocID)" -ForegroundColor Green
    }
}

# Confronto con vedcontab
Write-Host ""
Write-Host "  Confronto con vedcontab (attesi):" -ForegroundColor Yellow
if ($exVc) {
    foreach ($r in $exVc) {
        Write-Host "    vedcontab: Fattura $($r.OriginDocID) -> DocContabile $($r.DerivedDocID)" -ForegroundColor Cyan
    }
}

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
Write-Host "  Cross-ref totali (Fattura->DocContabile): $totalCR" -ForegroundColor White
Write-Host "  Aggiornati:   $updated" -ForegroundColor Green
Write-Host "  Residui:      $stillWrong" -ForegroundColor $(if ($stillWrong -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "  Per rollback: esegui 29b_RipristinaMA_CrossReferencesBackup.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Operazione completata!" -ForegroundColor Green
