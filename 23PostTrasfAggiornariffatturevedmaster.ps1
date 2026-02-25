# ============================================
# SCRIPT 23: Aggiornamento Riferimenti Incrociati Post-Trasferimento
# ============================================
# Versione: 4.1 - Approccio basato sui clone + fallback ID diretto
#
# LOGICA:
#   Le fatture su VEDMaster sono state importate da procedura esterna,
#   quindi Mago4 non ha trasferito i relativi cross-references.
#   I DB clone hanno i cross-references corretti post-rinumerazione.
#   Questo script:
#   1. Crea mappatura SaleDoc clone -> VEDMaster (TAG_SaleDocMapping)
#   2. Corregge cross-ref ESISTENTI su VEDMaster che hanno ancora ID clone
#   3. Importa cross-ref MANCANTI dai DB clone, mappando gli ID a VEDMaster
#      - Prima via TAG_SaleDocMapping (ID rinumerati sui clone)
#      - Fallback: ID originale vedcontab gia' valido su VEDMaster
# ============================================

# Parametri di connessione
$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"
$destinationDB = "VEDMaster"
$sourceDatabases = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Funzione per eseguire query SQL (non-query)
function Execute-SqlQuery {
    param (
        [string]$query,
        [string]$connectionString,
        [string]$messageSuccess,
        [string]$messageError,
        [int]$timeout = 600
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()

        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = $query
        $command.CommandTimeout = $timeout
        $rowsAffected = $command.ExecuteNonQuery()

        $connection.Close()
        if ($messageSuccess) {
            Write-Host "$messageSuccess (righe: $rowsAffected)" -ForegroundColor Green
        }
        return $rowsAffected
    }
    catch {
        if ($messageError) {
            Write-Host "$messageError`: $_" -ForegroundColor Red
        }
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        return -1
    }
}

# Funzione per eseguire query scalare
function Execute-SqlScalar {
    param (
        [string]$query,
        [string]$connectionString
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()

        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = $query
        $command.CommandTimeout = 300
        $result = $command.ExecuteScalar()

        $connection.Close()
        return $result
    }
    catch {
        Write-Host "Errore query scalare: $_" -ForegroundColor Red
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        return $null
    }
}

# Funzione per eseguire query con DataReader
function Execute-SqlReader {
    param (
        [string]$query,
        [string]$connectionString
    )

    $results = @()
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()

        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = $query
        $command.CommandTimeout = 300

        $reader = $command.ExecuteReader()
        while ($reader.Read()) {
            $row = @{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $row[$reader.GetName($i)] = $reader.GetValue($i)
            }
            $results += [PSCustomObject]$row
        }
        $reader.Close()
        $connection.Close()
    }
    catch {
        Write-Host "Errore reader: $_" -ForegroundColor Red
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
    }
    return $results
}

# Stringa di connessione
$connectionString = "Server=$serverName;Database=$destinationDB;User ID=$userName;Password=$password;"

