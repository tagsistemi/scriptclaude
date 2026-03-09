# =============================================================================
# 02_EstraiOffsetDMS.ps1
# Estrae l'offset esatto per ogni DocumentType da TAG_CrMaps
# e costruisce la mappa definitiva IdType -> offset per database
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername    = "sa"
$SqlPassword   = "stream"

$CloneConfigs = @(
    @{ ErpClone = "gpxnetclone";      DmsDb = "gpxnetdms";     Label = "GPXNET" }
    @{ ErpClone = "furmanetclone";    DmsDb = "furmanetdms";   Label = "FURMANET" }
    @{ ErpClone = "vedbondifeclone";  DmsDb = "vedbondifedms"; Label = "VEDBONDIFE" }
)

# Mappa DocumentType -> descrizione (da TAG_DocumentTypesCr)
$DocTypeNames = @{
    3801088 = "DDT"
    3801090 = "DDT Fornitore Lav.Esterna"
    3801091 = "Fattura Accompagnatoria"
    3801093 = "Movimento Magazzino"
    3801095 = "Fattura Immediata"
    3801097 = "Nota di Credito"
    3801098 = "Ordine Cliente"
    3801099 = "Offerta Cliente"
    3801100 = "Ordine Fornitore"
    3801102 = "Fattura di Acconto"
    3801107 = "Paragon"
    3801109 = "Offerta Fornitore"
    3801110 = "Trasferimento tra Depositi"
    3801127 = "RdA"
    3801155 = "AutoFattura"
    3801188 = "Rapportino"
    3801189 = "Analisi"
    3801290 = "Libretto delle Misure"
    3801291 = "SAL"
    3801310 = "Richiesta Offerta"
    9830400 = "Bolla di Carico"
    9830401 = "Fattura di Acquisto"
    9830402 = "NC Ricevuta"
    9830405 = "Fatt.Acquisto Acconto"
}

Add-Type -AssemblyName System.Data

function Invoke-SqlQuery {
    param([string]$Database, [string]$Query)
    $connStr = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connStr
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.CommandText = $Query
    $command.Connection = $connection
    $command.CommandTimeout = 300
    $results = @()
    try {
        $connection.Open()
        $reader = $command.ExecuteReader()
        while ($reader.Read()) {
            $obj = @{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $obj[$reader.GetName($i)] = $reader.GetValue($i)
            }
            $results += [PSCustomObject]$obj
        }
        $reader.Close()
    }
    catch { Write-Host "  ERRORE su $Database : $_" -ForegroundColor Red }
    finally { if ($connection.State -eq 'Open') { $connection.Close() } }
    return $results
}

# =============================================================================
# SEZIONE 1: Offset per DocumentType da TAG_CrMaps
# =============================================================================
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 1: OFFSET PER DocumentType (da TAG_CrMaps)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Calcola offset come (NewDocId - OldId) per il primo record di ogni DocumentType
$offsetQuery = @"
;WITH OffsetCalc AS (
    SELECT
        DocumentType,
        OldId,
        NewDocId,
        NewDocId - OldId AS Offset,
        ROW_NUMBER() OVER (PARTITION BY DocumentType ORDER BY OldId) AS rn
    FROM TAG_CrMaps
    WHERE OldId > 0
)
SELECT
    DocumentType,
    Offset,
    COUNT(*) AS NumRecords,
    MIN(OldId) AS MinOldId,
    MAX(OldId) AS MaxOldId
FROM OffsetCalc
WHERE rn <= 10
GROUP BY DocumentType, Offset
ORDER BY DocumentType, Offset
"@

$allOffsets = @()

