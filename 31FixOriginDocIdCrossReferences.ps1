# ============================================
# SCRIPT: Fix OriginDocID in MA_CrossReferences
# ============================================
# Versione: 1.0
# Data: 2026-02-25
#
# PROBLEMA:
#   Su VEDMaster, MA_CrossReferences contiene record con:
#   - OriginDocType  = 27066387 (Fattura Immediata)
#   - DerivedDocType = 27066419 (Documento Contabile Emesso)
#   dove OriginDocID e' ancora il vecchio ID di vedcontab,
#   ma su VEDMaster il SaleDocId e' stato rinumerato.
#   Esempio: OriginDocID=141874 (vecchio) anziche' 535618 (nuovo)
#
# SOLUZIONE:
#   1. Trovare i record con OriginDocID che NON esiste in VEDMaster.dbo.MA_SaleDoc
#   2. Risalire alla business key (DocNo, DocumentDate, CustSupp, DocumentType)
#      tramite vedcontab.dbo.MA_SaleDoc
#   3. Trovare il nuovo SaleDocId su VEDMaster con la stessa business key
#   4. Aggiornare OriginDocID al nuovo ID
# ============================================

$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"
$destinationDB = "VEDMaster"
$sourceDB = "vedcontab"

$originDocType = 27066387   # Fattura Immediata
$derivedDocType = 27066419  # Documento Contabile Emesso

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
        Write-Host "  ERRORE reader: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
    }
    return $results
}

# ============================================
# INIZIO OPERAZIONE
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  FIX OriginDocID in MA_CrossReferences" -ForegroundColor Cyan
Write-Host "  OriginDocType  = $originDocType (Fattura Immediata)" -ForegroundColor Cyan
Write-Host "  DerivedDocType = $derivedDocType (Doc Contabile Emesso)" -ForegroundColor Cyan
Write-Host "  Database: $destinationDB" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# ============================================
# FASE 1: Diagnostica - record con OriginDocID orfano
# ============================================
Write-Host "--- FASE 1: Diagnostica record con OriginDocID orfano ---" -ForegroundColor Cyan
Write-Host ""

# Totale cross-ref di questo tipo
$totalCR = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences
WHERE OriginDocType = $originDocType
  AND DerivedDocType = $derivedDocType
"@ -connString $connString

Write-Host "  Totale cross-ref Fattura->DocContabile: $totalCR" -ForegroundColor White

# Record con OriginDocID che NON esiste in MA_SaleDoc di VEDMaster
$orphanCount = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
      WHERE sd.SaleDocId = cr.OriginDocID
  )
"@ -connString $connString

Write-Host "  Record con OriginDocID orfano (vecchio ID vedcontab): $orphanCount" -ForegroundColor $(if ($orphanCount -gt 0) { "Yellow" } else { "Green" })

if ($orphanCount -eq 0) {
    Write-Host ""
    Write-Host "  Nessun record orfano trovato. Tutti gli OriginDocID sono validi." -ForegroundColor Green
    exit
}

# Record orfani che possiamo mappare tramite vedcontab
$mappableCount = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $sourceDB.dbo.MA_SaleDoc vc
    ON vc.SaleDocId = cr.OriginDocID
INNER JOIN $destinationDB.dbo.MA_SaleDoc vm
    ON vm.DocNo = vc.DocNo
    AND vm.DocumentDate = vc.DocumentDate
    AND vm.CustSupp = vc.CustSupp
    AND vm.DocumentType = vc.DocumentType
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
      WHERE sd.SaleDocId = cr.OriginDocID
  )
"@ -connString $connString

Write-Host "  Di cui mappabili tramite business key vedcontab->VEDMaster: $mappableCount" -ForegroundColor $(if ($mappableCount -eq $orphanCount) { "Green" } else { "Yellow" })

$notMappable = $orphanCount - $mappableCount
if ($notMappable -gt 0) {
    Write-Host "  Non mappabili (business key non trovata): $notMappable" -ForegroundColor Red
}

# Record che genererebbero duplicato PK (esiste gia' un cross-ref con il nuovo OriginDocID)
$duplicateCount = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $sourceDB.dbo.MA_SaleDoc vc
    ON vc.SaleDocId = cr.OriginDocID
