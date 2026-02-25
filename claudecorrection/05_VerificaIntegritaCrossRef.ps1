# ============================================
# SCRIPT: Verifica Integrità CrossReferences
# ============================================
# Versione: 1.0
# Data: 2025-01-29
# Descrizione: Verifica completa dell'integrità dei cross-references
#              dopo la migrazione e gli aggiornamenti
# ============================================

# Carica la configurazione
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\00_Config.ps1"

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  VERIFICA INTEGRITA' CROSSREFERENCES" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$startTime = Get-Date
Write-ColorOutput "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-Host ""

$allIssues = @()
$allWarnings = @()
$stats = @{}

# ============================================
# FASE 1: Verifica su VEDMaster (database destinazione)
# ============================================
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 1: Verifica su $Global:DestinationDB" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Conta record totali
$totalRecords = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $Global:DestinationDB.dbo.MA_CrossReferences"
Write-ColorOutput "Record totali in MA_CrossReferences: $totalRecords" "White"
$stats["VEDMaster_TotalRecords"] = $totalRecords

# ============================================
# Verifica 1.1: Riferimenti orfani a MA_SaleDoc
# ============================================
Write-ColorOutput "" "White"
Write-ColorOutput "Verifica 1.1: Riferimenti orfani a documenti vendita..." "Yellow"

$saleDocTypes = $Global:DDTDocTypes + @(27066385, 27066386, 27066387, 27066388, 27066389, 27066390, 27066396, 27066397, 27066391, 27066392, 27066393)
$saleDocTypeList = $saleDocTypes -join ","

$queryOrphanOriginSale = @"
SELECT
    cr.OriginDocType,
    COUNT(*) as OrphanCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $Global:DestinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.OriginDocID
WHERE cr.OriginDocType IN ($saleDocTypeList)
    AND sd.SaleDocId IS NULL
GROUP BY cr.OriginDocType
"@

$orphanOriginSale = Execute-SqlReader -Query $queryOrphanOriginSale -Database $Global:DestinationDB
if ($orphanOriginSale -and $orphanOriginSale.Rows.Count -gt 0) {
    foreach ($row in $orphanOriginSale.Rows) {
        $msg = "OriginDocID orfani per DocType $($row.OriginDocType): $($row.OrphanCount) record"
        Write-ColorOutput "  PROBLEMA: $msg" "Red"
        $allIssues += "[VEDMaster] $msg"
    }
}
else {
    Write-ColorOutput "  OK: Nessun OriginDocID orfano per documenti vendita" "Green"
}

$queryOrphanDerivedSale = @"
SELECT
    cr.DerivedDocType,
    COUNT(*) as OrphanCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $Global:DestinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.DerivedDocID
WHERE cr.DerivedDocType IN ($saleDocTypeList)
    AND sd.SaleDocId IS NULL
GROUP BY cr.DerivedDocType
"@

$orphanDerivedSale = Execute-SqlReader -Query $queryOrphanDerivedSale -Database $Global:DestinationDB
if ($orphanDerivedSale -and $orphanDerivedSale.Rows.Count -gt 0) {
    foreach ($row in $orphanDerivedSale.Rows) {
        $msg = "DerivedDocID orfani per DocType $($row.DerivedDocType): $($row.OrphanCount) record"
        Write-ColorOutput "  PROBLEMA: $msg" "Red"
        $allIssues += "[VEDMaster] $msg"
    }
}
else {
    Write-ColorOutput "  OK: Nessun DerivedDocID orfano per documenti vendita" "Green"
}

# ============================================
# Verifica 1.2: Riferimenti orfani a MA_PurchaseDoc
# ============================================
Write-ColorOutput "" "White"
Write-ColorOutput "Verifica 1.2: Riferimenti orfani a documenti acquisto..." "Yellow"

$purchaseDocTypes = @(27066402, 27066403, 27066404, 27066405, 27066406, 27066400, 27066401)
$purchaseDocTypeList = $purchaseDocTypes -join ","

$queryOrphanOriginPurchase = @"
SELECT
    cr.OriginDocType,
    COUNT(*) as OrphanCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $Global:DestinationDB.dbo.MA_PurchaseDoc pd ON pd.PurchaseDocId = cr.OriginDocID
