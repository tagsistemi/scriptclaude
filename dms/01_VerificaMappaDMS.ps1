# =============================================================================
# 01_VerificaMappaDMS.ps1
# Verifica corrispondenza IdType (PrimaryKeyValue) <-> DocumentType (TAG_CrMaps)
# + Fix query dimensione binari + verifica rimappatura Job
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername    = "sa"
$SqlPassword   = "stream"

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
# SEZIONE 1: DIMENSIONE BINARI (fix FROM mancante)
# =============================================================================
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 1: DIMENSIONE BINARI (DMS_ArchivedDocContent)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Prima verifichiamo il nome reale della colonna binaria
$colQuery = @"
SELECT c.name AS ColName
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.DMS_ArchivedDocContent')
ORDER BY c.column_id
"@

Write-Host "`n--- Colonne di DMS_ArchivedDocContent ---" -ForegroundColor Yellow
$cols = Invoke-SqlQuery -Database "vedcontabdms" -Query $colQuery
foreach ($col in $cols) {
    Write-Host "  $($col.ColName)"
}

# Query con nome colonna corretto (usiamo il nome dallo schema)
$binaryColName = ($cols | Where-Object { $_.ColName -like '*Content*' -or $_.ColName -like '*Binary*' } | Select-Object -First 1).ColName
if (-not $binaryColName) { $binaryColName = ($cols | Where-Object { $_.ColName -ne 'ArchivedDocID' -and $_.ColName -ne 'ExtensionType' -and $_.ColName -ne 'OCRProcess' } | Select-Object -First 1).ColName }

Write-Host "`n  Colonna binaria identificata: $binaryColName" -ForegroundColor Green

$sizeQuery = @"
SELECT
    COUNT(*) AS TotalDocs,
    ISNULL(SUM(CAST(DATALENGTH([$binaryColName]) AS BIGINT)), 0) / 1048576 AS TotalSizeMB,
    ISNULL(AVG(CAST(DATALENGTH([$binaryColName]) AS BIGINT)), 0) / 1024 AS AvgSizeKB,
    ISNULL(MAX(CAST(DATALENGTH([$binaryColName]) AS BIGINT)), 0) / 1048576 AS MaxSizeMB
FROM dbo.DMS_ArchivedDocContent
"@

$totalAllMB = 0
foreach ($db in $DmsDatabases) {
    Write-Host "`n--- $($db.Label) [$($db.Name)] ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.Name -Query $sizeQuery

    if ($rows.Count -gt 0) {
        $row = $rows[0]
        Write-Host "  Documenti totali : $($row.TotalDocs)"
        Write-Host "  Dimensione totale: $($row.TotalSizeMB) MB ($([math]::Round([int64]$row.TotalSizeMB / 1024, 1)) GB)"
        Write-Host "  Media per doc    : $($row.AvgSizeKB) KB"
        Write-Host "  Doc piu grande   : $($row.MaxSizeMB) MB"
        $totalAllMB += [int64]$row.TotalSizeMB
    }
}
Write-Host "`n  TOTALE COMPLESSIVO: $totalAllMB MB ($([math]::Round($totalAllMB / 1024, 1)) GB)" -ForegroundColor Green

# =============================================================================
# SEZIONE 2: DocumentType distinti in TAG_CrMaps per ogni clone
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 2: DocumentType DISTINTI IN TAG_CrMaps" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$docTypeQuery = @"
SELECT
    DocumentType,
    COUNT(*) AS NumRecords,
    MIN(OldId) AS MinOldId,
    MAX(OldId) AS MaxOldId,
    MIN(NewDocId) AS MinNewId,
    MAX(NewDocId) AS MaxNewId
FROM TAG_CrMaps
GROUP BY DocumentType
ORDER BY DocumentType
"@

$allDocTypes = @{}

