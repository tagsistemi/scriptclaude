# =============================================================================
# 00_CensimentoDMS.ps1
# Censimento dei 4 database DMS per calcolo offset e mappa PrimaryKeyValue
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername    = "sa"
$SqlPassword   = "stream"

# I 4 database DMS
$DmsDatabases = @(
    @{ Name = "vedcontabdms";  Label = "VEDCONTAB (base)";  ErpClone = "vedcontab" }
    @{ Name = "gpxnetdms";     Label = "GPXNET";            ErpClone = "gpxnetclone" }
    @{ Name = "furmanetdms";   Label = "FURMANET";          ErpClone = "furmanetclone" }
    @{ Name = "vedbondifedms"; Label = "VEDBONDIFE";        ErpClone = "vedbondifeclone" }
)

Add-Type -AssemblyName System.Data

function Invoke-SqlQuery {
    param(
        [string]$Database,
        [string]$Query
    )
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
    catch {
        Write-Host "  ERRORE su $Database : $_" -ForegroundColor Red
    }
    finally {
        if ($connection.State -eq 'Open') { $connection.Close() }
    }
    return $results
}

# =============================================================================
# SEZIONE 1: MAX ID per calcolo offset
# =============================================================================
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 1: MAX ID PER TABELLA - CALCOLO OFFSET" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$maxIdQuery = @"
SELECT
    (SELECT ISNULL(MAX(ArchivedDocID), 0) FROM dbo.DMS_ArchivedDocument) AS MaxArchivedDocID,
    (SELECT ISNULL(MAX(ErpDocumentID), 0) FROM dbo.DMS_ErpDocument)     AS MaxErpDocumentID,
    (SELECT ISNULL(MAX(AttachmentID), 0)  FROM dbo.DMS_Attachment)      AS MaxAttachmentID,
    (SELECT ISNULL(MAX(SearchIndexID), 0) FROM dbo.DMS_SearchFieldIndexes) AS MaxSearchIndexID,
    (SELECT ISNULL(MAX(EnvelopeID), 0)    FROM dbo.DMS_SOSEnvelope)     AS MaxEnvelopeID,
    (SELECT ISNULL(MAX(CollectionID), 0)  FROM dbo.DMS_Collection)      AS MaxCollectionID,
    (SELECT ISNULL(MAX(CollectorID), 0)   FROM dbo.DMS_Collector)       AS MaxCollectorID
"@

$allMaxIds = @()

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- $($db.Label) [$($db.Name)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.Name -Query $maxIdQuery

    if ($rows.Count -gt 0) {
        $row = $rows[0]
        Write-Host "  MaxArchivedDocID : $($row.MaxArchivedDocID)"
        Write-Host "  MaxErpDocumentID : $($row.MaxErpDocumentID)"
        Write-Host "  MaxAttachmentID  : $($row.MaxAttachmentID)"
        Write-Host "  MaxSearchIndexID : $($row.MaxSearchIndexID)"
        Write-Host "  MaxEnvelopeID    : $($row.MaxEnvelopeID)"
        Write-Host "  MaxCollectionID  : $($row.MaxCollectionID)"
        Write-Host "  MaxCollectorID   : $($row.MaxCollectorID)"

        $allMaxIds += [PSCustomObject]@{
            Database        = $db.Name
            Label           = $db.Label
            ArchivedDocID   = [int]$row.MaxArchivedDocID
            ErpDocumentID   = [int]$row.MaxErpDocumentID
            AttachmentID    = [int]$row.MaxAttachmentID
            SearchIndexID   = [int]$row.MaxSearchIndexID
            EnvelopeID      = [int]$row.MaxEnvelopeID
            CollectionID    = [int]$row.MaxCollectionID
            CollectorID     = [int]$row.MaxCollectorID
        }
    }
}

# Calcolo offset suggeriti
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "CALCOLO OFFSET SUGGERITI" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$idTypes = @("ArchivedDocID", "ErpDocumentID", "AttachmentID", "SearchIndexID", "EnvelopeID", "CollectionID", "CollectorID")