foreach ($cfg in $CloneConfigs) {
    Write-Host "`n--- $($cfg.Label) [$($cfg.ErpClone)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $cfg.ErpClone -Query $offsetQuery

    foreach ($row in $rows) {
        $dt = [int]$row.DocumentType
        $dtName = if ($DocTypeNames.ContainsKey($dt)) { $DocTypeNames[$dt] } else { "???" }
        $offset = [int]$row.Offset
        Write-Host ("  DocType={0,-8} ({1,-30}) | Offset={2,+10} | {3,6} record | OldId: {4,8}-{5,8}" -f `
            $dt, $dtName, $offset, $row.NumRecords, $row.MinOldId, $row.MaxOldId)

        $allOffsets += [PSCustomObject]@{
            Clone        = $cfg.ErpClone
            DmsDb        = $cfg.DmsDb
            Label        = $cfg.Label
            DocumentType = $dt
            DocTypeName  = $dtName
            Offset       = $offset
        }
    }
}

# =============================================================================
# SEZIONE 2: Verifica consistenza offset (tutti i record stesso offset?)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 2: VERIFICA CONSISTENZA OFFSET (anomalie)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$consistencyQuery = @"
SELECT
    DocumentType,
    NewDocId - OldId AS Offset,
    COUNT(*) AS NumRecords
FROM TAG_CrMaps
WHERE OldId > 0
GROUP BY DocumentType, NewDocId - OldId
HAVING COUNT(*) > 0
ORDER BY DocumentType, Offset
"@

foreach ($cfg in $CloneConfigs) {
    Write-Host "`n--- $($cfg.Label) [$($cfg.ErpClone)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $cfg.ErpClone -Query $consistencyQuery

    # Raggruppa per DocumentType
    $grouped = $rows | Group-Object -Property { [int]$_.DocumentType }
    foreach ($group in $grouped) {
        if ($group.Count -gt 1) {
            $dt = [int]$group.Name
            $dtName = if ($DocTypeNames.ContainsKey($dt)) { $DocTypeNames[$dt] } else { "???" }
            Write-Host "  ANOMALIA DocType=$dt ($dtName) - offset multipli:" -ForegroundColor Red
            foreach ($row in $group.Group) {
                Write-Host ("    Offset={0,+10} | {1,8} record" -f [int]$row.Offset, $row.NumRecords) -ForegroundColor Red
            }
        }
    }

    $singleOffset = $grouped | Where-Object { $_.Count -eq 1 }
    Write-Host "  DocumentType con offset consistente: $($singleOffset.Count)/$($grouped.Count)" -ForegroundColor Green
}

# =============================================================================
# SEZIONE 3: Raggruppa DocumentType per IdType (stessa famiglia di offset)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 3: RAGGRUPPAMENTO DocumentType PER FAMIGLIA IdType" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# DocumentType che usano lo stesso ID (stessa tabella ERP)
# Basato sulla conoscenza dello schema Mago.net
$IdTypeFamilies = @{
    "SaleDocId" = @(3801088, 3801089, 3801090, 3801091, 3801094, 3801095, 3801096, 3801097,
                    3801101, 3801102, 3801103, 3801104, 3801105, 3801106, 3801107, 3801108,
                    3801110, 3801111, 3801155, 3801156, 3801157)
    "PurchaseDocId" = @(9830400, 9830401, 9830402, 9830403, 9830404, 9830405, 9830406, 9830407)
    "EntryId" = @(3801093)
    "PurchaseOrdId" = @(3801100)
    "CustQuotaId" = @(3801099)
    "SuppQuotaId" = @(3801109)
    "SaleOrdId" = @(3801098)
    "WorkingReportId" = @(3801188)
    "JobQuotationId" = @(3801189)
    "MeasuresBookId" = @(3801290)
    "WPRId" = @(3801291)
    "QuotationRequestId" = @(3801310)
}

Write-Host ""
Write-Host "  MAPPA DEFINITIVA IdType -> Offset per database:" -ForegroundColor Green
Write-Host ("  {0,-25} | {1,12} | {2,12} | {3,12}" -f "IdType", "GPXNET", "FURMANET", "VEDBONDIFE") -ForegroundColor White
Write-Host ("  " + ("-" * 70))

foreach ($family in $IdTypeFamilies.GetEnumerator() | Sort-Object Name) {
    $idType = $family.Key
    $docTypes = $family.Value

    $offsets = @{}
    foreach ($cfg in $CloneConfigs) {
        $match = $allOffsets | Where-Object {
            $_.Clone -eq $cfg.ErpClone -and $docTypes -contains $_.DocumentType
        } | Select-Object -First 1
        if ($match) {
            $offsets[$cfg.Label] = $match.Offset
        }
        else {
            $offsets[$cfg.Label] = "-"
        }
    }

    $gpx = if ($offsets["GPXNET"] -is [int]) { "+{0}" -f $offsets["GPXNET"] } else { "-" }
    $fur = if ($offsets["FURMANET"] -is [int]) { "+{0}" -f $offsets["FURMANET"] } else { "-" }
    $bon = if ($offsets["VEDBONDIFE"] -is [int]) { "+{0}" -f $offsets["VEDBONDIFE"] } else { "-" }

    Write-Host ("  {0,-25} | {1,12} | {2,12} | {3,12}" -f $idType, $gpx, $fur, $bon)
}

# =============================================================================
# SEZIONE 4: Verifica SaleOrdId (valori negativi)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 4: VERIFICA SaleOrdId (valori negativi/speciali)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$saleOrdQuery = @"
SELECT TOP 10 PrimaryKeyValue
FROM dbo.DMS_ErpDocument
WHERE PrimaryKeyValue LIKE 'SaleOrdId:%'
ORDER BY ErpDocumentID
"@

foreach ($cfg in $CloneConfigs) {
    Write-Host "`n--- $($cfg.Label) [$($cfg.DmsDb)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $cfg.DmsDb -Query $saleOrdQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host "  $($row.PrimaryKeyValue)"
        }
    }
    else {
        Write-Host "  (nessun SaleOrdId)" -ForegroundColor DarkGray
    }
}

# Verifica TAG_CrMaps per SaleOrdId (DocumentType=3801098)
$saleOrdCrQuery = @"
SELECT TOP 5 OldId, DocumentType, NewDocId, NewDocId - OldId AS Offset
FROM TAG_CrMaps
WHERE DocumentType = 3801098
ORDER BY OldId
"@

foreach ($cfg in $CloneConfigs) {
    Write-Host "`n--- TAG_CrMaps SaleOrdId su $($cfg.ErpClone) ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $cfg.ErpClone -Query $saleOrdCrQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host ("  OldId={0,8} | NewDocId={1,8} | Offset={2,+8}" -f $row.OldId, $row.NewDocId, $row.Offset)
        }
    }
    else {
        Write-Host "  (nessun record con DocumentType=3801098)" -ForegroundColor DarkGray
    }
}