foreach ($db in $DmsDatabases) {
    if ($db.ErpClone -eq "vedcontab") { continue } # base, no TAG_CrMaps

    Write-Host "`n--- Clone ERP: $($db.ErpClone) ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.ErpClone -Query $docTypeQuery

    foreach ($row in $rows) {
        $dt = [int]$row.DocumentType
        Write-Host ("  DocumentType={0,-12} | {1,8} record | OldId: {2,8}-{3,8} | NewId: {4,8}-{5,8}" -f `
            $dt, $row.NumRecords, $row.MinOldId, $row.MaxOldId, $row.MinNewId, $row.MaxNewId)
        if (-not $allDocTypes.ContainsKey($dt)) { $allDocTypes[$dt] = @() }
        $allDocTypes[$dt] += $db.ErpClone
    }
}

# =============================================================================
# SEZIONE 3: Verifica TAG_DocumentTypesCr (mappa enum da script 18)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 3: TAG_DocumentTypesCr (mappa enum da script 18)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$tagDocTypesQuery = @"
IF OBJECT_ID('TAG_DocumentTypesCr', 'U') IS NOT NULL
    SELECT * FROM TAG_DocumentTypesCr ORDER BY EnumValue
ELSE
    SELECT 'TABELLA NON TROVATA' AS Messaggio
"@

foreach ($db in $DmsDatabases) {
    if ($db.ErpClone -eq "vedcontab") { continue }

    Write-Host "`n--- Clone ERP: $($db.ErpClone) ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.ErpClone -Query $tagDocTypesQuery

    if ($rows.Count -gt 0 -and $rows[0].PSObject.Properties.Name -contains "Messaggio") {
        Write-Host "  $($rows[0].Messaggio)" -ForegroundColor Red
    }
    elseif ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            $props = $row.PSObject.Properties
            $vals = ($props | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join " | "
            Write-Host "  $vals"
        }
    }
    # Proviamo solo sul primo clone trovato
    break
}

# =============================================================================
# SEZIONE 4: Cercare tabelle di rimappatura Job e altri mapping
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 4: TABELLE DI RIMAPPATURA (Job, Item, ecc.)" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$mappingTablesQuery = @"
SELECT t.name AS TableName, p.[rows] AS NumRows
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE 'TAG_%' OR t.name LIKE 'MM4_%' OR t.name LIKE '%Mappa%' OR t.name LIKE '%Map%'
ORDER BY t.name
"@

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- Clone ERP: $($db.ErpClone) ---" -ForegroundColor Yellow
    $rows = Invoke-SqlQuery -Database $db.ErpClone -Query $mappingTablesQuery

    if ($rows.Count -gt 0) {
        foreach ($row in $rows) {
            Write-Host ("  {0,-40} : {1,8} righe" -f $row.TableName, $row.NumRows)
        }
    }
    else {
        Write-Host "  (nessuna tabella di mapping trovata)" -ForegroundColor DarkGray
    }
}

# =============================================================================
# SEZIONE 5: Struttura MM4_MappaJobsCodes (se esiste)
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 5: STRUTTURA E DATI MM4_MappaJobsCodes" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$jobMapQuery = @"
IF OBJECT_ID('MM4_MappaJobsCodes', 'U') IS NOT NULL
BEGIN
    SELECT 'STRUTTURA' AS Tipo, c.name AS Info1, ty.name AS Info2, '' AS Info3, '' AS Info4
    FROM sys.columns c
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE c.object_id = OBJECT_ID('MM4_MappaJobsCodes')
    ORDER BY c.column_id
END
ELSE
    SELECT 'NON TROVATA' AS Tipo, '' AS Info1, '' AS Info2, '' AS Info3, '' AS Info4
"@

$jobMapSampleQuery = @"
IF OBJECT_ID('MM4_MappaJobsCodes', 'U') IS NOT NULL
    SELECT TOP 5 * FROM MM4_MappaJobsCodes
"@