foreach ($idType in $idTypes) {
    $maxVal = ($allMaxIds | ForEach-Object { $_.$idType } | Measure-Object -Maximum).Maximum
    # Offset = arrotondamento al multiplo di 100k superiore
    $suggestedOffset = [Math]::Ceiling($maxVal / 100000) * 100000
    if ($suggestedOffset -lt 100000) { $suggestedOffset = 100000 }
    Write-Host ("  {0,-20}: MAX globale = {1,8} -> Offset = {2} (x2={3}, x3={4})" -f $idType, $maxVal, $suggestedOffset, ($suggestedOffset*2), ($suggestedOffset*3)) -ForegroundColor Green
}

# =============================================================================
# SEZIONE 2: CONTEGGIO RECORD PER TABELLA
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 2: CONTEGGIO RECORD PER TABELLA" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$countQuery = @"
SELECT
    (SELECT COUNT(*) FROM dbo.DMS_ArchivedDocument)         AS ArchivedDocument,
    (SELECT COUNT(*) FROM dbo.DMS_ArchivedDocContent)       AS ArchivedDocContent,
    (SELECT COUNT(*) FROM dbo.DMS_ArchivedDocTextContent)   AS ArchivedDocTextContent,
    (SELECT COUNT(*) FROM dbo.DMS_ArchivedDocSearchIndexes) AS ArchivedDocSearchIndexes,
    (SELECT COUNT(*) FROM dbo.DMS_ErpDocument)              AS ErpDocument,
    (SELECT COUNT(*) FROM dbo.DMS_Attachment)               AS Attachment,
    (SELECT COUNT(*) FROM dbo.DMS_AttachmentSearchIndexes)  AS AttachmentSearchIndexes,
    (SELECT COUNT(*) FROM dbo.DMS_ErpDocBarcodes)           AS ErpDocBarcodes,
    (SELECT COUNT(*) FROM dbo.DMS_IndexesSynchronization)   AS IndexesSynchronization,
    (SELECT COUNT(*) FROM dbo.DMS_SearchFieldIndexes)       AS SearchFieldIndexes,
    (SELECT COUNT(*) FROM dbo.DMS_SOSDocument)              AS SOSDocument,
    (SELECT COUNT(*) FROM dbo.DMS_SOSEnvelope)              AS SOSEnvelope,
    (SELECT COUNT(*) FROM dbo.DMS_DocumentToArchive)        AS DocumentToArchive,
    (SELECT COUNT(*) FROM dbo.DMS_Collection)               AS Coll,
    (SELECT COUNT(*) FROM dbo.DMS_Collector)                AS Collector,
    (SELECT COUNT(*) FROM dbo.DMS_Field)                    AS Field,
    (SELECT COUNT(*) FROM dbo.DMS_Settings)                 AS Settings
"@

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- $($db.Label) [$($db.Name)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.Name -Query $countQuery

    if ($rows.Count -gt 0) {
        $row = $rows[0]
        Write-Host "  TABELLE DATI:" -ForegroundColor White
        Write-Host "    DMS_ArchivedDocument         : $($row.ArchivedDocument)"
        Write-Host "    DMS_ArchivedDocContent       : $($row.ArchivedDocContent)"
        Write-Host "    DMS_ArchivedDocTextContent   : $($row.ArchivedDocTextContent)"
        Write-Host "    DMS_ArchivedDocSearchIndexes : $($row.ArchivedDocSearchIndexes)"
        Write-Host "    DMS_ErpDocument              : $($row.ErpDocument)"
        Write-Host "    DMS_Attachment               : $($row.Attachment)"
        Write-Host "    DMS_AttachmentSearchIndexes  : $($row.AttachmentSearchIndexes)"
        Write-Host "    DMS_ErpDocBarcodes           : $($row.ErpDocBarcodes)"
        Write-Host "    DMS_IndexesSynchronization   : $($row.IndexesSynchronization)"
        Write-Host "    DMS_SearchFieldIndexes       : $($row.SearchFieldIndexes)"
        Write-Host "    DMS_SOSDocument              : $($row.SOSDocument)"
        Write-Host "    DMS_SOSEnvelope              : $($row.SOSEnvelope)"
        Write-Host "    DMS_DocumentToArchive        : $($row.DocumentToArchive)"
        Write-Host "  TABELLE CONFIGURAZIONE:" -ForegroundColor White
        Write-Host "    DMS_Collection               : $($row.Coll)"
        Write-Host "    DMS_Collector                : $($row.Collector)"
        Write-Host "    DMS_Field                    : $($row.Field)"
        Write-Host "    DMS_Settings                 : $($row.Settings)"
    }
}