# ReferenceCode per documenti di vendita (MA_SaleDoc) usati in MA_CrossReferences
$saleDocRefCodes = @(
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
$saleDocRefCodesSQL = $saleDocRefCodes -join ", "

# ReferenceCode ordine cliente (usa SaleOrdId, NON SaleDocId - ID preservato nel trasferimento)
$saleOrdRefCode = 27066372

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  AGGIORNAMENTO RIFERIMENTI POST-TRASFERIMENTO" -ForegroundColor Cyan
Write-Host "  Versione 4.1 - Approccio clone + fallback ID diretto" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
Write-Host "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

# ============================================
# FASE 0: Diagnostica rapida - stato attuale
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 0: Stato attuale cross-references" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$totalCR = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences" -connectionString $connectionString
Write-Host "  Totale MA_CrossReferences su VEDMaster: $totalCR" -ForegroundColor White

# Cross-ref con DerivedDocID orfano (SaleDoc non trovato su VEDMaster)
$orphanDerived = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
  AND NOT EXISTS (SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd WHERE sd.SaleDocId = cr.DerivedDocID)
"@ -connectionString $connectionString
Write-Host "  DerivedDocID orfani (SaleDoc): $orphanDerived" -ForegroundColor $(if ($orphanDerived -gt 0) { "Yellow" } else { "Green" })

# Cross-ref con OriginDocID orfano (SaleDoc non trovato su VEDMaster)
$orphanOrigin = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
  AND NOT EXISTS (SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd WHERE sd.SaleDocId = cr.OriginDocID)
"@ -connectionString $connectionString
Write-Host "  OriginDocID orfani (SaleDoc): $orphanOrigin" -ForegroundColor $(if ($orphanOrigin -gt 0) { "Yellow" } else { "Green" })

# Catene complete: quante fatture hanno cross-ref da ordini?
$fattConOrdini = Execute-SqlScalar -query @"
SELECT COUNT(DISTINCT cr.DerivedDocID) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType = $saleOrdRefCode AND cr.DerivedDocType IN ($saleDocRefCodesSQL)
"@ -connectionString $connectionString
Write-Host "  Fatture/DDT con riferimento a ordini clienti: $fattConOrdini" -ForegroundColor White

$totalFatture = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.MA_SaleDoc WHERE DocumentType = 3407874" -connectionString $connectionString
Write-Host "  Totale fatture (tipo 3407874) su VEDMaster: $totalFatture" -ForegroundColor White

# Cross-ref per combinazione DocType (top 10)
$crStats = Execute-SqlReader -query @"
SELECT TOP 10 cr.OriginDocType, cr.DerivedDocType, COUNT(*) as Cnt
FROM $destinationDB.dbo.MA_CrossReferences cr
GROUP BY cr.OriginDocType, cr.DerivedDocType
ORDER BY Cnt DESC
"@ -connectionString $connectionString

if ($crStats) {
    Write-Host "  Top combinazioni DocType:" -ForegroundColor Gray
    foreach ($row in $crStats) {
        Write-Host "    $($row.OriginDocType) -> $($row.DerivedDocType) : $($row.Cnt)" -ForegroundColor Gray
    }
}
Write-Host ""

# ============================================
# FASE 1: Creazione mappatura SaleDoc clone -> VEDMaster
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 1: Mappatura SaleDoc clone -> VEDMaster" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$createMappingSQL = @"
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TAG_SaleDocMapping')
    DROP TABLE $destinationDB.dbo.TAG_SaleDocMapping;

CREATE TABLE $destinationDB.dbo.TAG_SaleDocMapping (
    SourceDB NVARCHAR(50),
    OldSaleDocId INT,
    NewSaleDocId INT,
    DocumentType INT,
    DocNo NVARCHAR(50),
    DocumentDate DATETIME,
    CustSupp NVARCHAR(50)
);

CREATE INDEX IX_TAG_SaleDocMapping_Old ON $destinationDB.dbo.TAG_SaleDocMapping (OldSaleDocId, SourceDB);
CREATE INDEX IX_TAG_SaleDocMapping_New ON $destinationDB.dbo.TAG_SaleDocMapping (NewSaleDocId);
"@

Execute-SqlQuery -query $createMappingSQL -connectionString $connectionString `
    -messageSuccess "  TAG_SaleDocMapping creata con indici" `
    -messageError "  Errore creazione TAG_SaleDocMapping"

foreach ($sourceDB in $sourceDatabases) {
    Write-Host "  Popolamento da: $sourceDB" -ForegroundColor Yellow

    # Match per chiave business: DocNo + DocumentDate + CustSupp + DocumentType
    $insertMappingSQL = @"
    INSERT INTO $destinationDB.dbo.TAG_SaleDocMapping
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
    INNER JOIN $destinationDB.dbo.MA_SaleDoc dest
        ON dest.DocNo = src.DocNo
        AND dest.DocumentDate = src.DocumentDate
        AND dest.CustSupp = src.CustSupp
        AND dest.DocumentType = src.DocumentType
"@

    Execute-SqlQuery -query $insertMappingSQL -connectionString $connectionString `
        -messageSuccess "    Mappature inserite da $sourceDB" `
        -messageError "    Errore inserimento da $sourceDB"
}

$totalMappings = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.TAG_SaleDocMapping" -connectionString $connectionString
$diffIdMappings = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.TAG_SaleDocMapping WHERE OldSaleDocId <> NewSaleDocId" -connectionString $connectionString
$sameIdMappings = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.TAG_SaleDocMapping WHERE OldSaleDocId = NewSaleDocId" -connectionString $connectionString
Write-Host "  Totale mappature: $totalMappings (ID diverso: $diffIdMappings, ID uguale: $sameIdMappings)" -ForegroundColor White

# Check ambiguita' (un OldSaleDocId -> piu' NewSaleDocId)
$ambiguous = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM (
    SELECT OldSaleDocId, SourceDB
    FROM $destinationDB.dbo.TAG_SaleDocMapping
    GROUP BY OldSaleDocId, SourceDB
    HAVING COUNT(DISTINCT NewSaleDocId) > 1
) t
"@ -connectionString $connectionString
if ($ambiguous -gt 0) {
    Write-Host "  ATTENZIONE: $ambiguous mappature ambigue (1 clone ID -> N VEDMaster ID)!" -ForegroundColor Red
}

# Statistiche per DB
$statsPerDB = Execute-SqlReader -query @"
SELECT SourceDB, COUNT(*) as Cnt
FROM $destinationDB.dbo.TAG_SaleDocMapping
GROUP BY SourceDB ORDER BY SourceDB
"@ -connectionString $connectionString

if ($statsPerDB) {
    foreach ($row in $statsPerDB) {
        Write-Host "    $($row.SourceDB): $($row.Cnt) mappature" -ForegroundColor Gray
    }
}
Write-Host ""

# ============================================
# FASE 2: Fix DerivedDocID su cross-ref ESISTENTI su VEDMaster
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 2: Fix DerivedDocID cross-ref esistenti" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$derivedToFix = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.DerivedDocID
WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL) AND cr.DerivedDocID <> m.NewSaleDocId
"@ -connectionString $connectionString
Write-Host "  DerivedDocID da correggere: $derivedToFix" -ForegroundColor $(if ($derivedToFix -gt 0) { "Yellow" } else { "Green" })

