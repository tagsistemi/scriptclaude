# ============================================
# SCRIPT 29: Fix DocId in MA_EIEventViewer
# ============================================
# Versione: 1.0
#
# SCOPO:
#   Dopo la rinumerazione dei SaleDocId su VEDMaster (script 28),
#   la tabella MA_EIEventViewer contiene ancora i vecchi DocId
#   per le fatture emesse (DocCRType = 27066387).
#
#   Questo script aggiorna DocId usando il mapping
#   TAG_RenumberMapping (CurrentSaleDocId -> NewSaleDocId).
#
# QUANDO ESEGUIRE:
#   - DOPO lo script 28 (rinumerazione SaleDocId su VEDMaster)
#
# NOTA:
#   La PK di MA_EIEventViewer e' (DocCRType, DocID, Line).
#   Per evitare collisioni PK durante l'update si usa l'approccio
#   a 2 passaggi: prima valori negativi, poi ABS al valore finale.
# ============================================

# Parametri di connessione
$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"
$destinationDB = "VEDMaster"

# DocCRType per fatture emesse (tutti i tipi documento di vendita)
$saleDocCRTypes = @(
    27066383,  # DDT (Documento di Trasporto)
    27066384,  # DDT al Fornitore per Lavorazione Esterna
    27066385,  # Fattura Accompagnatoria
    27066386,  # Fattura Accompagnatoria a Correzione
    27066387,  # Fattura Immediata
    27066388,  # Fattura a Correzione
    27066389,  # Nota di Credito
    27066390,  # Nota di Debito
    27066391,  # Ricevuta Fiscale
    27066392,  # Ricevuta Fiscale a Correzione
    27066393,  # Ricevuta Fiscale Non Incassata
    27066394,  # Paragon
    27066395,  # Paragon a Correzione
    27066396,  # Fattura di Acconto
    27066397,  # Fattura ProForma
    27066398,  # Documento Trasferimento tra Depositi
    27066399,  # Picking List
    27066382,  # Reso da Cliente
    27066381   # Reso a fornitore
)
$saleDocCRTypesSQL = $saleDocCRTypes -join ", "

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
    param (
        [string]$query,
        [string]$connString
    )
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 300
        $result = $cmd.ExecuteScalar()
        $conn.Close()
        return $result
    }
    catch {
        Write-Host "Errore query scalare: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return $null
    }
}