WHERE cr.OriginDocType IN ($purchaseDocTypeList)
    AND pd.PurchaseDocId IS NULL
GROUP BY cr.OriginDocType
"@

$orphanOriginPurchase = Execute-SqlReader -Query $queryOrphanOriginPurchase -Database $Global:DestinationDB
if ($orphanOriginPurchase -and $orphanOriginPurchase.Rows.Count -gt 0) {
    foreach ($row in $orphanOriginPurchase.Rows) {
        $msg = "OriginDocID orfani acquisti per DocType $($row.OriginDocType): $($row.OrphanCount) record"
        Write-ColorOutput "  PROBLEMA: $msg" "Red"
        $allIssues += "[VEDMaster] $msg"
    }
}
else {
    Write-ColorOutput "  OK: Nessun OriginDocID orfano per documenti acquisto" "Green"
}

$queryOrphanDerivedPurchase = @"
SELECT
    cr.DerivedDocType,
    COUNT(*) as OrphanCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $Global:DestinationDB.dbo.MA_PurchaseDoc pd ON pd.PurchaseDocId = cr.DerivedDocID
WHERE cr.DerivedDocType IN ($purchaseDocTypeList)
    AND pd.PurchaseDocId IS NULL
GROUP BY cr.DerivedDocType
"@

$orphanDerivedPurchase = Execute-SqlReader -Query $queryOrphanDerivedPurchase -Database $Global:DestinationDB
if ($orphanDerivedPurchase -and $orphanDerivedPurchase.Rows.Count -gt 0) {
    foreach ($row in $orphanDerivedPurchase.Rows) {
        $msg = "DerivedDocID orfani acquisti per DocType $($row.DerivedDocType): $($row.OrphanCount) record"
        Write-ColorOutput "  PROBLEMA: $msg" "Red"
        $allIssues += "[VEDMaster] $msg"
    }
}
else {
    Write-ColorOutput "  OK: Nessun DerivedDocID orfano per documenti acquisto" "Green"
}

# ============================================
# Verifica 1.3: Riferimenti orfani a Commesse (Jobs)
# ============================================
Write-ColorOutput "" "White"
Write-ColorOutput "Verifica 1.3: Riferimenti orfani a commesse..." "Yellow"

$jobDocTypeList = $Global:JobDocTypes -join ","

$queryOrphanJobs = @"
SELECT
    cr.OriginDocType,
    COUNT(*) as OrphanCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $Global:DestinationDB.dbo.IM_Jobs j ON j.Job = cr.OriginDocID
WHERE cr.OriginDocType IN ($jobDocTypeList)
    AND j.Job IS NULL
GROUP BY cr.OriginDocType
"@

$orphanJobs = Execute-SqlReader -Query $queryOrphanJobs -Database $Global:DestinationDB
if ($orphanJobs -and $orphanJobs.Rows.Count -gt 0) {
    foreach ($row in $orphanJobs.Rows) {
        $msg = "OriginDocID orfani commesse per DocType $($row.OriginDocType): $($row.OrphanCount) record"
        Write-ColorOutput "  AVVISO: $msg" "Yellow"
        $allWarnings += "[VEDMaster] $msg"
    }
}
else {
    Write-ColorOutput "  OK: Nessun riferimento orfano a commesse" "Green"
}

# ============================================
# Verifica 1.4: Range ID per database sorgente
# ============================================
Write-ColorOutput "" "White"
Write-ColorOutput "Verifica 1.4: Analisi range ID..." "Yellow"

$queryRanges = @"
SELECT
    'OriginDocID' as IDType,
    MIN(OriginDocID) as MinID,
    MAX(OriginDocID) as MaxID,
    COUNT(DISTINCT OriginDocID) as DistinctCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences
UNION ALL
SELECT
    'DerivedDocID' as IDType,
    MIN(DerivedDocID) as MinID,
    MAX(DerivedDocID) as MaxID,
    COUNT(DISTINCT DerivedDocID) as DistinctCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences
"@

$ranges = Execute-SqlReader -Query $queryRanges -Database $Global:DestinationDB
if ($ranges -and $ranges.Rows.Count -gt 0) {
    foreach ($row in $ranges.Rows) {
        Write-ColorOutput "  $($row.IDType): Min=$($row.MinID), Max=$($row.MaxID), Distinti=$($row.DistinctCount)" "Gray"
    }
}

