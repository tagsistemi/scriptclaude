# ============================================
# SCRIPT: Aggiornamento Riferimenti Post-Trasferimento
# ============================================
# Versione: 1.0
# Data: 2025-01-29
# Descrizione: Aggiorna TUTTI i riferimenti documenti su VEDMaster dopo la migrazione
#              Risolve l'anomalia degli script 22 e 23 che gestivano solo alcuni tipi
# ============================================

# Carica la configurazione
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\00_Config.ps1"

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  AGGIORNAMENTO RIFERIMENTI POST-TRASFERIMENTO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$startTime = Get-Date
Write-ColorOutput "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-ColorOutput "Database destinazione: $Global:DestinationDB" "Gray"
Write-Host ""

# Verifica che VEDMaster esista e contenga dati
$countCR = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $Global:DestinationDB.dbo.MA_CrossReferences"
Write-ColorOutput "Record in MA_CrossReferences su VEDMaster: $countCR" "White"

if ($countCR -eq 0) {
    Write-ColorOutput "ERRORE: MA_CrossReferences su VEDMaster e' vuota! Eseguire prima la migrazione." "Red"
    exit
}

# ============================================
# FASE 1: Creazione tabella mappatura SaleDoc
# ============================================
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 1: Creazione mappatura SaleDoc" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Crea/Svuota tabella SaleDocMapping
$createMappingTable = @"
IF NOT EXISTS (SELECT * FROM $Global:DestinationDB.sys.objects WHERE object_id = OBJECT_ID(N'$Global:DestinationDB.dbo.TAG_SaleDocMapping') AND type in (N'U'))
BEGIN
    CREATE TABLE $Global:DestinationDB.dbo.TAG_SaleDocMapping (
        SourceDB NVARCHAR(50),
        OldSaleDocId INT,
        NewSaleDocId INT,
        DocumentType INT,
        DocNo NVARCHAR(50),
        DocumentDate DATETIME,
        CustSupp NVARCHAR(50),
        PRIMARY KEY (SourceDB, OldSaleDocId)
    )
END
ELSE
BEGIN
    TRUNCATE TABLE $Global:DestinationDB.dbo.TAG_SaleDocMapping
END
"@

$result = Execute-SqlQuery -Query $createMappingTable -Database $Global:DestinationDB
if ($result.Success) {
    Write-ColorOutput "Tabella TAG_SaleDocMapping creata/svuotata" "Green"
}
else {
    Write-ColorOutput "ERRORE creazione tabella: $($result.Error)" "Red"
}

# Popola mappatura per ogni database sorgente
foreach ($sourceDB in $Global:CloneDatabases) {
    Write-ColorOutput "Popolamento mappatura da: $sourceDB" "Yellow"

    # Query per mappare vecchi ID a nuovi ID basandosi su DocNo + DocumentDate + CustSupp
    $insertMapping = @"
INSERT INTO $Global:DestinationDB.dbo.TAG_SaleDocMapping
    (SourceDB, OldSaleDocId, NewSaleDocId, DocumentType, DocNo, DocumentDate, CustSupp)
SELECT DISTINCT
    '$sourceDB' as SourceDB,
    src.SaleDocId as OldSaleDocId,
    dest.SaleDocId as NewSaleDocId,
    src.DocumentType,
    src.DocNo,
    src.DocumentDate,
    src.CustSupp
FROM $sourceDB.dbo.MA_SaleDoc src
INNER JOIN $Global:DestinationDB.dbo.MA_SaleDoc dest
    ON dest.DocNo = src.DocNo
    AND dest.DocumentDate = src.DocumentDate
    AND dest.CustSupp = src.CustSupp
    AND dest.DocumentType = src.DocumentType
WHERE src.SaleDocId <> dest.SaleDocId;
"@

    $result = Execute-SqlQuery -Query $insertMapping -Database $Global:DestinationDB -Timeout 600
    if ($result.Success) {
        Write-ColorOutput "  Mappature inserite: $($result.RowsAffected)" "Green"
    }
    else {
        Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
    }
}

