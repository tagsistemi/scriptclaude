# ============================================
# SCRIPT 28: Rinumerazione SaleDocId su VEDMaster
# ============================================
# Versione: 2.0
#
# SCOPO:
#   Le fatture su VEDMaster sono state importate da vedcontab con ID originali.
#   I DB clone hanno gli stessi documenti con ID rinumerati (offset).
#   I cross-references nei clone puntano agli ID rinumerati.
#
#   Questo script rinumera i SaleDocId su VEDMaster per farli coincidere
#   con quelli dei clone, cosi' i cross-references importati dai clone
#   saranno corretti BY DESIGN, senza bisogno dello script 23.
#
# QUANDO ESEGUIRE:
#   - DOPO l'importazione fatture da vedcontab su VEDMaster
#   - PRIMA dell'importazione cross-references dai clone
#
# LOGICA:
#   1. Match per business key (DocNo + DocumentDate + CustSupp + DocumentType)
#      tra VEDMaster e ogni clone
#   2. Per ogni fattura matchata: VEDMaster.SaleDocId -> clone.SaleDocId
#   3. Aggiorna MA_SaleDoc + tutte le child tables
#   4. Aggiorna cross-references GIA' presenti su VEDMaster
#   5. Fatture non matchate: restano con ID originale (nessun rischio collisione
#      perche' i clone usano offset 200000+)
# ============================================

# Parametri di connessione
$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"
$destinationDB = "VEDMaster"

# Clone databases e relativi offset (per diagnostica/log)
$sourceDatabases = @(
    @{ Name = "gpxnetclone";      Offset = 400000 },
    @{ Name = "furmanetclone";    Offset = 200000 },
    @{ Name = "vedbondifeclone";  Offset = 300000 }
)

# Tabelle da aggiornare (ordine: prima parent, poi child - ma con FK disabilitate non importa)
# Stessa lista usata in 27rinumerasaledoc/02rinumeraIdSaledocCrs.ps1
$tables = @(
    "MA_SaleDocDetail",
    "MA_SaleDocComponents",
    "MA_SaleDocManufReasons",
    "MA_SaleDocNotes",
    "MA_SaleDocPymtSched",
    "MA_SaleDocReferences",
    "MA_SaleDocShipping",
    "MA_SaleDocSummary",
    "MA_SaleDocTaxSummary",
    "MA_SaleDocDetailAccDef",
    "MA_SaleDocDetailVar",
    "IM_SaleDocJobs",
    "MA_BRNotaFiscalForCustomer",
    "MA_BRNotaFiscalForCustDetail",
    "MA_BRNotaFiscalForCustSummary",
    "MA_BRNotaFiscalForCustRef",
    "MA_BRNotaFiscalForCustShipping",
    "MA_BRNotaFiscalForCustAdDat",
    "MA_CostAccEntries",
    "MA_PurchaseDocDetail",
    "IM_Schedules",
    "MA_WMPreShippingDetails",
    "MA_SaleDoc"    # Parent table - per ultima
)

# ReferenceCode per documenti di vendita in MA_CrossReferences
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
Write-Host "  SCRIPT 28: RINUMERAZIONE SaleDocId su VEDMaster" -ForegroundColor Cyan
Write-Host "  Versione 2.0 - Allinea ID VEDMaster ai clone" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
Write-Host "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

# ============================================
# FASE 0: Diagnostica - stato attuale
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 0: Diagnostica stato attuale" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$totalSaleDoc = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.MA_SaleDoc" -connString $connString
Write-Host "  Totale documenti in MA_SaleDoc su VEDMaster: $totalSaleDoc" -ForegroundColor White

# Conta per tipo documento
$docStats = Execute-SqlReader -query @"
SELECT DocumentType, COUNT(*) as Cnt
FROM $destinationDB.dbo.MA_SaleDoc
WHERE DocumentType BETWEEN 3407873 AND 3407899
GROUP BY DocumentType ORDER BY DocumentType
"@ -connString $connString

if ($docStats) {
    Write-Host "  Distribuzione per tipo:" -ForegroundColor Gray
    foreach ($row in $docStats) {
        Write-Host "    Tipo $($row.DocumentType): $($row.Cnt) documenti" -ForegroundColor Gray
    }
}