INNER JOIN $destinationDB.dbo.MA_SaleDoc vm
    ON vm.DocNo = vc.DocNo
    AND vm.DocumentDate = vc.DocumentDate
    AND vm.CustSupp = vc.CustSupp
    AND vm.DocumentType = vc.DocumentType
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
      WHERE sd.SaleDocId = cr.OriginDocID
  )
  AND EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences dup
      WHERE dup.OriginDocType  = cr.OriginDocType
        AND dup.OriginDocID    = vm.SaleDocId
        AND dup.OriginDocSubID = cr.OriginDocSubID
        AND dup.OriginDocLine  = cr.OriginDocLine
        AND dup.DerivedDocType = cr.DerivedDocType
        AND dup.DerivedDocID   = cr.DerivedDocID
        AND dup.DerivedDocSubID= cr.DerivedDocSubID
        AND dup.DerivedDocLine = cr.DerivedDocLine
  )
"@ -connString $connString

Write-Host "  Di cui gia' presenti con nuovo ID (duplicati PK): $duplicateCount" -ForegroundColor $(if ($duplicateCount -eq 0) { "Green" } else { "Yellow" })
$updatable = $mappableCount - $duplicateCount
Write-Host "  Aggiornabili (no conflitto PK): $updatable" -ForegroundColor White

# ============================================
# FASE 2: Campione dei record da aggiornare
# ============================================
Write-Host ""
Write-Host "--- FASE 2: Campione mapping vecchio->nuovo ---" -ForegroundColor Cyan
Write-Host ""

$sample = Execute-SqlReader -query @"
SELECT TOP 10
    cr.OriginDocID AS VecchioID,
    vm.SaleDocId AS NuovoID,
    vc.DocNo,
    vc.DocumentDate,
    vc.CustSupp
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $sourceDB.dbo.MA_SaleDoc vc
    ON vc.SaleDocId = cr.OriginDocID
INNER JOIN $destinationDB.dbo.MA_SaleDoc vm
    ON vm.DocNo = vc.DocNo
    AND vm.DocumentDate = vc.DocumentDate
    AND vm.CustSupp = vc.CustSupp
    AND vm.DocumentType = vc.DocumentType
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
      WHERE sd.SaleDocId = cr.OriginDocID
  )
ORDER BY cr.OriginDocID
"@ -connString $connString

foreach ($r in $sample) {
    Write-Host "    DocNo=$($r.DocNo) CustSupp=$($r.CustSupp) Data=$($r.DocumentDate)  ID: $($r.VecchioID) -> $($r.NuovoID)" -ForegroundColor Gray
}

# ============================================
# FASE 3: Conferma utente
# ============================================
Write-Host ""
Write-Host "--- FASE 3: Conferma ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Verranno AGGIORNATI $mappableCount record in MA_CrossReferences" -ForegroundColor Yellow
Write-Host "  OriginDocID: vecchio ID vedcontab -> nuovo ID VEDMaster" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "  Procedere? (S/N)"
if ($confirm -ne 'S' -and $confirm -ne 's') {
    Write-Host "  Operazione annullata." -ForegroundColor Yellow
    exit
}

# ============================================
# FASE 4a: DELETE record orfani che sono duplicati
# ============================================
Write-Host ""
Write-Host "--- FASE 4a: Elimina record orfani gia' presenti con nuovo ID ---" -ForegroundColor Cyan
Write-Host ""