# Verifica anche OldId negativi in TAG_CrMaps
$negativeCrQuery = @"
SELECT TOP 5 OldId, DocumentType, NewDocId
FROM TAG_CrMaps
WHERE OldId < 0
ORDER BY OldId
"@

foreach ($cfg in $CloneConfigs) {
    Write-Host "`n--- TAG_CrMaps OldId negativi su $($cfg.ErpClone) ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $cfg.ErpClone -Query $negativeCrQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host ("  OldId={0,8} | DocType={1,8} | NewDocId={2,8}" -f $row.OldId, $row.DocumentType, $row.NewDocId)
        }
    }
    else {
        Write-Host "  (nessun OldId negativo)" -ForegroundColor DarkGray
    }
}

# =============================================================================
# SEZIONE 5: Verifica Job codes in DMS (rimappatura stringhe)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 5: VERIFICA Job codes IN DMS vs MM4_MappaJobsCodes" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$jobDmsQuery = @"
SELECT TOP 10 PrimaryKeyValue
FROM dbo.DMS_ErpDocument
WHERE PrimaryKeyValue LIKE 'Job:%'
ORDER BY ErpDocumentID
"@

foreach ($cfg in $CloneConfigs) {
    Write-Host "`n--- $($cfg.Label) [$($cfg.DmsDb)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $cfg.DmsDb -Query $jobDmsQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            # Estrai il codice Job
            $pkv = [string]$row.PrimaryKeyValue
            if ($pkv -match 'Job:([^;]+);') {
                $jobCode = $matches[1]
                # Cerca in MM4_MappaJobsCodes
                $mapQuery = "SELECT vecchiocodice, nuovocodice FROM MM4_MappaJobsCodes WHERE vecchiocodice LIKE '%$jobCode%' OR nuovocodice LIKE '%$jobCode%'"
                $mapRows = Invoke-SqlQuery -Database $cfg.ErpClone -Query $mapQuery

                if ($mapRows.Count -gt 0) {
                    Write-Host "  $pkv -> MATCH: $($mapRows[0].vecchiocodice) => $($mapRows[0].nuovocodice)" -ForegroundColor Green
                }
                else {
                    Write-Host "  $pkv -> nessun match in MM4_MappaJobsCodes" -ForegroundColor DarkGray
                }
            }
            else {
                Write-Host "  $pkv" -ForegroundColor DarkGray
            }
        }
    }
    else {
        Write-Host "  (nessun Job in DMS)" -ForegroundColor DarkGray
    }
}