$totalCR = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences" -connString $connString
Write-Host "  Totale MA_CrossReferences su VEDMaster: $totalCR" -ForegroundColor White
Write-Host ""

# ============================================
# FASE 1: Creazione tabella di mapping
# ============================================
# Per ogni fattura su VEDMaster, trova il corrispondente SaleDocId
# nel clone tramite business key match.
# Il SaleDocId del clone e' gia' rinumerato (con offset).
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 1: Creazione mapping VEDMaster -> Clone" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Execute-SqlNonQuery -query @"
IF OBJECT_ID('$destinationDB.dbo.TAG_RenumberMapping') IS NOT NULL
    DROP TABLE $destinationDB.dbo.TAG_RenumberMapping;

CREATE TABLE $destinationDB.dbo.TAG_RenumberMapping (
    CurrentSaleDocId INT NOT NULL,     -- ID attuale su VEDMaster (originale vedcontab)
    NewSaleDocId INT NOT NULL,         -- ID dal clone (rinumerato con offset)
    DocumentType INT,
    DocNo NVARCHAR(50),
    DocumentDate DATETIME,
    CustSupp NVARCHAR(50),
    SourceDB NVARCHAR(50)              -- Clone di provenienza
);

CREATE UNIQUE INDEX IX_TAG_RenumberMapping_Current
    ON $destinationDB.dbo.TAG_RenumberMapping (CurrentSaleDocId);
CREATE INDEX IX_TAG_RenumberMapping_New
    ON $destinationDB.dbo.TAG_RenumberMapping (NewSaleDocId);