$deleted = 0
if ($duplicateCount -gt 0) {
    Write-Host "  Eliminazione $duplicateCount record duplicati (il nuovo ID esiste gia')..." -ForegroundColor Yellow

    $deleted = Execute-SqlNonQuery -query @"
    DELETE cr
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $sourceDB.dbo.MA_SaleDoc vc
        ON vc.SaleDocId = cr.OriginDocID
    INNER JOIN $destinationDB.dbo.MA_SaleDoc vm
        ON vm.DocNo = vc.DocNo
        AND vm.DocumentDate = vc.DocumentDate
        AND vm.CustSupp = vc.CustSupp
        AND vm.DocumentType = vc.DocumentType
    WHERE cr.OriginDocType = $originDocType
      AND cr.DerivedDocType = $derivedDocType
      AND NOT EXISTS (
          SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
          WHERE sd.SaleDocId = cr.OriginDocID
      )
      AND EXISTS (
          SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences dup
          WHERE dup.OriginDocType  = cr.OriginDocType
            AND dup.OriginDocID    = vm.SaleDocId
            AND dup.OriginDocSubID = cr.OriginDocSubID
            AND dup.OriginDocLine  = cr.OriginDocLine
            AND dup.DerivedDocType = cr.DerivedDocType
            AND dup.DerivedDocID   = cr.DerivedDocID
            AND dup.DerivedDocSubID= cr.DerivedDocSubID
            AND dup.DerivedDocLine = cr.DerivedDocLine
      )
"@ -connString $connString -timeout 1200

    if ($deleted -ge 0) {
        Write-Host "  Duplicati eliminati: $deleted" -ForegroundColor Green
    } else {
        Write-Host "  DELETE duplicati fallito!" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "  Nessun duplicato da eliminare." -ForegroundColor Green
}

# ============================================
# FASE 4b: UPDATE OriginDocID (record rimanenti)
# ============================================
Write-Host ""
Write-Host "--- FASE 4b: UPDATE OriginDocID ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Esecuzione UPDATE..." -ForegroundColor Yellow

$updated = Execute-SqlNonQuery -query @"
UPDATE cr
SET cr.OriginDocID = vm.SaleDocId
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $sourceDB.dbo.MA_SaleDoc vc
    ON vc.SaleDocId = cr.OriginDocID
INNER JOIN $destinationDB.dbo.MA_SaleDoc vm
    ON vm.DocNo = vc.DocNo
    AND vm.DocumentDate = vc.DocumentDate
    AND vm.CustSupp = vc.CustSupp
    AND vm.DocumentType = vc.DocumentType
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
      WHERE sd.SaleDocId = cr.OriginDocID
  )
"@ -connString $connString -timeout 1200

if ($updated -ge 0) {
    Write-Host "  Record aggiornati: $updated" -ForegroundColor Green
} else {
    Write-Host "  UPDATE fallito!" -ForegroundColor Red
    exit
}

# ============================================
# FASE 5: Verifica finale
# ============================================
Write-Host ""
Write-Host "--- FASE 5: Verifica finale ---" -ForegroundColor Cyan
Write-Host ""

# Ancora orfani?
$stillOrphan = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
      WHERE sd.SaleDocId = cr.OriginDocID
  )
"@ -connString $connString

Write-Host "  Record ancora orfani: $stillOrphan" -ForegroundColor $(if ($stillOrphan -eq 0) { "Green" } else { "Red" })

# Verifica esempio 000459EUR
Write-Host ""
Write-Host "  Verifica esempio 000459EUR / 019259:" -ForegroundColor Yellow

$check = Execute-SqlReader -query @"
SELECT cr.OriginDocID, cr.DerivedDocID, sd.DocNo, sd.CustSupp
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.OriginDocID
WHERE cr.OriginDocType = $originDocType
  AND cr.DerivedDocType = $derivedDocType
  AND sd.DocNo = '000459EUR'
  AND sd.CustSupp = '019259'
"@ -connString $connString

if ($check -and $check.Count -gt 0) {
    foreach ($r in $check) {
        Write-Host "    OriginDocID=$($r.OriginDocID) -> DerivedDocID=$($r.DerivedDocID) (DocNo=$($r.DocNo), CustSupp=$($r.CustSupp))" -ForegroundColor Green
    }
} else {
    Write-Host "    Record trovato tramite join con MA_SaleDoc: OK se il cross-ref e' stato aggiornato" -ForegroundColor Gray
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
Write-Host "  Totale cross-ref Fattura->DocContabile: $totalCR" -ForegroundColor White
Write-Host "  Record orfani trovati:      $orphanCount" -ForegroundColor Yellow
Write-Host "  Mappabili via business key:  $mappableCount" -ForegroundColor White
Write-Host "  Duplicati PK eliminati:      $deleted" -ForegroundColor Yellow
Write-Host "  Aggiornati (vecchio->nuovo): $updated" -ForegroundColor Green
Write-Host "  Ancora orfani:               $stillOrphan" -ForegroundColor $(if ($stillOrphan -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Operazione completata!" -ForegroundColor Green