# Conta mappature totali
$totalMappings = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $Global:DestinationDB.dbo.TAG_SaleDocMapping"
Write-ColorOutput "Totale mappature SaleDoc: $totalMappings" "White"
Write-Host ""

# ============================================
# FASE 2: Aggiornamento OriginDocID per documenti di vendita
# ============================================
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 2: Aggiornamento OriginDocID (Documenti Vendita)" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# DocTypes per documenti di vendita (DDT, Fatture, etc.)
$saleDocTypes = @(
    27066383,  # DDT
    27066384,  # DDT Lavorazione Esterna
    27066385,  # Fattura Accompagnatoria
    27066386,  # Fattura Accompagnatoria a Correzione
    27066387,  # Fattura Immediata
    27066388,  # Fattura a Correzione
    27066389,  # Nota di Credito
    27066390,  # Nota di Debito
    27066396,  # Fattura di Acconto
    27066397,  # Fattura ProForma
    27066391,  # Ricevuta Fiscale
    27066392,  # Ricevuta Fiscale a Correzione
    27066393,  # Ricevuta Fiscale Non Incassata
    27066400,  # Bolla di Carico
    27066401,  # Bolla Carico Lavorazione Esterna
    27066416   # Bolla lavorazione
)

$docTypeList = $saleDocTypes -join ","

$updateOriginSaleDoc = @"
UPDATE cr
SET cr.OriginDocID = m.NewSaleDocId
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
INNER JOIN $Global:DestinationDB.dbo.TAG_SaleDocMapping m
    ON m.OldSaleDocId = cr.OriginDocID
WHERE cr.OriginDocType IN ($docTypeList)
    AND cr.OriginDocID <> m.NewSaleDocId;
"@

$result = Execute-SqlQuery -Query $updateOriginSaleDoc -Database $Global:DestinationDB -Timeout 600
if ($result.Success) {
    Write-ColorOutput "OriginDocID aggiornati (Vendita): $($result.RowsAffected)" "Green"
}
else {
    Write-ColorOutput "ERRORE: $($result.Error)" "Red"
}

# ============================================
# FASE 3: Aggiornamento DerivedDocID per documenti di vendita
# ============================================
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 3: Aggiornamento DerivedDocID (Documenti Vendita)" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$updateDerivedSaleDoc = @"
UPDATE cr
SET cr.DerivedDocID = m.NewSaleDocId
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
INNER JOIN $Global:DestinationDB.dbo.TAG_SaleDocMapping m
    ON m.OldSaleDocId = cr.DerivedDocID
WHERE cr.DerivedDocType IN ($docTypeList)
    AND cr.DerivedDocID <> m.NewSaleDocId;
"@

$result = Execute-SqlQuery -Query $updateDerivedSaleDoc -Database $Global:DestinationDB -Timeout 600
if ($result.Success) {
    Write-ColorOutput "DerivedDocID aggiornati (Vendita): $($result.RowsAffected)" "Green"
}
else {
    Write-ColorOutput "ERRORE: $($result.Error)" "Red"
}

# ============================================
# FASE 4: Creazione mappatura PurchaseDoc
# ============================================
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 4: Creazione mappatura PurchaseDoc" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$createPurchaseMappingTable = @"
IF NOT EXISTS (SELECT * FROM $Global:DestinationDB.sys.objects WHERE object_id = OBJECT_ID(N'$Global:DestinationDB.dbo.TAG_PurchaseDocMapping') AND type in (N'U'))
BEGIN
    CREATE TABLE $Global:DestinationDB.dbo.TAG_PurchaseDocMapping (
        SourceDB NVARCHAR(50),
        OldPurchaseDocId INT,
        NewPurchaseDocId INT,
        DocumentType INT,
        DocNo NVARCHAR(50),
        DocumentDate DATETIME,
        Supplier NVARCHAR(50),
        PRIMARY KEY (SourceDB, OldPurchaseDocId)
    )