# ============================================
# Verifica 1.5: DocTypes presenti
# ============================================
Write-ColorOutput "" "White"
Write-ColorOutput "Verifica 1.5: DocTypes utilizzati..." "Yellow"

$queryDocTypes = @"
SELECT
    'Origin' as RefType,
    OriginDocType as DocType,
    COUNT(*) as RecordCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences
GROUP BY OriginDocType
UNION ALL
SELECT
    'Derived' as RefType,
    DerivedDocType as DocType,
    COUNT(*) as RecordCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences
GROUP BY DerivedDocType
ORDER BY RefType, DocType
"@

$docTypes = Execute-SqlReader -Query $queryDocTypes -Database $Global:DestinationDB
$originTypes = @()
$derivedTypes = @()

if ($docTypes -and $docTypes.Rows.Count -gt 0) {
    Write-ColorOutput "  DocTypes trovati:" "White"
    foreach ($row in $docTypes.Rows) {
        Write-ColorOutput "    $($row.RefType) DocType $($row.DocType): $($row.RecordCount) record" "Gray"
        if ($row.RefType -eq "Origin") {
            $originTypes += $row.DocType
        }
        else {
            $derivedTypes += $row.DocType
        }
    }
}

$stats["VEDMaster_OriginTypes"] = $originTypes.Count
$stats["VEDMaster_DerivedTypes"] = $derivedTypes.Count

# ============================================
# FASE 2: Verifica consistenza con tabelle mappatura
# ============================================
Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 2: Verifica tabelle mappatura" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Verifica TAG_SaleDocMapping
if (Test-TableExists -Database $Global:DestinationDB -TableName "TAG_SaleDocMapping") {
    $countSaleMapping = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $Global:DestinationDB.dbo.TAG_SaleDocMapping"
    Write-ColorOutput "TAG_SaleDocMapping: $countSaleMapping mappature" "White"

    # Verifica mappature non utilizzate
    $queryUnusedSale = @"
SELECT COUNT(*)
FROM $Global:DestinationDB.dbo.TAG_SaleDocMapping m
WHERE NOT EXISTS (
    SELECT 1 FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
    WHERE cr.OriginDocID = m.NewSaleDocId OR cr.DerivedDocID = m.NewSaleDocId
)
"@
    $unusedSale = Execute-SqlScalar -Query $queryUnusedSale -Database $Global:DestinationDB
    if ($unusedSale -gt 0) {
        Write-ColorOutput "  Mappature non utilizzate in CrossReferences: $unusedSale" "Yellow"
    }
}
else {
    Write-ColorOutput "TAG_SaleDocMapping: NON ESISTE (creata da 04_PostTrasfAggiornaRiferimentiCompleto.ps1)" "Yellow"
}

# Verifica TAG_PurchaseDocMapping
if (Test-TableExists -Database $Global:DestinationDB -TableName "TAG_PurchaseDocMapping") {
    $countPurchaseMapping = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $Global:DestinationDB.dbo.TAG_PurchaseDocMapping"
    Write-ColorOutput "TAG_PurchaseDocMapping: $countPurchaseMapping mappature" "White"
}
else {
    Write-ColorOutput "TAG_PurchaseDocMapping: NON ESISTE (creata da 04_PostTrasfAggiornaRiferimentiCompleto.ps1)" "Yellow"
}

# ============================================
# FASE 3: Verifica database sorgente (clone)
# ============================================
Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 3: Verifica database sorgenti" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