if ($derivedToFix -gt 0) {
    # Step 2a: Salva righe con ID corretto in tabella permanente
    Execute-SqlQuery -query @"
    IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCRDerivedFix') IS NOT NULL
        DROP TABLE $destinationDB.dbo.TAG_TmpCRDerivedFix;

    SELECT
        cr.OriginDocType, cr.OriginDocID, cr.OriginDocSubID, cr.OriginDocLine,
        cr.DerivedDocType, m.NewSaleDocId as DerivedDocID, cr.DerivedDocSubID, cr.DerivedDocLine,
        cr.[Manual], cr.TBCreated, cr.TBModified, cr.TBCreatedID, cr.TBModifiedID,
        ROW_NUMBER() OVER (
            PARTITION BY cr.OriginDocType, cr.OriginDocID, cr.OriginDocSubID, cr.OriginDocLine,
                         cr.DerivedDocType, m.NewSaleDocId, cr.DerivedDocSubID, cr.DerivedDocLine
            ORDER BY cr.DerivedDocID
        ) as rn
    INTO $destinationDB.dbo.TAG_TmpCRDerivedFix
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.DerivedDocID
    WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
        AND cr.DerivedDocID <> m.NewSaleDocId
"@ -connectionString $connectionString `
        -messageSuccess "  Righe salvate in TAG_TmpCRDerivedFix" `
        -messageError "  ERRORE salvataggio"

    # Step 2b: DELETE righe con vecchio DerivedDocID
    Execute-SqlQuery -query @"
    DELETE cr
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.DerivedDocID
    WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
        AND cr.DerivedDocID <> m.NewSaleDocId
"@ -connectionString $connectionString `
        -messageSuccess "  Righe con vecchio ID eliminate" `
        -messageError "  ERRORE eliminazione"

    # Step 2c: INSERT righe con nuovo DerivedDocID (dedup + no conflitto PK)
    Execute-SqlQuery -query @"
    INSERT INTO $destinationDB.dbo.MA_CrossReferences
        (OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
         DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
         [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID)
    SELECT
        t.OriginDocType, t.OriginDocID, t.OriginDocSubID, t.OriginDocLine,
        t.DerivedDocType, t.DerivedDocID, t.DerivedDocSubID, t.DerivedDocLine,
        t.[Manual], t.TBCreated, t.TBModified, t.TBCreatedID, t.TBModifiedID
    FROM $destinationDB.dbo.TAG_TmpCRDerivedFix t
    WHERE t.rn = 1
        AND NOT EXISTS (
            SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences x
            WHERE x.OriginDocType = t.OriginDocType AND x.OriginDocID = t.OriginDocID
              AND x.OriginDocSubID = t.OriginDocSubID AND x.OriginDocLine = t.OriginDocLine
              AND x.DerivedDocType = t.DerivedDocType AND x.DerivedDocID = t.DerivedDocID
              AND x.DerivedDocSubID = t.DerivedDocSubID AND x.DerivedDocLine = t.DerivedDocLine
        )
"@ -connectionString $connectionString `
        -messageSuccess "  Righe inserite con DerivedDocID corretto" `
        -messageError "  ERRORE inserimento"

    # Verifica residui
    $residual = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.DerivedDocID
    WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL) AND cr.DerivedDocID <> m.NewSaleDocId
"@ -connectionString $connectionString
    Write-Host "  Residui dopo fix: $residual" -ForegroundColor $(if ($residual -eq 0) { "Green" } else { "Red" })

    Execute-SqlQuery -query "IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCRDerivedFix') IS NOT NULL DROP TABLE $destinationDB.dbo.TAG_TmpCRDerivedFix" -connectionString $connectionString
}
else {
    Write-Host "  Nessuna correzione necessaria" -ForegroundColor Gray
}
Write-Host ""

# ============================================
# FASE 3: Fix OriginDocID su cross-ref ESISTENTI su VEDMaster
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 3: Fix OriginDocID cross-ref esistenti" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$originToFix = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.OriginDocID
WHERE cr.OriginDocType IN ($saleDocRefCodesSQL) AND cr.OriginDocID <> m.NewSaleDocId
"@ -connectionString $connectionString
Write-Host "  OriginDocID da correggere: $originToFix" -ForegroundColor $(if ($originToFix -gt 0) { "Yellow" } else { "Green" })

if ($originToFix -gt 0) {
    # Step 3a: Salva righe con ID corretto
    Execute-SqlQuery -query @"
    IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCROriginFix') IS NOT NULL
        DROP TABLE $destinationDB.dbo.TAG_TmpCROriginFix;

    SELECT
        cr.OriginDocType, m.NewSaleDocId as OriginDocID, cr.OriginDocSubID, cr.OriginDocLine,
        cr.DerivedDocType, cr.DerivedDocID, cr.DerivedDocSubID, cr.DerivedDocLine,
        cr.[Manual], cr.TBCreated, cr.TBModified, cr.TBCreatedID, cr.TBModifiedID,
        ROW_NUMBER() OVER (
            PARTITION BY cr.OriginDocType, m.NewSaleDocId, cr.OriginDocSubID, cr.OriginDocLine,
                         cr.DerivedDocType, cr.DerivedDocID, cr.DerivedDocSubID, cr.DerivedDocLine
            ORDER BY cr.OriginDocID
        ) as rn
    INTO $destinationDB.dbo.TAG_TmpCROriginFix
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.OriginDocID
    WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
        AND cr.OriginDocID <> m.NewSaleDocId
"@ -connectionString $connectionString `
        -messageSuccess "  Righe salvate in TAG_TmpCROriginFix" `
        -messageError "  ERRORE salvataggio"

    # Step 3b: DELETE righe con vecchio OriginDocID
    Execute-SqlQuery -query @"
    DELETE cr
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.OriginDocID
    WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
        AND cr.OriginDocID <> m.NewSaleDocId
"@ -connectionString $connectionString `
        -messageSuccess "  Righe con vecchio ID eliminate" `
        -messageError "  ERRORE eliminazione"

    # Step 3c: INSERT righe con nuovo OriginDocID
    Execute-SqlQuery -query @"
    INSERT INTO $destinationDB.dbo.MA_CrossReferences
        (OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
         DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
         [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID)
    SELECT
        t.OriginDocType, t.OriginDocID, t.OriginDocSubID, t.OriginDocLine,
        t.DerivedDocType, t.DerivedDocID, t.DerivedDocSubID, t.DerivedDocLine,
        t.[Manual], t.TBCreated, t.TBModified, t.TBCreatedID, t.TBModifiedID
    FROM $destinationDB.dbo.TAG_TmpCROriginFix t
    WHERE t.rn = 1
        AND NOT EXISTS (
            SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences x
            WHERE x.OriginDocType = t.OriginDocType AND x.OriginDocID = t.OriginDocID
              AND x.OriginDocSubID = t.OriginDocSubID AND x.OriginDocLine = t.OriginDocLine
              AND x.DerivedDocType = t.DerivedDocType AND x.DerivedDocID = t.DerivedDocID
              AND x.DerivedDocSubID = t.DerivedDocSubID AND x.DerivedDocLine = t.DerivedDocLine
        )
"@ -connectionString $connectionString `
        -messageSuccess "  Righe inserite con OriginDocID corretto" `
        -messageError "  ERRORE inserimento"

    # Verifica residui
    $residual = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_SaleDocMapping m ON m.OldSaleDocId = cr.OriginDocID
    WHERE cr.OriginDocType IN ($saleDocRefCodesSQL) AND cr.OriginDocID <> m.NewSaleDocId
"@ -connectionString $connectionString
    Write-Host "  Residui dopo fix: $residual" -ForegroundColor $(if ($residual -eq 0) { "Green" } else { "Red" })

    Execute-SqlQuery -query "IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCROriginFix') IS NOT NULL DROP TABLE $destinationDB.dbo.TAG_TmpCROriginFix" -connectionString $connectionString
}
else {
    Write-Host "  Nessuna correzione necessaria" -ForegroundColor Gray
}
Write-Host ""

# ============================================
# FASE 4: Importa cross-references MANCANTI dai DB clone
# ============================================
# I clone hanno i cross-references corretti post-rinumerazione.
# Leggiamo i cross-ref che coinvolgono SaleDoc e SaleOrd,
# mappiamo i SaleDocId tramite TAG_SaleDocMapping,
# e inseriamo su VEDMaster quelli che mancano.
# SaleOrdId (27066372) e' preservato nel trasferimento, non serve mappatura.
#
# FALLBACK: Alcuni cross-ref nei clone riferiscono SaleDocId originali vedcontab
# (non rinumerati), che NON sono in TAG_SaleDocMapping ma ESISTONO gia'
# su VEDMaster. Per questi, verifichiamo direttamente su VEDMaster.MA_SaleDoc
# e usiamo l'ID cosi' com'e' (gia' valido su VEDMaster).
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 4: Importazione cross-references dai clone" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Crea tabella staging per raccogliere cross-ref mappati da tutti i clone
Execute-SqlQuery -query @"
IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCloneCR') IS NOT NULL
    DROP TABLE $destinationDB.dbo.TAG_TmpCloneCR;

CREATE TABLE $destinationDB.dbo.TAG_TmpCloneCR (
    OriginDocType INT,
    OriginDocID INT,
    OriginDocSubID INT,
    OriginDocLine INT,
    DerivedDocType INT,
    DerivedDocID INT,
    DerivedDocSubID INT,
    DerivedDocLine INT,
    [Manual] INT,
    TBCreated DATETIME,
    TBModified DATETIME,
    TBCreatedID INT,
    TBModifiedID INT,
    SourceDB NVARCHAR(50)
);
"@ -connectionString $connectionString `
    -messageSuccess "  Tabella staging TAG_TmpCloneCR creata" `
    -messageError "  Errore creazione staging"

foreach ($sourceDB in $sourceDatabases) {
    Write-Host ""
    Write-Host "  --- $sourceDB ---" -ForegroundColor Yellow

    # Conta cross-ref coinvolgenti SaleDoc/SaleOrd sul clone
    $cloneCrTotal = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM $sourceDB.dbo.MA_CrossReferences cr
    WHERE (cr.OriginDocType IN ($saleDocRefCodesSQL) OR cr.OriginDocType = $saleOrdRefCode)
      AND (cr.DerivedDocType IN ($saleDocRefCodesSQL) OR cr.DerivedDocType = $saleOrdRefCode)
"@ -connectionString $connectionString
    Write-Host "    Cross-ref SaleDoc/SaleOrd sul clone: $cloneCrTotal" -ForegroundColor Gray

    # Conta quanti sono mappabili (via TAG_SaleDocMapping O via ID diretto su VEDMaster)
    $cloneMappable = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM $sourceDB.dbo.MA_CrossReferences cr
    LEFT JOIN $destinationDB.dbo.TAG_SaleDocMapping mo
        ON mo.OldSaleDocId = cr.OriginDocID AND mo.SourceDB = '$sourceDB'
    LEFT JOIN $destinationDB.dbo.TAG_SaleDocMapping md
        ON md.OldSaleDocId = cr.DerivedDocID AND md.SourceDB = '$sourceDB'
    -- Fallback: ID originale vedcontab gia' presente su VEDMaster
    LEFT JOIN $destinationDB.dbo.MA_SaleDoc sdo_fb
        ON sdo_fb.SaleDocId = cr.OriginDocID AND cr.OriginDocType IN ($saleDocRefCodesSQL)
    LEFT JOIN $destinationDB.dbo.MA_SaleDoc sdd_fb
        ON sdd_fb.SaleDocId = cr.DerivedDocID AND cr.DerivedDocType IN ($saleDocRefCodesSQL)
    WHERE (cr.OriginDocType IN ($saleDocRefCodesSQL) OR cr.OriginDocType = $saleOrdRefCode)
      AND (cr.DerivedDocType IN ($saleDocRefCodesSQL) OR cr.DerivedDocType = $saleOrdRefCode)
      AND (cr.OriginDocType = $saleOrdRefCode OR mo.NewSaleDocId IS NOT NULL OR sdo_fb.SaleDocId IS NOT NULL)
      AND (cr.DerivedDocType = $saleOrdRefCode OR md.NewSaleDocId IS NOT NULL OR sdd_fb.SaleDocId IS NOT NULL)
"@ -connectionString $connectionString
    Write-Host "    Di cui mappabili su VEDMaster: $cloneMappable" -ForegroundColor Gray

    # Diagnostica: quanti risolti via mapping vs ID diretto
    $viaMapping = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM $sourceDB.dbo.MA_CrossReferences cr
    LEFT JOIN $destinationDB.dbo.TAG_SaleDocMapping mo
        ON mo.OldSaleDocId = cr.OriginDocID AND mo.SourceDB = '$sourceDB'
    LEFT JOIN $destinationDB.dbo.TAG_SaleDocMapping md
        ON md.OldSaleDocId = cr.DerivedDocID AND md.SourceDB = '$sourceDB'
    WHERE (cr.OriginDocType IN ($saleDocRefCodesSQL) OR cr.OriginDocType = $saleOrdRefCode)
      AND (cr.DerivedDocType IN ($saleDocRefCodesSQL) OR cr.DerivedDocType = $saleOrdRefCode)
      AND (cr.OriginDocType = $saleOrdRefCode OR mo.NewSaleDocId IS NOT NULL)
      AND (cr.DerivedDocType = $saleOrdRefCode OR md.NewSaleDocId IS NOT NULL)
"@ -connectionString $connectionString
    $viaFallback = $cloneMappable - $viaMapping
    Write-Host "      Via TAG_SaleDocMapping: $viaMapping | Via ID diretto VEDMaster: $viaFallback" -ForegroundColor Gray

    if ($cloneMappable -gt 0) {
        # Inserisci cross-ref mappati nella staging table
        # - SaleDoc types: OriginDocID/DerivedDocID mappato tramite TAG_SaleDocMapping
        #   FALLBACK: se non in mapping, controlla ID diretto su VEDMaster.MA_SaleDoc
        # - SaleOrd (27066372): ID preservato, usato as-is
        $insertStaging = @"
        INSERT INTO $destinationDB.dbo.TAG_TmpCloneCR
            (OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
             DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
             [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID, SourceDB)
        SELECT
            cr.OriginDocType,
            CASE WHEN cr.OriginDocType IN ($saleDocRefCodesSQL)
                 THEN COALESCE(mo.NewSaleDocId, sdo_fb.SaleDocId)
                 ELSE cr.OriginDocID
            END,
            cr.OriginDocSubID, cr.OriginDocLine,
            cr.DerivedDocType,
            CASE WHEN cr.DerivedDocType IN ($saleDocRefCodesSQL)
                 THEN COALESCE(md.NewSaleDocId, sdd_fb.SaleDocId)
                 ELSE cr.DerivedDocID
            END,
            cr.DerivedDocSubID, cr.DerivedDocLine,
            cr.[Manual], cr.TBCreated, cr.TBModified, cr.TBCreatedID, cr.TBModifiedID,
            '$sourceDB'
        FROM $sourceDB.dbo.MA_CrossReferences cr
        LEFT JOIN $destinationDB.dbo.TAG_SaleDocMapping mo
            ON mo.OldSaleDocId = cr.OriginDocID AND mo.SourceDB = '$sourceDB'
        LEFT JOIN $destinationDB.dbo.TAG_SaleDocMapping md
            ON md.OldSaleDocId = cr.DerivedDocID AND md.SourceDB = '$sourceDB'
        -- Fallback: ID originale vedcontab gia' presente su VEDMaster
        LEFT JOIN $destinationDB.dbo.MA_SaleDoc sdo_fb
            ON sdo_fb.SaleDocId = cr.OriginDocID AND cr.OriginDocType IN ($saleDocRefCodesSQL)
        LEFT JOIN $destinationDB.dbo.MA_SaleDoc sdd_fb
            ON sdd_fb.SaleDocId = cr.DerivedDocID AND cr.DerivedDocType IN ($saleDocRefCodesSQL)
        WHERE
            -- Entrambi i lati devono essere SaleDoc o SaleOrd
            (cr.OriginDocType IN ($saleDocRefCodesSQL) OR cr.OriginDocType = $saleOrdRefCode)
            AND (cr.DerivedDocType IN ($saleDocRefCodesSQL) OR cr.DerivedDocType = $saleOrdRefCode)
            -- Per SaleDoc: mapping O ID diretto su VEDMaster (documento deve esistere)
            AND (cr.OriginDocType = $saleOrdRefCode OR mo.NewSaleDocId IS NOT NULL OR sdo_fb.SaleDocId IS NOT NULL)
            AND (cr.DerivedDocType = $saleOrdRefCode OR md.NewSaleDocId IS NOT NULL OR sdd_fb.SaleDocId IS NOT NULL)
"@

        Execute-SqlQuery -query $insertStaging -connectionString $connectionString `
            -messageSuccess "    Cross-ref mappati inseriti in staging" `
            -messageError "    ERRORE inserimento staging"
    }
}

Write-Host ""
$totalStaging = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.TAG_TmpCloneCR" -connectionString $connectionString
Write-Host "  Totale cross-ref mappati nella staging: $totalStaging" -ForegroundColor White

# Statistiche staging per DB e combinazione tipo
$stagingStats = Execute-SqlReader -query @"
SELECT SourceDB, OriginDocType, DerivedDocType, COUNT(*) as Cnt
FROM $destinationDB.dbo.TAG_TmpCloneCR
GROUP BY SourceDB, OriginDocType, DerivedDocType
ORDER BY SourceDB, Cnt DESC
"@ -connectionString $connectionString

if ($stagingStats) {
    Write-Host "  Dettaglio per DB e tipo:" -ForegroundColor Gray
    foreach ($row in $stagingStats) {
        Write-Host "    $($row.SourceDB): $($row.OriginDocType)->$($row.DerivedDocType) = $($row.Cnt)" -ForegroundColor Gray
    }
}

# Quanti sono gia' presenti su VEDMaster?
$alreadyExist = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.TAG_TmpCloneCR t
WHERE EXISTS (
    SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences x
    WHERE x.OriginDocType = t.OriginDocType AND x.OriginDocID = t.OriginDocID
      AND x.OriginDocSubID = t.OriginDocSubID AND x.OriginDocLine = t.OriginDocLine
      AND x.DerivedDocType = t.DerivedDocType AND x.DerivedDocID = t.DerivedDocID
      AND x.DerivedDocSubID = t.DerivedDocSubID AND x.DerivedDocLine = t.DerivedDocLine
)
"@ -connectionString $connectionString
Write-Host "  Di cui gia' presenti su VEDMaster: $alreadyExist" -ForegroundColor Gray

$toInsert = $totalStaging - $alreadyExist
Write-Host "  Da inserire (nuovi): ~$toInsert" -ForegroundColor Yellow

if ($totalStaging -gt 0) {
    Write-Host ""
    Write-Host "  Inserimento cross-ref mancanti in VEDMaster..." -ForegroundColor Yellow

    # INSERT con dedup (ROW_NUMBER per gestire duplicati tra clone) + NOT EXISTS
    Execute-SqlQuery -query @"
    ;WITH Dedup AS (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
                             DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine
                ORDER BY SourceDB
            ) as rn
        FROM $destinationDB.dbo.TAG_TmpCloneCR
    )
    INSERT INTO $destinationDB.dbo.MA_CrossReferences
        (OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
         DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
         [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID)
    SELECT
        d.OriginDocType, d.OriginDocID, d.OriginDocSubID, d.OriginDocLine,
        d.DerivedDocType, d.DerivedDocID, d.DerivedDocSubID, d.DerivedDocLine,
        d.[Manual], d.TBCreated, d.TBModified, d.TBCreatedID, d.TBModifiedID
    FROM Dedup d
    WHERE d.rn = 1
        AND NOT EXISTS (
            SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences x
            WHERE x.OriginDocType = d.OriginDocType AND x.OriginDocID = d.OriginDocID
              AND x.OriginDocSubID = d.OriginDocSubID AND x.OriginDocLine = d.OriginDocLine
              AND x.DerivedDocType = d.DerivedDocType AND x.DerivedDocID = d.DerivedDocID
              AND x.DerivedDocSubID = d.DerivedDocSubID AND x.DerivedDocLine = d.DerivedDocLine
        )
"@ -connectionString $connectionString `
        -messageSuccess "  Cross-ref inseriti in VEDMaster" `
        -messageError "  ERRORE inserimento in VEDMaster"
}
else {
    Write-Host "  Nessun cross-ref da importare dai clone" -ForegroundColor Gray
}

# Cleanup staging
Execute-SqlQuery -query "IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCloneCR') IS NOT NULL DROP TABLE $destinationDB.dbo.TAG_TmpCloneCR" -connectionString $connectionString
Write-Host ""

# ============================================
# FASE 5: Verifica finale
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 5: Verifica finale" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$totalCRAfter = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences" -connectionString $connectionString
Write-Host "  Totale MA_CrossReferences DOPO: $totalCRAfter (prima: $totalCR, differenza: $($totalCRAfter - $totalCR))" -ForegroundColor White

# Orfani residui
$orphanDerivedAfter = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
  AND NOT EXISTS (SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd WHERE sd.SaleDocId = cr.DerivedDocID)
"@ -connectionString $connectionString
Write-Host "  DerivedDocID orfani DOPO: $orphanDerivedAfter (prima: $orphanDerived)" -ForegroundColor $(if ($orphanDerivedAfter -lt $orphanDerived) { "Green" } elseif ($orphanDerivedAfter -eq $orphanDerived) { "Yellow" } else { "Red" })

$orphanOriginAfter = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
  AND NOT EXISTS (SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd WHERE sd.SaleDocId = cr.OriginDocID)
"@ -connectionString $connectionString
Write-Host "  OriginDocID orfani DOPO: $orphanOriginAfter (prima: $orphanOrigin)" -ForegroundColor $(if ($orphanOriginAfter -lt $orphanOrigin) { "Green" } elseif ($orphanOriginAfter -eq $orphanOrigin) { "Yellow" } else { "Red" })

# Catene Ordine->Fattura/DDT
$fattConOrdiniAfter = Execute-SqlScalar -query @"
SELECT COUNT(DISTINCT cr.DerivedDocID) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType = $saleOrdRefCode AND cr.DerivedDocType IN ($saleDocRefCodesSQL)
"@ -connectionString $connectionString
Write-Host "  Fatture/DDT con rif. a ordini DOPO: $fattConOrdiniAfter (prima: $fattConOrdini, +$($fattConOrdiniAfter - $fattConOrdini))" -ForegroundColor $(if ($fattConOrdiniAfter -gt $fattConOrdini) { "Green" } else { "Yellow" })

# Dettaglio catene per tipo
$chainStats = Execute-SqlReader -query @"
SELECT cr.OriginDocType, cr.DerivedDocType, COUNT(*) as Cnt,
    SUM(CASE WHEN sd.SaleDocId IS NOT NULL THEN 1 ELSE 0 END) as DerivedValido,
    SUM(CASE WHEN sd.SaleDocId IS NULL THEN 1 ELSE 0 END) as DerivedOrfano
FROM $destinationDB.dbo.MA_CrossReferences cr
LEFT JOIN $destinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.DerivedDocID
WHERE (cr.OriginDocType IN ($saleDocRefCodesSQL) OR cr.OriginDocType = $saleOrdRefCode)
  AND cr.DerivedDocType IN ($saleDocRefCodesSQL)
GROUP BY cr.OriginDocType, cr.DerivedDocType
ORDER BY Cnt DESC
"@ -connectionString $connectionString

if ($chainStats) {
    Write-Host ""
    Write-Host "  Catene cross-ref (con stato DerivedDocID):" -ForegroundColor Gray
    foreach ($row in $chainStats) {
        $color = if ($row.DerivedOrfano -eq 0) { "Green" } else { "Yellow" }
        Write-Host "    $($row.OriginDocType)->$($row.DerivedDocType): $($row.Cnt) totali ($($row.DerivedValido) validi, $($row.DerivedOrfano) orfani)" -ForegroundColor $color
    }
}

# Campione: 5 fatture con catena completa Ordine->Fattura
Write-Host ""
Write-Host "  --- CAMPIONE: Fatture con catena completa ---" -ForegroundColor Yellow
$sampleChain = Execute-SqlReader -query @"
SELECT TOP 5
    cr.OriginDocID as OrdineId,
    so.InternalOrdNo as OrdineNo,
    cr.DerivedDocID as FatturaId,
    sd.DocNo as FatturaNo,
    sd.DocumentDate as FatturaData,
    sd.CustSupp as Cliente
FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = cr.DerivedDocID
INNER JOIN $destinationDB.dbo.MA_SaleOrd so ON so.SaleOrdId = cr.OriginDocID
WHERE cr.OriginDocType = $saleOrdRefCode
  AND cr.DerivedDocType IN (27066387, 27066385)
ORDER BY sd.DocumentDate DESC
"@ -connectionString $connectionString

if ($sampleChain -and $sampleChain.Count -gt 0) {
    foreach ($row in $sampleChain) {
        Write-Host "    Ordine $($row.OrdineNo) (ID=$($row.OrdineId)) -> Fattura $($row.FatturaNo) (ID=$($row.FatturaId)) del $($row.FatturaData) cliente $($row.Cliente)" -ForegroundColor Green
    }
}
else {
    Write-Host "    Nessuna catena completa Ordine->Fattura trovata" -ForegroundColor Red
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

Write-Host "  Ora inizio:  $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Ora fine:    $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Durata:      $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host ""
Write-Host "  Mappature SaleDoc create:    $totalMappings" -ForegroundColor White
Write-Host "  Cross-ref totali PRIMA:      $totalCR" -ForegroundColor White
Write-Host "  Cross-ref totali DOPO:       $totalCRAfter (+$($totalCRAfter - $totalCR))" -ForegroundColor White
Write-Host "  DerivedDocID orfani PRIMA:   $orphanDerived" -ForegroundColor White
Write-Host "  DerivedDocID orfani DOPO:    $orphanDerivedAfter" -ForegroundColor White
Write-Host "  Catene Ordine->Fatt PRIMA:   $fattConOrdini" -ForegroundColor White
Write-Host "  Catene Ordine->Fatt DOPO:    $fattConOrdiniAfter" -ForegroundColor White
Write-Host ""
Write-Host "Operazione completata!" -ForegroundColor Green