END
ELSE
BEGIN
    TRUNCATE TABLE $Global:DestinationDB.dbo.TAG_PurchaseDocMapping
END
"@

$result = Execute-SqlQuery -Query $createPurchaseMappingTable -Database $Global:DestinationDB
if ($result.Success) {
    Write-ColorOutput "Tabella TAG_PurchaseDocMapping creata/svuotata" "Green"
}
else {
    Write-ColorOutput "ERRORE creazione tabella: $($result.Error)" "Red"
}

# Popola mappatura per documenti acquisto
foreach ($sourceDB in $Global:CloneDatabases) {
    Write-ColorOutput "Popolamento mappatura acquisti da: $sourceDB" "Yellow"

    $insertPurchaseMapping = @"
INSERT INTO $Global:DestinationDB.dbo.TAG_PurchaseDocMapping
    (SourceDB, OldPurchaseDocId, NewPurchaseDocId, DocumentType, DocNo, DocumentDate, Supplier)
SELECT DISTINCT
    '$sourceDB' as SourceDB,
    src.PurchaseDocId as OldPurchaseDocId,
    dest.PurchaseDocId as NewPurchaseDocId,
    src.DocumentType,
    src.DocNo,
    src.DocumentDate,
    src.Supplier
FROM $sourceDB.dbo.MA_PurchaseDoc src
INNER JOIN $Global:DestinationDB.dbo.MA_PurchaseDoc dest
    ON dest.DocNo = src.DocNo
    AND dest.DocumentDate = src.DocumentDate
    AND dest.Supplier = src.Supplier
    AND dest.DocumentType = src.DocumentType
WHERE src.PurchaseDocId <> dest.PurchaseDocId;
"@

    $result = Execute-SqlQuery -Query $insertPurchaseMapping -Database $Global:DestinationDB -Timeout 600
    if ($result.Success) {
        Write-ColorOutput "  Mappature acquisti inserite: $($result.RowsAffected)" "Green"
    }
    else {
        Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
    }
}

# ============================================
# FASE 5: Aggiornamento riferimenti acquisti
# ============================================
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 5: Aggiornamento riferimenti Acquisti" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$purchaseDocTypes = @(
    27066402,  # Fattura di Acquisto
    27066403,  # Fattura di Acquisto a Correzione
    27066404,  # Nota di Credito ricevuta
    27066405,  # Nota di Debito Acquisto
    27066406   # Fattura di Acquisto di Acconto
)

$purchaseDocTypeList = $purchaseDocTypes -join ","

# Aggiorna OriginDocID acquisti
$updateOriginPurchase = @"
UPDATE cr
SET cr.OriginDocID = m.NewPurchaseDocId
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
INNER JOIN $Global:DestinationDB.dbo.TAG_PurchaseDocMapping m
    ON m.OldPurchaseDocId = cr.OriginDocID
WHERE cr.OriginDocType IN ($purchaseDocTypeList)
    AND cr.OriginDocID <> m.NewPurchaseDocId;
"@

$result = Execute-SqlQuery -Query $updateOriginPurchase -Database $Global:DestinationDB -Timeout 600
if ($result.Success) {
    Write-ColorOutput "OriginDocID aggiornati (Acquisti): $($result.RowsAffected)" "Green"
}
else {
    Write-ColorOutput "ERRORE: $($result.Error)" "Red"
}

# Aggiorna DerivedDocID acquisti
$updateDerivedPurchase = @"
UPDATE cr
SET cr.DerivedDocID = m.NewPurchaseDocId
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
INNER JOIN $Global:DestinationDB.dbo.TAG_PurchaseDocMapping m
    ON m.OldPurchaseDocId = cr.DerivedDocID