"@ -connString $connString `
    -msgOk "  Tabella TAG_RenumberMapping creata" `
    -msgErr "  Errore creazione TAG_RenumberMapping"

foreach ($sourceDB in $sourceDatabases) {
    $dbName = $sourceDB.Name
    $dbOffset = $sourceDB.Offset
    Write-Host "  Popolamento da: $dbName (offset +$dbOffset)" -ForegroundColor Yellow

    # Match per business key: DocNo + DocumentDate + CustSupp + DocumentType
    # Il clone ha SaleDocId gia' rinumerato.
    #
    # DEDUPLICAZIONE (v2.0):
    # - ROW_NUMBER per CurrentSaleDocId: se lo stesso doc VEDMaster matcha piu' clone rows, prende il primo
    # - ROW_NUMBER per NewSaleDocId: se piu' doc VEDMaster matchano lo stesso clone row, prende il primo
    # - NOT EXISTS: evita duplicati con righe gia' inserite dai clone precedenti
    $insertSQL = @"
    ;WITH Matches AS (
        SELECT
            vm.SaleDocId as CurrentSaleDocId,
            clone.SaleDocId as NewSaleDocId,
            vm.DocumentType,
            vm.DocNo,
            vm.DocumentDate,
            vm.CustSupp,
            '$dbName' as SourceDB,
            ROW_NUMBER() OVER (PARTITION BY vm.SaleDocId ORDER BY clone.SaleDocId) as rn_current,
            ROW_NUMBER() OVER (PARTITION BY clone.SaleDocId ORDER BY vm.SaleDocId) as rn_new
        FROM $destinationDB.dbo.MA_SaleDoc vm
        INNER JOIN $dbName.dbo.MA_SaleDoc clone
            ON clone.DocNo = vm.DocNo
            AND clone.DocumentDate = vm.DocumentDate
            AND clone.CustSupp = vm.CustSupp
            AND clone.DocumentType = vm.DocumentType
        WHERE vm.SaleDocId <> clone.SaleDocId
          AND NOT EXISTS (
              SELECT 1 FROM $destinationDB.dbo.TAG_RenumberMapping m
              WHERE m.CurrentSaleDocId = vm.SaleDocId
          )
          AND NOT EXISTS (
              SELECT 1 FROM $destinationDB.dbo.TAG_RenumberMapping m
              WHERE m.NewSaleDocId = clone.SaleDocId
          )
    )
    INSERT INTO $destinationDB.dbo.TAG_RenumberMapping
        (CurrentSaleDocId, NewSaleDocId, DocumentType, DocNo, DocumentDate, CustSupp, SourceDB)
    SELECT CurrentSaleDocId, NewSaleDocId, DocumentType, DocNo, DocumentDate, CustSupp, SourceDB
    FROM Matches
    WHERE rn_current = 1 AND rn_new = 1
"@

    Execute-SqlNonQuery -query $insertSQL -connString $connString `
        -msgOk "    Mappature inserite da $dbName" `
        -msgErr "    Errore inserimento da $dbName"
}

# Statistiche mapping
$totalMapping = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.TAG_RenumberMapping" -connString $connString
Write-Host ""
Write-Host "  Totale documenti da rinumerare: $totalMapping" -ForegroundColor White

$mappingPerDB = Execute-SqlReader -query @"
SELECT SourceDB, COUNT(*) as Cnt, MIN(NewSaleDocId) as MinNew, MAX(NewSaleDocId) as MaxNew
FROM $destinationDB.dbo.TAG_RenumberMapping
GROUP BY SourceDB ORDER BY SourceDB
"@ -connString $connString

if ($mappingPerDB) {
    foreach ($row in $mappingPerDB) {
        Write-Host "    $($row.SourceDB): $($row.Cnt) documenti (ID range: $($row.MinNew)-$($row.MaxNew))" -ForegroundColor Gray
    }
}

# Check: documenti VEDMaster NON matchati (restano con ID originale)
$unmatched = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_SaleDoc vm
WHERE vm.DocumentType BETWEEN 3407873 AND 3407899
  AND NOT EXISTS (
      SELECT 1 FROM $destinationDB.dbo.TAG_RenumberMapping m
      WHERE m.CurrentSaleDocId = vm.SaleDocId
  )
"@ -connString $connString
Write-Host "  Documenti VEDMaster senza match nei clone: $unmatched (restano con ID originale)" -ForegroundColor $(if ($unmatched -eq 0) { "Green" } else { "Yellow" })

if ($unmatched -gt 0) {
    # Verifica che gli ID non matchati non collidano con i range dei clone
    $collisionCheck = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM $destinationDB.dbo.MA_SaleDoc vm
    WHERE vm.DocumentType BETWEEN 3407873 AND 3407899
      AND NOT EXISTS (
          SELECT 1 FROM $destinationDB.dbo.TAG_RenumberMapping m
          WHERE m.CurrentSaleDocId = vm.SaleDocId
      )
      AND (vm.SaleDocId >= 200000)  -- Range usati dai clone
"@ -connString $connString
    if ($collisionCheck -gt 0) {
        Write-Host "  ATTENZIONE: $collisionCheck documenti non matchati hanno ID >= 200000 (possibile collisione!)" -ForegroundColor Red
    }
    else {
        Write-Host "  OK: tutti gli ID non matchati sono < 200000 (nessuna collisione)" -ForegroundColor Green
    }
}

# Check: ambiguita' (un VEDMaster ID matchato da piu' clone - gestito dal NOT EXISTS sopra, ma verifica)
$ambiguous = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM (
    SELECT CurrentSaleDocId
    FROM $destinationDB.dbo.TAG_RenumberMapping
    GROUP BY CurrentSaleDocId
    HAVING COUNT(*) > 1
) t
"@ -connString $connString
if ($ambiguous -gt 0) {
    Write-Host "  ATTENZIONE: $ambiguous ID con match multipli!" -ForegroundColor Red
}

# Check: collisione NewSaleDocId (due current ID che mappano allo stesso nuovo ID)
$newIdCollision = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM (
    SELECT NewSaleDocId
    FROM $destinationDB.dbo.TAG_RenumberMapping
    GROUP BY NewSaleDocId
    HAVING COUNT(*) > 1
) t
"@ -connString $connString
if ($newIdCollision -gt 0) {
    Write-Host "  ATTENZIONE: $newIdCollision NewSaleDocId duplicati nel mapping!" -ForegroundColor Red
}

# Check: collisione tra NewSaleDocId e SaleDocId gia' esistenti su VEDMaster (non nel mapping)
$existingCollision = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.TAG_RenumberMapping m
INNER JOIN $destinationDB.dbo.MA_SaleDoc sd ON sd.SaleDocId = m.NewSaleDocId
WHERE sd.SaleDocId NOT IN (SELECT CurrentSaleDocId FROM $destinationDB.dbo.TAG_RenumberMapping)
"@ -connString $connString
if ($existingCollision -gt 0) {
    Write-Host "  ATTENZIONE: $existingCollision NewSaleDocId collidono con ID esistenti non nel mapping!" -ForegroundColor Red
    Write-Host "  Lo script potrebbe generare errori di chiave duplicata." -ForegroundColor Red
}
else {
    Write-Host "  OK: nessuna collisione tra nuovi ID e ID esistenti" -ForegroundColor Green
}

Write-Host ""

if ($totalMapping -eq 0) {
    Write-Host "  Nessun documento da rinumerare. Fine script." -ForegroundColor Yellow
    exit
}

# ============================================
# FASE 2: Disabilita vincoli FK
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 2: Disabilita vincoli FK su MA_SaleDoc" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Trova e disabilita tutte le FK che referenziano MA_SaleDoc.SaleDocId
$fkQuery = @"
SELECT
    'ALTER TABLE [' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '].[' + OBJECT_NAME(fk.parent_object_id) + '] NOCHECK CONSTRAINT [' + fk.name + ']' as DisableSQL,
    'ALTER TABLE [' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '].[' + OBJECT_NAME(fk.parent_object_id) + '] WITH CHECK CHECK CONSTRAINT [' + fk.name + ']' as EnableSQL,
    fk.name as FKName,
    OBJECT_NAME(fk.parent_object_id) as ParentTable
FROM $destinationDB.sys.foreign_keys fk
INNER JOIN $destinationDB.sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.referenced_object_id) = 'MA_SaleDoc'
  AND COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) = 'SaleDocId'
"@

$fkConstraints = Execute-SqlReader -query $fkQuery -connString $connString
$enableFKCommands = @()

if ($fkConstraints) {
    foreach ($fk in $fkConstraints) {
        Execute-SqlNonQuery -query $fk.DisableSQL -connString $connString `
            -msgOk "  FK disabilitata: $($fk.FKName) ($($fk.ParentTable))" `
            -msgErr "  Errore disabilitazione FK: $($fk.FKName)"
        $enableFKCommands += $fk.EnableSQL
    }
}
Write-Host "  Totale FK disabilitate: $($fkConstraints.Count)" -ForegroundColor White
Write-Host ""

# ============================================
# FASE 3: Rinumerazione SaleDocId nelle tabelle
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 3: Rinumerazione SaleDocId" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$errorOccurred = $false

# APPROCCIO A 2 PASSAGGI (v2.0):
# Passaggio 1: SaleDocId -> valore negativo temporaneo (-NewSaleDocId)
#   Questo evita PK violation perche' i valori negativi non collidono con nessun ID esistente
# Passaggio 2: SaleDocId negativo -> valore positivo finale (ABS)
#   A questo punto i vecchi ID sono gia' stati rimossi, nessuna collisione possibile

Write-Host "  Passaggio 1: MA_SaleDoc -> valori negativi temporanei..." -ForegroundColor Yellow
$pass1Result = Execute-SqlNonQuery -query @"
UPDATE sd
SET sd.SaleDocId = -m.NewSaleDocId
FROM $destinationDB.dbo.MA_SaleDoc sd
INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m
    ON m.CurrentSaleDocId = sd.SaleDocId
"@ -connString $connString `
    -msgOk "    MA_SaleDoc passaggio 1 (negativo)" `
    -msgErr "    ERRORE passaggio 1 MA_SaleDoc"

if ($pass1Result -eq -1) {
    Write-Host "  ERRORE CRITICO su MA_SaleDoc passaggio 1. Interruzione." -ForegroundColor Red
    $errorOccurred = $true
}

if (-not $errorOccurred) {
    Write-Host "  Passaggio 2: MA_SaleDoc -> valori positivi finali..." -ForegroundColor Yellow
    $pass2Result = Execute-SqlNonQuery -query @"
    UPDATE $destinationDB.dbo.MA_SaleDoc
    SET SaleDocId = ABS(SaleDocId)
    WHERE SaleDocId < 0
"@ -connString $connString `
        -msgOk "    MA_SaleDoc passaggio 2 (positivo)" `
        -msgErr "    ERRORE passaggio 2 MA_SaleDoc"

    if ($pass2Result -eq -1) {
        Write-Host "  ERRORE CRITICO su MA_SaleDoc passaggio 2. Interruzione." -ForegroundColor Red
        $errorOccurred = $true
    }
}

# Aggiorna le child tables (stessi 2 passaggi)
if (-not $errorOccurred) {
    $childTables = $tables | Where-Object { $_ -ne "MA_SaleDoc" }

    foreach ($table in $childTables) {
        # Verifica se la tabella esiste
        $tableExists = Execute-SqlScalar -query @"
        SELECT COUNT(*) FROM $destinationDB.sys.objects
        WHERE object_id = OBJECT_ID(N'$destinationDB.dbo.$table') AND type = 'U'
"@ -connString $connString

        if ($tableExists -eq 0) {
            Write-Host "    $table - non esiste, skip" -ForegroundColor DarkGray
            continue
        }

        # Verifica se la tabella ha la colonna SaleDocId
        $hasColumn = Execute-SqlScalar -query @"
        SELECT COUNT(*) FROM $destinationDB.sys.columns c
        INNER JOIN $destinationDB.sys.objects o ON c.object_id = o.object_id
        WHERE o.object_id = OBJECT_ID(N'$destinationDB.dbo.$table')
          AND c.name = 'SaleDocId'
"@ -connString $connString

        if ($hasColumn -eq 0) {
            Write-Host "    $table - colonna SaleDocId non trovata, skip" -ForegroundColor DarkGray
            continue
        }

        # Passaggio 1: negativo
        $r1 = Execute-SqlNonQuery -query @"
        UPDATE t
        SET t.SaleDocId = -m.NewSaleDocId
        FROM $destinationDB.dbo.$table t
        INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m
            ON m.CurrentSaleDocId = t.SaleDocId
"@ -connString $connString `
            -msgOk "    $table pass1 (neg)" `
            -msgErr "    ERRORE $table pass1"

        # Passaggio 2: positivo
        $r2 = Execute-SqlNonQuery -query @"
        UPDATE $destinationDB.dbo.$table
        SET SaleDocId = ABS(SaleDocId)
        WHERE SaleDocId < 0
"@ -connString $connString `
            -msgOk "    $table pass2 (pos)" `
            -msgErr "    ERRORE $table pass2"

        if ($r1 -eq -1 -or $r2 -eq -1) {
            Write-Host "    ERRORE su $table, proseguo con le altre..." -ForegroundColor Red
            $errorOccurred = $true
        }
    }
}

Write-Host ""

# ============================================
# FASE 4: Aggiornamento MA_CrossReferences esistenti
# ============================================
# Le cross-references GIA' presenti su VEDMaster (da vedcontab)
# puntano ancora agli ID originali. Vanno aggiornate.
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 4: Aggiornamento cross-references esistenti" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 4a: Aggiorna OriginDocID
$originToFix = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = cr.OriginDocID
WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString
Write-Host "  OriginDocID da aggiornare: $originToFix" -ForegroundColor $(if ($originToFix -gt 0) { "Yellow" } else { "Green" })

if ($originToFix -gt 0) {
    # Approccio DELETE + INSERT per evitare violazioni PK
    Execute-SqlNonQuery -query @"
    IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCROriginRenumber') IS NOT NULL
        DROP TABLE $destinationDB.dbo.TAG_TmpCROriginRenumber;

    SELECT
        cr.OriginDocType, m.NewSaleDocId as OriginDocID, cr.OriginDocSubID, cr.OriginDocLine,
        cr.DerivedDocType, cr.DerivedDocID, cr.DerivedDocSubID, cr.DerivedDocLine,
        cr.[Manual], cr.TBCreated, cr.TBModified, cr.TBCreatedID, cr.TBModifiedID,
        ROW_NUMBER() OVER (
            PARTITION BY cr.OriginDocType, m.NewSaleDocId, cr.OriginDocSubID, cr.OriginDocLine,
                         cr.DerivedDocType, cr.DerivedDocID, cr.DerivedDocSubID, cr.DerivedDocLine
            ORDER BY cr.OriginDocID
        ) as rn
    INTO $destinationDB.dbo.TAG_TmpCROriginRenumber
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = cr.OriginDocID
    WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString `
        -msgOk "    Righe salvate in TAG_TmpCROriginRenumber" `
        -msgErr "    ERRORE salvataggio"

    Execute-SqlNonQuery -query @"
    DELETE cr
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = cr.OriginDocID
    WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString `
        -msgOk "    Righe con vecchio OriginDocID eliminate" `
        -msgErr "    ERRORE eliminazione"

    Execute-SqlNonQuery -query @"
    INSERT INTO $destinationDB.dbo.MA_CrossReferences
        (OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
         DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
         [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID)
    SELECT
        t.OriginDocType, t.OriginDocID, t.OriginDocSubID, t.OriginDocLine,
        t.DerivedDocType, t.DerivedDocID, t.DerivedDocSubID, t.DerivedDocLine,
        t.[Manual], t.TBCreated, t.TBModified, t.TBCreatedID, t.TBModifiedID
    FROM $destinationDB.dbo.TAG_TmpCROriginRenumber t
    WHERE t.rn = 1
        AND NOT EXISTS (
            SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences x
            WHERE x.OriginDocType = t.OriginDocType AND x.OriginDocID = t.OriginDocID
              AND x.OriginDocSubID = t.OriginDocSubID AND x.OriginDocLine = t.OriginDocLine
              AND x.DerivedDocType = t.DerivedDocType AND x.DerivedDocID = t.DerivedDocID
              AND x.DerivedDocSubID = t.DerivedDocSubID AND x.DerivedDocLine = t.DerivedDocLine
        )
"@ -connString $connString `
        -msgOk "    Righe inserite con OriginDocID rinumerato" `
        -msgErr "    ERRORE inserimento"

    Execute-SqlNonQuery -query "IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCROriginRenumber') IS NOT NULL DROP TABLE $destinationDB.dbo.TAG_TmpCROriginRenumber" -connString $connString
}

# 4b: Aggiorna DerivedDocID
$derivedToFix = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = cr.DerivedDocID
WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString
Write-Host "  DerivedDocID da aggiornare: $derivedToFix" -ForegroundColor $(if ($derivedToFix -gt 0) { "Yellow" } else { "Green" })

if ($derivedToFix -gt 0) {
    Execute-SqlNonQuery -query @"
    IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCRDerivedRenumber') IS NOT NULL
        DROP TABLE $destinationDB.dbo.TAG_TmpCRDerivedRenumber;

    SELECT
        cr.OriginDocType, cr.OriginDocID, cr.OriginDocSubID, cr.OriginDocLine,
        cr.DerivedDocType, m.NewSaleDocId as DerivedDocID, cr.DerivedDocSubID, cr.DerivedDocLine,
        cr.[Manual], cr.TBCreated, cr.TBModified, cr.TBCreatedID, cr.TBModifiedID,
        ROW_NUMBER() OVER (
            PARTITION BY cr.OriginDocType, cr.OriginDocID, cr.OriginDocSubID, cr.OriginDocLine,
                         cr.DerivedDocType, m.NewSaleDocId, cr.DerivedDocSubID, cr.DerivedDocLine
            ORDER BY cr.DerivedDocID
        ) as rn
    INTO $destinationDB.dbo.TAG_TmpCRDerivedRenumber
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = cr.DerivedDocID
    WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString `
        -msgOk "    Righe salvate in TAG_TmpCRDerivedRenumber" `
        -msgErr "    ERRORE salvataggio"

    Execute-SqlNonQuery -query @"
    DELETE cr
    FROM $destinationDB.dbo.MA_CrossReferences cr
    INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = cr.DerivedDocID
    WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString `
        -msgOk "    Righe con vecchio DerivedDocID eliminate" `
        -msgErr "    ERRORE eliminazione"

    Execute-SqlNonQuery -query @"
    INSERT INTO $destinationDB.dbo.MA_CrossReferences
        (OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
         DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
         [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID)
    SELECT
        t.OriginDocType, t.OriginDocID, t.OriginDocSubID, t.OriginDocLine,
        t.DerivedDocType, t.DerivedDocID, t.DerivedDocSubID, t.DerivedDocLine,
        t.[Manual], t.TBCreated, t.TBModified, t.TBCreatedID, t.TBModifiedID
    FROM $destinationDB.dbo.TAG_TmpCRDerivedRenumber t
    WHERE t.rn = 1
        AND NOT EXISTS (
            SELECT 1 FROM $destinationDB.dbo.MA_CrossReferences x
            WHERE x.OriginDocType = t.OriginDocType AND x.OriginDocID = t.OriginDocID
              AND x.OriginDocSubID = t.OriginDocSubID AND x.OriginDocLine = t.OriginDocLine
              AND x.DerivedDocType = t.DerivedDocType AND x.DerivedDocID = t.DerivedDocID
              AND x.DerivedDocSubID = t.DerivedDocSubID AND x.DerivedDocLine = t.DerivedDocLine
        )
"@ -connString $connString `
        -msgOk "    Righe inserite con DerivedDocID rinumerato" `
        -msgErr "    ERRORE inserimento"

    Execute-SqlNonQuery -query "IF OBJECT_ID('$destinationDB.dbo.TAG_TmpCRDerivedRenumber') IS NOT NULL DROP TABLE $destinationDB.dbo.TAG_TmpCRDerivedRenumber" -connString $connString
}

# 4c: Aggiorna anche MA_CrossReferencesNotes
Write-Host ""
Write-Host "  Aggiornamento MA_CrossReferencesNotes..." -ForegroundColor Yellow

$notesTableExists = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.sys.objects
WHERE object_id = OBJECT_ID(N'$destinationDB.dbo.MA_CrossReferencesNotes') AND type = 'U'
"@ -connString $connString

if ($notesTableExists -gt 0) {
    # OriginDocID
    Execute-SqlNonQuery -query @"
    UPDATE crn
    SET crn.OriginDocID = m.NewSaleDocId
    FROM $destinationDB.dbo.MA_CrossReferencesNotes crn
    INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = crn.OriginDocID
    WHERE crn.OriginDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString `
        -msgOk "    CrossReferencesNotes OriginDocID aggiornato" `
        -msgErr "    ERRORE OriginDocID CrossReferencesNotes"

    # DerivedDocID
    Execute-SqlNonQuery -query @"
    UPDATE crn
    SET crn.DerivedDocID = m.NewSaleDocId
    FROM $destinationDB.dbo.MA_CrossReferencesNotes crn
    INNER JOIN $destinationDB.dbo.TAG_RenumberMapping m ON m.CurrentSaleDocId = crn.DerivedDocID
    WHERE crn.DerivedDocType IN ($saleDocRefCodesSQL)
"@ -connString $connString `
        -msgOk "    CrossReferencesNotes DerivedDocID aggiornato" `
        -msgErr "    ERRORE DerivedDocID CrossReferencesNotes"
}
else {
    Write-Host "    Tabella MA_CrossReferencesNotes non presente, skip" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================
# FASE 5: Riabilita vincoli FK
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 5: Riabilita vincoli FK" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

foreach ($enableSQL in $enableFKCommands) {
    Execute-SqlNonQuery -query $enableSQL -connString $connString `
        -msgOk "  FK riabilitata" `
        -msgErr "  ERRORE riabilitazione FK"
}
Write-Host "  Totale FK riabilitate: $($enableFKCommands.Count)" -ForegroundColor White
Write-Host ""

# ============================================
# FASE 6: Verifica finale
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 6: Verifica finale" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verifica: ogni NewSaleDocId deve ora esistere in MA_SaleDoc
$notMigrated = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.TAG_RenumberMapping m
WHERE NOT EXISTS (
    SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
    WHERE sd.SaleDocId = m.NewSaleDocId
)
"@ -connString $connString
Write-Host "  Mapping non riscontrati in MA_SaleDoc: $notMigrated" -ForegroundColor $(if ($notMigrated -eq 0) { "Green" } else { "Red" })

# Verifica: nessun vecchio ID deve restare in MA_SaleDoc
$oldIdStillPresent = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.TAG_RenumberMapping m
WHERE m.CurrentSaleDocId <> m.NewSaleDocId
  AND EXISTS (
    SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd
    WHERE sd.SaleDocId = m.CurrentSaleDocId
)
"@ -connString $connString
Write-Host "  Vecchi ID ancora presenti in MA_SaleDoc: $oldIdStillPresent" -ForegroundColor $(if ($oldIdStillPresent -eq 0) { "Green" } else { "Red" })

# Conta documenti per range ID (verifica distribuzione)
$rangeStats = Execute-SqlReader -query @"
SELECT
    CASE
        WHEN SaleDocId >= 400000 AND SaleDocId < 500000 THEN 'gpxnetclone (400k)'
        WHEN SaleDocId >= 200000 AND SaleDocId < 300000 THEN 'furmanetclone (200k)'
        WHEN SaleDocId >= 300000 AND SaleDocId < 400000 THEN 'vedbondifeclone (300k)'
        WHEN SaleDocId < 200000 THEN 'originale vedcontab (<200k)'
        ELSE 'altro range'
    END as RangeID,
    COUNT(*) as Cnt
FROM $destinationDB.dbo.MA_SaleDoc
WHERE DocumentType BETWEEN 3407873 AND 3407899
GROUP BY
    CASE
        WHEN SaleDocId >= 400000 AND SaleDocId < 500000 THEN 'gpxnetclone (400k)'
        WHEN SaleDocId >= 200000 AND SaleDocId < 300000 THEN 'furmanetclone (200k)'
        WHEN SaleDocId >= 300000 AND SaleDocId < 400000 THEN 'vedbondifeclone (300k)'
        WHEN SaleDocId < 200000 THEN 'originale vedcontab (<200k)'
        ELSE 'altro range'
    END
ORDER BY RangeID
"@ -connString $connString

if ($rangeStats) {
    Write-Host "  Distribuzione SaleDocId per range:" -ForegroundColor White
    foreach ($row in $rangeStats) {
        Write-Host "    $($row.RangeID): $($row.Cnt) documenti" -ForegroundColor Gray
    }
}

# Cross-references: orfani residui
$orphanDerived = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.DerivedDocType IN ($saleDocRefCodesSQL)
  AND NOT EXISTS (SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd WHERE sd.SaleDocId = cr.DerivedDocID)
"@ -connString $connString
Write-Host "  DerivedDocID orfani nei cross-references: $orphanDerived" -ForegroundColor $(if ($orphanDerived -eq 0) { "Green" } else { "Yellow" })

$orphanOrigin = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.dbo.MA_CrossReferences cr
WHERE cr.OriginDocType IN ($saleDocRefCodesSQL)
  AND NOT EXISTS (SELECT 1 FROM $destinationDB.dbo.MA_SaleDoc sd WHERE sd.SaleDocId = cr.OriginDocID)
"@ -connString $connString
Write-Host "  OriginDocID orfani nei cross-references: $orphanOrigin" -ForegroundColor $(if ($orphanOrigin -eq 0) { "Green" } else { "Yellow" })

# Campione: 5 fatture rinumerate
Write-Host ""
Write-Host "  --- CAMPIONE: Documenti rinumerati ---" -ForegroundColor Yellow
$sample = Execute-SqlReader -query @"
SELECT TOP 5
    m.CurrentSaleDocId as VecchioID,
    m.NewSaleDocId as NuovoID,
    m.DocNo,
    m.DocumentDate,
    m.CustSupp,
    m.SourceDB
FROM $destinationDB.dbo.TAG_RenumberMapping m
ORDER BY m.SourceDB, m.DocNo
"@ -connString $connString

if ($sample) {
    foreach ($row in $sample) {
        Write-Host "    $($row.VecchioID) -> $($row.NuovoID) | $($row.DocNo) | $($row.CustSupp) | $($row.SourceDB)" -ForegroundColor Green
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

Write-Host "  Ora inizio:              $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Ora fine:                $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Durata:                  $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host ""
Write-Host "  Documenti rinumerati:    $totalMapping" -ForegroundColor White
Write-Host "  Documenti non matchati:  $unmatched (ID originale preservato)" -ForegroundColor White
Write-Host "  CR OriginDocID fix:      $originToFix" -ForegroundColor White
Write-Host "  CR DerivedDocID fix:     $derivedToFix" -ForegroundColor White

if ($errorOccurred) {
    Write-Host ""
    Write-Host "  ATTENZIONE: si sono verificati errori durante l'esecuzione!" -ForegroundColor Red
    Write-Host "  Verificare i messaggi sopra e la tabella TAG_RenumberMapping per dettagli." -ForegroundColor Red
}
else {
    Write-Host ""
    Write-Host "  Operazione completata con successo!" -ForegroundColor Green
    Write-Host "  La tabella TAG_RenumberMapping e' stata preservata per riferimento." -ForegroundColor Gray
    Write-Host "  Lo script 23 (PostTrasfAggiornariffatturevedmaster) NON e' piu' necessario." -ForegroundColor Yellow
}