foreach ($db in $DmsDatabases) {
    Write-Host "`n--- Clone ERP: $($db.ErpClone) ---" -ForegroundColor Yellow

    $rows = Invoke-SqlQuery -Database $db.ErpClone -Query $jobMapQuery
    if ($rows.Count -gt 0 -and $rows[0].Tipo -eq "NON TROVATA") {
        Write-Host "  MM4_MappaJobsCodes non trovata" -ForegroundColor DarkGray
        continue
    }

    Write-Host "  Struttura:" -ForegroundColor White
    foreach ($row in $rows) {
        Write-Host ("    {0,-20} {1}" -f $row.Info1, $row.Info2)
    }

    $samples = Invoke-SqlQuery -Database $db.ErpClone -Query $jobMapSampleQuery
    if ($samples.Count -gt 0) {
        Write-Host "  Esempi:" -ForegroundColor DarkGray
        foreach ($row in $samples) {
            $props = $row.PSObject.Properties
            $vals = ($props | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join " | "
            Write-Host "    $vals" -ForegroundColor DarkGray
        }
    }
}

# =============================================================================
# SEZIONE 6: Tentativo di mappatura IdType <-> DocumentType
# =============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "SEZIONE 6: CROSS-CHECK IdType <-> DocumentType" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Per ogni IdType trovato nel DMS, cerchiamo un match nel TAG_CrMaps
# confrontando i valori OldId con i valori nel PrimaryKeyValue

$crossCheckTypes = @(
    @{ IdType = "SaleDocId";          TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
    @{ IdType = "PurchaseOrdId";      TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
    @{ IdType = "PurchaseDocId";      TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
    @{ IdType = "CustQuotaId";        TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
    @{ IdType = "SaleOrdId";          TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
    @{ IdType = "SuppQuotaId";        TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
    @{ IdType = "WorkingReportId";    TestDb = "furmanetdms"; ErpClone = "furmanetclone" }
    @{ IdType = "JobQuotationId";     TestDb = "furmanetdms"; ErpClone = "furmanetclone" }
    @{ IdType = "MeasuresBookId";     TestDb = "furmanetdms"; ErpClone = "furmanetclone" }
    @{ IdType = "QuotationRequestId"; TestDb = "furmanetdms"; ErpClone = "furmanetclone" }
    @{ IdType = "PurchaseRequestId";  TestDb = "furmanetdms"; ErpClone = "furmanetclone" }
    @{ IdType = "EntryId";            TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
    @{ IdType = "IdRam";              TestDb = "gpxnetdms"; ErpClone = "gpxnetclone" }
)

foreach ($check in $crossCheckTypes) {
    Write-Host "`n  IdType: $($check.IdType)" -ForegroundColor White

    # Prendi un esempio di valore dal DMS
    $sampleQuery = @"
SELECT TOP 1
    PrimaryKeyValue,
    CASE
        WHEN CHARINDEX(';', PrimaryKeyValue, CHARINDEX(':', PrimaryKeyValue) + 1) > 0
        THEN SUBSTRING(
            PrimaryKeyValue,
            CHARINDEX(':', PrimaryKeyValue) + 1,
            CHARINDEX(';', PrimaryKeyValue, CHARINDEX(':', PrimaryKeyValue) + 1) - CHARINDEX(':', PrimaryKeyValue) - 1
        )
        ELSE ''
    END AS ExtractedId
FROM dbo.DMS_ErpDocument
WHERE PrimaryKeyValue LIKE '$($check.IdType):%'
  AND PrimaryKeyValue NOT LIKE '%:%:%'
"@

    $samples = Invoke-SqlQuery -Database $check.TestDb -Query $sampleQuery
    if ($samples.Count -eq 0) {
        # Prova anche con pattern multi-chiave
        $sampleQuery2 = @"
SELECT TOP 1 PrimaryKeyValue,
    SUBSTRING(
        PrimaryKeyValue,
        CHARINDEX(':', PrimaryKeyValue) + 1,
        CHARINDEX(';', PrimaryKeyValue) - CHARINDEX(':', PrimaryKeyValue) - 1
    ) AS ExtractedId
FROM dbo.DMS_ErpDocument
WHERE PrimaryKeyValue LIKE '$($check.IdType):%'
"@
        $samples = Invoke-SqlQuery -Database $check.TestDb -Query $sampleQuery2
    }

    if ($samples.Count -gt 0) {
        $extractedId = $samples[0].ExtractedId
        $pkv = $samples[0].PrimaryKeyValue
        Write-Host "    PKV esempio: $pkv -> ID estratto: $extractedId"

        # Cerca questo ID in TAG_CrMaps
        if ($extractedId -match '^\d+$') {
            $findQuery = @"
SELECT DocumentType, OldId, NewDocId
FROM TAG_CrMaps
WHERE OldId = $extractedId
"@
            $matches = Invoke-SqlQuery -Database $check.ErpClone -Query $findQuery
            if ($matches.Count -gt 0) {
                foreach ($m in $matches) {
                    Write-Host "    MATCH in TAG_CrMaps: DocumentType=$($m.DocumentType) | OldId=$($m.OldId) -> NewDocId=$($m.NewDocId)" -ForegroundColor Green
                }
            }
            else {
                Write-Host "    NESSUN MATCH in TAG_CrMaps per OldId=$extractedId" -ForegroundColor Red
            }
        }
        else {
            Write-Host "    ID non numerico ('$extractedId') - non cercato in TAG_CrMaps" -ForegroundColor DarkYellow
        }
    }
    else {
        Write-Host "    Nessun esempio trovato in $($check.TestDb)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "VERIFICA COMPLETATA" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