WHERE cr.DerivedDocType IN ($purchaseDocTypeList)
    AND cr.DerivedDocID <> m.NewPurchaseDocId;
"@

$result = Execute-SqlQuery -Query $updateDerivedPurchase -Database $Global:DestinationDB -Timeout 600
if ($result.Success) {
    Write-ColorOutput "DerivedDocID aggiornati (Acquisti): $($result.RowsAffected)" "Green"
}
else {
    Write-ColorOutput "ERRORE: $($result.Error)" "Red"
}

# ============================================
# FASE 6: Pulizia riferimenti orfani
# ============================================
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "FASE 6: Identificazione riferimenti orfani" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Trova cross-references che puntano a documenti inesistenti
$queryOrphans = @"
SELECT
    'OriginDoc' as RefType,
    cr.OriginDocType,
    COUNT(*) as OrphanCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $Global:DestinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.OriginDocID
LEFT JOIN $Global:DestinationDB.dbo.MA_PurchaseDoc pd ON pd.PurchaseDocId = cr.OriginDocID
WHERE sd.SaleDocId IS NULL AND pd.PurchaseDocId IS NULL
    AND cr.OriginDocType IN ($docTypeList, $purchaseDocTypeList)
GROUP BY cr.OriginDocType

UNION ALL

SELECT
    'DerivedDoc' as RefType,
    cr.DerivedDocType,
    COUNT(*) as OrphanCount
FROM $Global:DestinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $Global:DestinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.DerivedDocID
LEFT JOIN $Global:DestinationDB.dbo.MA_PurchaseDoc pd ON pd.PurchaseDocId = cr.DerivedDocID
WHERE sd.SaleDocId IS NULL AND pd.PurchaseDocId IS NULL
    AND cr.DerivedDocType IN ($docTypeList, $purchaseDocTypeList)
GROUP BY cr.DerivedDocType
"@

$orphans = Execute-SqlReader -Query $queryOrphans -Database $Global:DestinationDB
if ($orphans -and $orphans.Rows.Count -gt 0) {
    Write-ColorOutput "Riferimenti orfani trovati:" "Yellow"
    foreach ($row in $orphans.Rows) {
        Write-ColorOutput "  $($row.RefType) DocType $($row.OriginDocType): $($row.OrphanCount) record" "Yellow"
    }
    Write-ColorOutput "NOTA: Questi riferimenti potrebbero essere da verificare manualmente" "Yellow"
}
else {
    Write-ColorOutput "Nessun riferimento orfano rilevato" "Green"
}

# ============================================
# RIEPILOGO FINALE
# ============================================
Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  RIEPILOGO AGGIORNAMENTO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$endTime = Get-Date
$duration = $endTime - $startTime

Write-ColorOutput "Ora inizio:  $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-ColorOutput "Ora fine:    $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-ColorOutput "Durata:      $($duration.ToString('hh\:mm\:ss'))" "Gray"
Write-Host ""

# Statistiche finali
$finalStats = Execute-SqlReader -Query @"
SELECT
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT OriginDocType) as OriginTypes,
    COUNT(DISTINCT DerivedDocType) as DerivedTypes
FROM $Global:DestinationDB.dbo.MA_CrossReferences
"@ -Database $Global:DestinationDB

if ($finalStats -and $finalStats.Rows.Count -gt 0) {
    $row = $finalStats.Rows[0]
    Write-ColorOutput "Statistiche finali MA_CrossReferences:" "White"
    Write-ColorOutput "  Record totali: $($row.TotalRecords)" "Gray"
    Write-ColorOutput "  OriginDocType distinti: $($row.OriginTypes)" "Gray"
    Write-ColorOutput "  DerivedDocType distinti: $($row.DerivedTypes)" "Gray"
}

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  AGGIORNAMENTO COMPLETATO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""
Write-ColorOutput "PROSSIMO PASSO: Eseguire 05_VerificaIntegritaCrossRef.ps1" "Yellow"