# =============================================================================
# SEZIONE 6: Verifica IdRam
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 6: VERIFICA IdRam" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$ramQuery = @"
SELECT PrimaryKeyValue
FROM dbo.DMS_ErpDocument
WHERE PrimaryKeyValue LIKE 'IdRam:%'
"@

foreach ($cfg in $CloneConfigs) {
    Write-Host "`n--- $($cfg.Label) [$($cfg.DmsDb)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $cfg.DmsDb -Query $ramQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host "  $($row.PrimaryKeyValue)"
        }
        # Cerca se esiste una tabella RAM con mapping
        $ramTableQuery = @"
SELECT t.name FROM sys.tables t
WHERE t.name LIKE '%Ram%' OR t.name LIKE '%GPX%RAM%'
ORDER BY t.name
"@
        $ramTables = Invoke-SqlQuery -Database $cfg.ErpClone -Query $ramTableQuery
        if ($ramTables.Count -gt 0) {
            Write-Host "  Tabelle RAM trovate:" -ForegroundColor White
            foreach ($t in $ramTables) { Write-Host "    $($t.name)" }
        }
    }
    else {
        Write-Host "  (nessun IdRam)" -ForegroundColor DarkGray
    }
}

# =============================================================================
# SEZIONE 7: Riepilogo tipi che NON richiedono rimappatura
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 7: RIEPILOGO TIPI SENZA RIMAPPATURA (solo vedcontab base)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$noRemapTypes = @("JournalEntryId", "PymtSchedId", "FeeId", "CompanyId", "Specification",
                   "Item", "Employee", "CustSuppType")

foreach ($idType in $noRemapTypes) {
    $likePattern = "${idType}:%"
    $countQuery = @"
SELECT COUNT(*) AS Cnt
FROM dbo.DMS_ErpDocument
WHERE PrimaryKeyValue LIKE '$likePattern'
"@
    $totalInClones = 0
    $inDbs = @()
    foreach ($cfg in $CloneConfigs) {
        $rows = Invoke-SqlQuery -Database $cfg.DmsDb -Query $countQuery
        if ($rows.Count -gt 0 -and [int]$rows[0].Cnt -gt 0) {
            $totalInClones += [int]$rows[0].Cnt
            $inDbs += "$($cfg.Label)($($rows[0].Cnt))"
        }
    }
    # Anche vedcontab
    $vedRows = Invoke-SqlQuery -Database "vedcontabdms" -Query $countQuery
    $vedCount = if ($vedRows.Count -gt 0) { [int]$vedRows[0].Cnt } else { 0 }

    $status = if ($totalInClones -eq 0 -and $vedCount -gt 0) { "SOLO BASE - OK" }
              elseif ($totalInClones -gt 0) { "PRESENTE IN CLONI - VERIFICARE" }
              else { "NESSUN RECORD" }
    $color = if ($totalInClones -gt 0) { "Yellow" } else { "Green" }

    Write-Host ("  {0,-20} | vedcontab: {1,6} | cloni: {2,6} | {3} {4}" -f `
        $idType, $vedCount, $totalInClones, $status, ($inDbs -join ", ")) -ForegroundColor $color
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "ESTRAZIONE OFFSET COMPLETATA" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