foreach ($db in $Global:CloneDatabases) {
    Write-ColorOutput "Database: $db" "Yellow"
    $offset = Get-DatabaseOffset -DatabaseName $db
    Write-ColorOutput "  Offset atteso: $offset" "Gray"

    # Conta record
    $count = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $db.dbo.MA_CrossReferences"
    Write-ColorOutput "  Record CrossReferences: $count" "White"
    $stats["${db}_Records"] = $count

    # Verifica range ID
    $queryDbRanges = @"
SELECT
    MIN(OriginDocID) as MinOrigin,
    MAX(OriginDocID) as MaxOrigin,
    MIN(DerivedDocID) as MinDerived,
    MAX(DerivedDocID) as MaxDerived
FROM $db.dbo.MA_CrossReferences
"@
    $dbRanges = Execute-SqlReader -Query $queryDbRanges -Database $db
    if ($dbRanges -and $dbRanges.Rows.Count -gt 0) {
        $row = $dbRanges.Rows[0]
        Write-ColorOutput "  Range OriginDocID: $($row.MinOrigin) - $($row.MaxOrigin)" "Gray"
        Write-ColorOutput "  Range DerivedDocID: $($row.MinDerived) - $($row.MaxDerived)" "Gray"

        # Verifica che i range siano nell'intervallo corretto per l'offset
        $expectedMin = $offset
        $expectedMax = $offset + 99999

        if ($offset -gt 0) {
            if ($row.MaxOrigin -lt $expectedMin -or $row.MinOrigin -gt $expectedMax) {
                Write-ColorOutput "  AVVISO: Range OriginDocID fuori dall'intervallo atteso ($expectedMin - $expectedMax)" "Yellow"
                $allWarnings += "[$db] Range OriginDocID potrebbe non essere stato rinumerato correttamente"
            }
        }
    }

    # Verifica TAG_CrMaps
    if (Test-TableExists -Database $db -TableName "TAG_CrMaps") {
        $countCrMaps = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $db.dbo.TAG_CrMaps"
        Write-ColorOutput "  TAG_CrMaps: $countCrMaps mappature" "Green"
    }
    else {
        Write-ColorOutput "  TAG_CrMaps: NON ESISTE" "Yellow"
        $allWarnings += "[$db] TAG_CrMaps non presente"
    }

    # Verifica TAG_DocumentTypesCr
    if (Test-TableExists -Database $db -TableName "TAG_DocumentTypesCr") {
        $countDocTypes = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $db.dbo.TAG_DocumentTypesCr"
        Write-ColorOutput "  TAG_DocumentTypesCr: $countDocTypes tipi" "Green"

        if ($countDocTypes -lt 70) {
            Write-ColorOutput "  AVVISO: Meno di 70 DocTypes (mappa incompleta?)" "Yellow"
            $allWarnings += "[$db] TAG_DocumentTypesCr potrebbe essere incompleta ($countDocTypes tipi)"
        }
    }
    else {
        Write-ColorOutput "  TAG_DocumentTypesCr: NON ESISTE" "Red"
        $allIssues += "[$db] TAG_DocumentTypesCr non presente - eseguire 01_CreaMappaDocTypeCompleta.ps1"
    }

    Write-Host ""
}

# ============================================
# FASE 4: Verifica duplicati e integrità chiave primaria
# ============================================
Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 4: Verifica integrità chiave primaria" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

Write-ColorOutput "Controllo duplicati su VEDMaster..." "Yellow"

$queryDuplicates = @"
SELECT
    OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
    DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
    COUNT(*) as DuplicateCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences
GROUP BY OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
         DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine
HAVING COUNT(*) > 1
"@

$duplicates = Execute-SqlReader -Query $queryDuplicates -Database $Global:DestinationDB
if ($duplicates -and $duplicates.Rows.Count -gt 0) {
    Write-ColorOutput "  PROBLEMA: Trovati $($duplicates.Rows.Count) gruppi di duplicati!" "Red"
    $allIssues += "[VEDMaster] Trovati $($duplicates.Rows.Count) gruppi di record duplicati"

    # Mostra primi 5
    $shown = 0
    foreach ($row in $duplicates.Rows) {
        if ($shown -ge 5) { break }
        Write-ColorOutput "    Origin($($row.OriginDocType),$($row.OriginDocID)) -> Derived($($row.DerivedDocType),$($row.DerivedDocID)): $($row.DuplicateCount) copie" "Red"
        $shown++
    }
    if ($duplicates.Rows.Count -gt 5) {
        Write-ColorOutput "    ... e altri $($duplicates.Rows.Count - 5) gruppi" "Red"
    }
}
else {
    Write-ColorOutput "  OK: Nessun duplicato trovato" "Green"
}

# ============================================
# FASE 5: Verifica coerenza tra Origin e Derived
# ============================================
Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 5: Verifica coerenza riferimenti" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Verifica riferimenti circolari (Origin = Derived)
Write-ColorOutput "Controllo riferimenti circolari..." "Yellow"