function Execute-SqlReader {
    param (
        [string]$query,
        [string]$connString
    )
    $results = @()
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 300
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

# Stringa di connessione
$connString = "Server=$serverName;Database=$destinationDB;User ID=$userName;Password=$password;"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SCRIPT 29: Fix DocId in MA_EIEventViewer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
Write-Host "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

# ============================================
# FASE 0: Verifica prerequisiti
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 0: Verifica prerequisiti" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verifica che TAG_RenumberMapping esista
$mappingExists = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.sys.objects
WHERE object_id = OBJECT_ID(N'$destinationDB.dbo.TAG_RenumberMapping') AND type = 'U'
"@ -connString $connString

if ($mappingExists -eq 0) {
    Write-Host "  ERRORE: Tabella TAG_RenumberMapping non trovata!" -ForegroundColor Red
    Write-Host "  Eseguire prima lo script 28 (RinumeraSaleDocVedmaster)." -ForegroundColor Red
    exit
}

$totalMapping = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.TAG_RenumberMapping" -connString $connString
Write-Host "  TAG_RenumberMapping: $totalMapping mappature disponibili" -ForegroundColor White

# Verifica che MA_EIEventViewer esista
$eiTableExists = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.sys.objects
WHERE object_id = OBJECT_ID(N'$destinationDB.dbo.MA_EIEventViewer') AND type = 'U'
"@ -connString $connString

if ($eiTableExists -eq 0) {
    Write-Host "  ERRORE: Tabella MA_EIEventViewer non trovata!" -ForegroundColor Red
    exit
}

Write-Host "  MA_EIEventViewer: presente" -ForegroundColor Green
Write-Host ""

# ============================================
# FASE 1: Diagnostica - stato attuale
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 1: Diagnostica stato attuale" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Conta totale righe per DocCRType
$eiStats = Execute-SqlReader -query @"
SELECT DocCRType, COUNT(*) as Cnt
FROM $destinationDB.dbo.MA_EIEventViewer
WHERE DocCRType IN ($saleDocCRTypesSQL)
GROUP BY DocCRType ORDER BY DocCRType
"@ -connString $connString

if ($eiStats) {
    Write-Host "  Righe in MA_EIEventViewer per tipo documento di vendita:" -ForegroundColor White
    foreach ($row in $eiStats) {
        Write-Host "    DocCRType $($row.DocCRType): $($row.Cnt) righe" -ForegroundColor Gray
    }
}
else {
    Write-Host "  Nessuna riga trovata per i DocCRType di vendita." -ForegroundColor Yellow
    Write-Host "  Nulla da aggiornare. Fine script." -ForegroundColor Yellow
    exit
}

# Conta righe da aggiornare (DocId presente nel mapping come vecchio ID)
$toUpdate = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_EIEventViewer ev
INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m
    ON m.CurrentSaleDocId = ev.DocID
WHERE ev.DocCRType IN ($saleDocCRTypesSQL)
"@ -connString $connString
Write-Host ""
Write-Host "  Righe da aggiornare (DocId con vecchio ID): $toUpdate" -ForegroundColor $(if ($toUpdate -gt 0) { "Yellow" } else { "Green" })

if ($toUpdate -eq 0) {
    Write-Host "  Nessuna riga da aggiornare. I DocId sono gia' corretti." -ForegroundColor Green
    Write-Host ""

    # Verifica comunque se ci sono orfani
    $orphans = Execute-SqlScalar -query @"
    SELECT COUNT(*)
    FROM $destinationDB.dbo.MA_EIEventViewer ev
    WHERE ev.DocCRType IN ($saleDocCRTypesSQL)
      AND NOT EXISTS (
          SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
          WHERE sd.SaleDocId = ev.DocID
      )
"@ -connString $connString
    if ($orphans -gt 0) {
        Write-Host "  ATTENZIONE: $orphans righe hanno DocId che non esiste in MA_SaleDoc!" -ForegroundColor Red
    }
    exit
}

# Campione prima dell'aggiornamento
Write-Host ""
Write-Host "  --- CAMPIONE: Righe da aggiornare ---" -ForegroundColor Yellow
$sampleBefore = Execute-SqlReader -query @"
SELECT TOP 5
    ev.DocCRType,
    ev.DocID as VecchioDocId,
    m.NewSaleDocId as NuovoDocId,
    ev.Line,
    ev.EventDate,
    ev.Event_Description
FROM $destinationDB.dbo.MA_EIEventViewer ev
INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m
    ON m.CurrentSaleDocId = ev.DocID
WHERE ev.DocCRType IN ($saleDocCRTypesSQL)
ORDER BY ev.DocCRType, ev.DocID, ev.Line
"@ -connString $connString

if ($sampleBefore) {
    foreach ($row in $sampleBefore) {
        Write-Host "    DocCRType=$($row.DocCRType) DocId=$($row.VecchioDocId)->$($row.NuovoDocId) Line=$($row.Line) | $($row.Event_Description)" -ForegroundColor Gray
    }
}

Write-Host ""

# ============================================
# FASE 2: Aggiornamento DocId (2 passaggi)
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 2: Aggiornamento DocId (2 passaggi)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  PK = (DocCRType, DocID, Line) -> approccio negativo/positivo" -ForegroundColor Gray
Write-Host ""

# Passaggio 1: DocId -> valore negativo temporaneo (-NewSaleDocId)
Write-Host "  Passaggio 1: DocId -> valori negativi temporanei..." -ForegroundColor Yellow
$pass1Result = Execute-SqlNonQuery -query @"
UPDATE ev
SET ev.DocID = -m.NewSaleDocId
FROM $destinationDB.dbo.MA_EIEventViewer ev
INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m
    ON m.CurrentSaleDocId = ev.DocID
WHERE ev.DocCRType IN ($saleDocCRTypesSQL)
"@ -connString $connString `
    -msgOk "    Passaggio 1 completato" `
    -msgErr "    ERRORE passaggio 1"

if ($pass1Result -eq -1) {
    Write-Host "  ERRORE CRITICO nel passaggio 1. Interruzione." -ForegroundColor Red
    exit
}

# Passaggio 2: DocId negativo -> valore positivo finale (ABS)
Write-Host "  Passaggio 2: DocId -> valori positivi finali..." -ForegroundColor Yellow
$pass2Result = Execute-SqlNonQuery -query @"
UPDATE $destinationDB.dbo.MA_EIEventViewer
SET DocID = ABS(DocID)
WHERE DocID < 0
  AND DocCRType IN ($saleDocCRTypesSQL)
"@ -connString $connString `
    -msgOk "    Passaggio 2 completato" `
    -msgErr "    ERRORE passaggio 2"

if ($pass2Result -eq -1) {
    Write-Host "  ERRORE CRITICO nel passaggio 2. Interruzione." -ForegroundColor Red
    exit
}

Write-Host ""

# ============================================
# FASE 3: Verifica finale
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 3: Verifica finale" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verifica: nessun vecchio ID deve restare
$oldIdsRemaining = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_EIEventViewer ev
INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m
    ON m.CurrentSaleDocId = ev.DocID
WHERE ev.DocCRType IN ($saleDocCRTypesSQL)
  AND m.CurrentSaleDocId <> m.NewSaleDocId
"@ -connString $connString
Write-Host "  Vecchi DocId ancora presenti: $oldIdsRemaining" -ForegroundColor $(if ($oldIdsRemaining -eq 0) { "Green" } else { "Red" })

# Verifica: nessun DocId negativo residuo
$negativeIds = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_EIEventViewer
WHERE DocID < 0
"@ -connString $connString
Write-Host "  DocId negativi residui: $negativeIds" -ForegroundColor $(if ($negativeIds -eq 0) { "Green" } else { "Red" })

# Verifica: DocId orfani (non presenti in MA_SaleDoc)
$orphans = Execute-SqlScalar -query @"
SELECT COUNT(*)
FROM $destinationDB.dbo.MA_EIEventViewer ev
WHERE ev.DocCRType IN ($saleDocCRTypesSQL)
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
      WHERE sd.SaleDocId = ev.DocID
  )
"@ -connString $connString
Write-Host "  DocId orfani (non in MA_SaleDoc): $orphans" -ForegroundColor $(if ($orphans -eq 0) { "Green" } else { "Yellow" })

# Campione dopo aggiornamento
Write-Host ""
Write-Host "  --- CAMPIONE: Righe aggiornate ---" -ForegroundColor Yellow
$sampleAfter = Execute-SqlReader -query @"
SELECT TOP 5
    ev.DocCRType,
    ev.DocID,
    ev.Line,
    ev.EventDate,
    ev.Event_Description
FROM $destinationDB.dbo.MA_EIEventViewer ev
WHERE ev.DocCRType IN ($saleDocCRTypesSQL)
  AND ev.DocID >= 200000
ORDER BY ev.DocCRType, ev.DocID, ev.Line
"@ -connString $connString

if ($sampleAfter) {
    foreach ($row in $sampleAfter) {
        Write-Host "    DocCRType=$($row.DocCRType) DocId=$($row.DocID) Line=$($row.Line) | $($row.Event_Description)" -ForegroundColor Green
    }
}

# ============================================
# RIEPILOGO
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RIEPILOGO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "  Ora inizio:             $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Ora fine:               $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Durata:                 $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host ""
Write-Host "  Righe aggiornate:       $toUpdate" -ForegroundColor White
Write-Host "  Vecchi ID residui:      $oldIdsRemaining" -ForegroundColor White
Write-Host "  DocId orfani:           $orphans" -ForegroundColor White
Write-Host ""

if ($oldIdsRemaining -eq 0 -and $negativeIds -eq 0) {
    Write-Host "  Operazione completata con successo!" -ForegroundColor Green
}
else {
    Write-Host "  ATTENZIONE: verificare i risultati sopra." -ForegroundColor Red
}