# =============================================================================
# SEZIONE 3: STIMA DIMENSIONE BINARI (MB)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 3: DIMENSIONE BINARI (DMS_ArchivedDocContent)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$sizeQuery = @"
SELECT
    COUNT(*) AS TotalDocs,
    ISNULL(SUM(CAST(DATALENGTH(BinaryContent) AS BIGINT)), 0) / 1048576 AS TotalSizeMB,
    ISNULL(AVG(CAST(DATALENGTH(BinaryContent) AS BIGINT)), 0) / 1024 AS AvgSizeKB,
    ISNULL(MAX(CAST(DATALENGTH(BinaryContent) AS BIGINT)), 0) / 1048576 AS MaxSizeMB
"@

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- $($db.Label) [$($db.Name)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.Name -Query $sizeQuery

    if ($rows.Count -gt 0) {
        $row = $rows[0]
        Write-Host "  Documenti totali : $($row.TotalDocs)"
        Write-Host "  Dimensione totale: $($row.TotalSizeMB) MB"
        Write-Host "  Media per doc    : $($row.AvgSizeKB) KB"
        Write-Host "  Doc piu grande   : $($row.MaxSizeMB) MB"
    }
}

# =============================================================================
# SEZIONE 4: MAPPA DocNamespace -> Tipo ID in PrimaryKeyValue
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 4: MAPPA DocNamespace -> TIPO ID (PrimaryKeyValue)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$namespaceQuery = @"
SELECT
    DocNamespace,
    CASE
        WHEN CHARINDEX(':', PrimaryKeyValue) > 0
        THEN LEFT(PrimaryKeyValue, CHARINDEX(':', PrimaryKeyValue) - 1)
        ELSE '(nessun pattern)'
    END AS IdType,
    COUNT(*) AS Conteggio,
    MIN(PrimaryKeyValue) AS EsempioPKV
FROM dbo.DMS_ErpDocument
WHERE ISNULL(PrimaryKeyValue, '') != ''
GROUP BY
    DocNamespace,
    CASE
        WHEN CHARINDEX(':', PrimaryKeyValue) > 0
        THEN LEFT(PrimaryKeyValue, CHARINDEX(':', PrimaryKeyValue) - 1)
        ELSE '(nessun pattern)'
    END
ORDER BY DocNamespace, IdType
"@

$allNamespaces = @()

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- $($db.Label) [$($db.Name)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.Name -Query $namespaceQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host ("  {0,-60} | {1,-20} | {2,6} | es: {3}" -f $row.DocNamespace, $row.IdType, $row.Conteggio, $row.EsempioPKV)
            $allNamespaces += [PSCustomObject]@{
                Database     = $db.Name
                DocNamespace = [string]$row.DocNamespace
                IdType       = [string]$row.IdType
                Count        = [int]$row.Conteggio
                Example      = [string]$row.EsempioPKV
            }
        }
    }
    else {
        Write-Host "  (nessun record in DMS_ErpDocument)" -ForegroundColor DarkGray
    }
}

# =============================================================================
# SEZIONE 5: RIEPILOGO TIPI ID DISTINTI (cross-database)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 5: RIEPILOGO TIPI ID DISTINTI IN PrimaryKeyValue" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$distinctTypes = $allNamespaces | Group-Object -Property IdType | Sort-Object Name
foreach ($group in $distinctTypes) {
    $totalCount = ($group.Group | Measure-Object -Property Count -Sum).Sum
    $dbs = ($group.Group | Select-Object -ExpandProperty Database -Unique) -join ", "
    Write-Host ("  {0,-25} | {1,8} record | presente in: {2}" -f $group.Name, $totalCount, $dbs) -ForegroundColor Green
}