$queryCircular = @"
SELECT COUNT(*)
FROM $Global:DestinationDB.dbo.MA_CrossReferences
WHERE OriginDocType = DerivedDocType
    AND OriginDocID = DerivedDocID
    AND OriginDocSubID = DerivedDocSubID
"@

$circularCount = Execute-SqlScalar -Query $queryCircular -Database $Global:DestinationDB
if ($circularCount -gt 0) {
    Write-ColorOutput "  AVVISO: $circularCount riferimenti circolari (documento riferisce se stesso)" "Yellow"
    $allWarnings += "[VEDMaster] $circularCount riferimenti circolari"
}
else {
    Write-ColorOutput "  OK: Nessun riferimento circolare" "Green"
}

# ============================================
# RIEPILOGO FINALE
# ============================================
Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  RIEPILOGO VERIFICA INTEGRITA'" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$endTime = Get-Date
$duration = $endTime - $startTime

Write-ColorOutput "Ora inizio:  $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-ColorOutput "Ora fine:    $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-ColorOutput "Durata:      $($duration.ToString('hh\:mm\:ss'))" "Gray"
Write-Host ""

# Statistiche
Write-ColorOutput "STATISTICHE:" "White"
Write-ColorOutput "  VEDMaster - Record totali: $($stats['VEDMaster_TotalRecords'])" "Gray"
Write-ColorOutput "  VEDMaster - OriginDocType distinti: $($stats['VEDMaster_OriginTypes'])" "Gray"
Write-ColorOutput "  VEDMaster - DerivedDocType distinti: $($stats['VEDMaster_DerivedTypes'])" "Gray"

foreach ($db in $Global:CloneDatabases) {
    $key = "${db}_Records"
    if ($stats.ContainsKey($key)) {
        Write-ColorOutput "  $db - Record: $($stats[$key])" "Gray"
    }
}

Write-Host ""

# Problemi critici
if ($allIssues.Count -gt 0) {
    Write-ColorOutput "PROBLEMI CRITICI ($($allIssues.Count)):" "Red"
    foreach ($issue in $allIssues) {
        Write-ColorOutput "  - $issue" "Red"
    }
    Write-Host ""
}

# Avvisi
if ($allWarnings.Count -gt 0) {
    Write-ColorOutput "AVVISI ($($allWarnings.Count)):" "Yellow"
    foreach ($warning in $allWarnings) {
        Write-ColorOutput "  - $warning" "Yellow"
    }
    Write-Host ""
}

# Risultato finale
if ($allIssues.Count -eq 0 -and $allWarnings.Count -eq 0) {
    Write-ColorOutput "============================================" "Green"
    Write-ColorOutput "  VERIFICA COMPLETATA CON SUCCESSO" "Green"
    Write-ColorOutput "  Nessun problema rilevato" "Green"
    Write-ColorOutput "============================================" "Green"
}
elseif ($allIssues.Count -eq 0) {
    Write-ColorOutput "============================================" "Yellow"
    Write-ColorOutput "  VERIFICA COMPLETATA CON AVVISI" "Yellow"
    Write-ColorOutput "  Controllare gli avvisi sopra riportati" "Yellow"
    Write-ColorOutput "============================================" "Yellow"
}
else {
    Write-ColorOutput "============================================" "Red"
    Write-ColorOutput "  VERIFICA COMPLETATA CON PROBLEMI" "Red"
    Write-ColorOutput "  Risolvere i problemi critici prima di procedere!" "Red"
    Write-ColorOutput "============================================" "Red"
}

Write-Host ""
Write-ColorOutput "Script di correzione disponibili:" "White"
Write-ColorOutput "  - 01_CreaMappaDocTypeCompleta.ps1: Crea mappa DocType completa" "Gray"
Write-ColorOutput "  - 02_VerificaTagCrMaps.ps1: Verifica mappature ID" "Gray"
Write-ColorOutput "  - 03_AggiornaCrossReferencesCompleto.ps1: Aggiorna tutti i CrossReferences" "Gray"
Write-ColorOutput "  - 04_PostTrasfAggiornaRiferimentiCompleto.ps1: Aggiorna riferimenti post-migrazione" "Gray"