# =============================================================================
# SEZIONE 6: VERIFICA TAG_CrMaps SUI CLONI ERP
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 6: VERIFICA TAG_CrMaps SUI CLONI ERP" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$tagCrMapsQuery = @"
SELECT
    t.name AS TableName,
    p.[rows] AS NumRows
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE 'TAG_CrMaps%'
ORDER BY t.name
"@

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- Clone ERP: $($db.ErpClone) ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.ErpClone -Query $tagCrMapsQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host ("  {0,-30} : {1,8} righe" -f $row.TableName, $row.NumRows)
        }
    }
    else {
        Write-Host "  (nessuna TAG_CrMaps trovata)" -ForegroundColor Red
    }
}

# =============================================================================
# SEZIONE 7: STRUTTURA TAG_CrMaps (colonne + esempi)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 7: STRUTTURA TAG_CrMaps (prime tabelle trovate)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Controlliamo la struttura su gpxnetclone (il primo clone con TAG_CrMaps)
Write-Host "`n--- Struttura TAG_CrMaps su gpxnetclone ---" -ForegroundColor Yellow

$connStr = "Server=$ServerInstance;Database=gpxnetclone;User Id=$SqlUsername;Password=$SqlPassword;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connStr

try {
    $connection.Open()

    # Lista tabelle TAG_CrMaps
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = "SELECT t.name FROM sys.tables t WHERE t.name LIKE 'TAG_CrMaps%' ORDER BY t.name"
    $reader = $cmd.ExecuteReader()
    $tagTables = @()
    while ($reader.Read()) { $tagTables += $reader["name"] }
    $reader.Close()

    foreach ($tableName in $tagTables) {
        Write-Host "`n  Tabella: $tableName" -ForegroundColor White
        $cmd2 = New-Object System.Data.SqlClient.SqlCommand
        $cmd2.Connection = $connection
        $cmd2.CommandText = "SELECT c.name AS ColumnName, ty.name AS DataType FROM sys.columns c INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id WHERE c.object_id = OBJECT_ID('$tableName') ORDER BY c.column_id"
        $reader2 = $cmd2.ExecuteReader()
        while ($reader2.Read()) {
            Write-Host ("    {0,-20} {1}" -f $reader2["ColumnName"], $reader2["DataType"])
        }
        $reader2.Close()

        # Primi 3 record di esempio
        $cmd3 = New-Object System.Data.SqlClient.SqlCommand
        $cmd3.Connection = $connection
        $cmd3.CommandText = "SELECT TOP 3 * FROM [$tableName]"
        $reader3 = $cmd3.ExecuteReader()
        $first = $true
        while ($reader3.Read()) {
            if ($first) { Write-Host "    Esempi:" -ForegroundColor DarkGray; $first = $false }
            $vals = @()
            for ($i = 0; $i -lt $reader3.FieldCount; $i++) {
                $vals += "$($reader3.GetName($i))=$($reader3.GetValue($i))"
            }
            Write-Host "      $($vals -join ' | ')" -ForegroundColor DarkGray
        }
        $reader3.Close()
    }
}
catch {
    Write-Host "  ERRORE: $_" -ForegroundColor Red
}
finally {
    if ($connection.State -eq 'Open') { $connection.Close() }
}

# =============================================================================
# SEZIONE 8: VERIFICA PrimaryKeyValue con valori multipli (pattern complessi)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 8: ESEMPI PrimaryKeyValue PER NAMESPACE (primi 3 per tipo)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$examplesQuery = @"
SELECT TOP 3 ErpDocumentID, DocNamespace, PrimaryKeyValue
FROM dbo.DMS_ErpDocument
WHERE ISNULL(PrimaryKeyValue, '') != ''
ORDER BY ErpDocumentID
"@

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- $($db.Label) [$($db.Name)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.Name -Query $examplesQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host ("  ID={0,-8} | NS={1}" -f $row.ErpDocumentID, $row.DocNamespace)
            Write-Host ("             PKV={0}" -f $row.PrimaryKeyValue) -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "CENSIMENTO COMPLETATO" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "Usare i risultati per:" -ForegroundColor White
Write-Host "  1. Definire gli offset corretti per ogni ID" -ForegroundColor White
Write-Host "  2. Creare la mappa IdType -> TAG_CrMaps per aggiornare PrimaryKeyValue" -ForegroundColor White
Write-Host "  3. Stimare tempi di trasferimento binari" -ForegroundColor White
