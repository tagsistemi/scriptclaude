# =============================================================================
# 07_VerificaPostMigrazione.ps1 - FASE 4
# Verifiche di integrita post-migrazione su VedMasterDMS
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$TargetDB = "vedDMS"

$AllSources = @(
    @{ Db = "vedcontabdmsclone";  Label = "vedcontab" }
    @{ Db = "gpxnetdmsclone";     Label = "gpxnet" }
    @{ Db = "furmanetdmsclone";   Label = "furmanet" }
    @{ Db = "vedbondifedmsclone"; Label = "vedbondife" }
    @{ Db = "VedMasterDMS";       Label = "vedmasterdms" }
)

Add-Type -AssemblyName System.Data

function Invoke-SqlScalar {
    param([string]$Query, [string]$Database)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 300
        return $cmd.ExecuteScalar()
    }
    catch { Write-Host "    ERRORE: $_" -ForegroundColor Red; return $null }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

function Invoke-SqlQuery {
    param([string]$Database, [string]$Query)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    $results = @()
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 300
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $obj = @{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) { $obj[$reader.GetName($i)] = $reader.GetValue($i) }
            $results += [PSCustomObject]$obj
        }
        $reader.Close()
    }
    catch { Write-Host "    ERRORE: $_" -ForegroundColor Red }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
    return $results
}

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "FASE 4: VERIFICHE POST-MIGRAZIONE SU $TargetDB" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# =============================================================================
# VERIFICA 1: Conteggio record
# =============================================================================
Write-Host "`n--- VERIFICA 1: Conteggio record (target vs somma sorgenti) ---" -ForegroundColor Yellow

$dataTables = @(
    "DMS_ArchivedDocument", "DMS_ArchivedDocContent", "DMS_ArchivedDocTextContent",
    "DMS_ArchivedDocSearchIndexes", "DMS_ErpDocument", "DMS_Attachment",
    "DMS_AttachmentSearchIndexes", "DMS_SearchFieldIndexes", "DMS_ErpDocBarcodes"
)

$allOk = $true
foreach ($table in $dataTables) {
    $targetCount = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.[$table]" -Database $TargetDB
    $sourceSum = 0
    foreach ($src in $AllSources) {
        $c = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.[$table]" -Database $src.Db
        $sourceSum += [int]$c
    }

    $match = $targetCount -eq $sourceSum
    $color = if ($match) { "Green" } else { "Red" }
    $status = if ($match) { "OK" } else { "MISMATCH" }
    Write-Host ("  {0,-35} Target: {1,10} | Sorgenti: {2,10} | {3}" -f $table, $targetCount, $sourceSum, $status) -ForegroundColor $color
    if (-not $match) { $allOk = $false }
}

if ($allOk) {
    Write-Host "  TUTTI I CONTEGGI CORRISPONDONO" -ForegroundColor Green
}

# =============================================================================
# VERIFICA 2: Integrita FK (record orfani)
# =============================================================================
Write-Host "`n--- VERIFICA 2: Integrita FK (record orfani) ---" -ForegroundColor Yellow

$fkChecks = @(
    @{ Name = "ArchivedDocContent -> ArchivedDocument";
       Query = "SELECT COUNT(*) FROM dbo.DMS_ArchivedDocContent c WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_ArchivedDocument d WHERE d.ArchivedDocID = c.ArchivedDocID)" }
    @{ Name = "ArchivedDocTextContent -> ArchivedDocContent";
       Query = "SELECT COUNT(*) FROM dbo.DMS_ArchivedDocTextContent t WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_ArchivedDocContent c WHERE c.ArchivedDocID = t.ArchivedDocID)" }
    @{ Name = "Attachment -> ArchivedDocument";
       Query = "SELECT COUNT(*) FROM dbo.DMS_Attachment a WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_ArchivedDocument d WHERE d.ArchivedDocID = a.ArchivedDocID)" }
    @{ Name = "Attachment -> ErpDocument";
       Query = "SELECT COUNT(*) FROM dbo.DMS_Attachment a WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_ErpDocument e WHERE e.ErpDocumentID = a.ErpDocumentID)" }
    @{ Name = "AttachmentSearchIndexes -> Attachment";
       Query = "SELECT COUNT(*) FROM dbo.DMS_AttachmentSearchIndexes si WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_Attachment a WHERE a.AttachmentID = si.AttachmentID)" }
    @{ Name = "AttachmentSearchIndexes -> SearchFieldIndexes";
       Query = "SELECT COUNT(*) FROM dbo.DMS_AttachmentSearchIndexes si WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_SearchFieldIndexes sf WHERE sf.SearchIndexID = si.SearchIndexID)" }
    @{ Name = "ArchivedDocSearchIndexes -> ArchivedDocument";
       Query = "SELECT COUNT(*) FROM dbo.DMS_ArchivedDocSearchIndexes si WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_ArchivedDocument d WHERE d.ArchivedDocID = si.ArchivedDocID)" }
    @{ Name = "ArchivedDocSearchIndexes -> SearchFieldIndexes";
       Query = "SELECT COUNT(*) FROM dbo.DMS_ArchivedDocSearchIndexes si WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_SearchFieldIndexes sf WHERE sf.SearchIndexID = si.SearchIndexID)" }
    @{ Name = "ErpDocBarcodes -> ErpDocument";
       Query = "SELECT COUNT(*) FROM dbo.DMS_ErpDocBarcodes b WHERE NOT EXISTS (SELECT 1 FROM dbo.DMS_ErpDocument e WHERE e.ErpDocumentID = b.ErpDocumentID)" }
)

foreach ($check in $fkChecks) {
    $orphans = Invoke-SqlScalar -Query $check.Query -Database $TargetDB
    $color = if ([int]$orphans -eq 0) { "Green" } else { "Red" }
    $status = if ([int]$orphans -eq 0) { "OK" } else { "$orphans ORFANI" }
    Write-Host ("  {0,-50} {1}" -f $check.Name, $status) -ForegroundColor $color
}

# =============================================================================
# VERIFICA 3: Nessun ID duplicato
# =============================================================================
Write-Host "`n--- VERIFICA 3: Nessun ID duplicato ---" -ForegroundColor Yellow

$dupChecks = @(
    @{ Table = "DMS_ArchivedDocument"; PK = "ArchivedDocID" }
    @{ Table = "DMS_ErpDocument";      PK = "ErpDocumentID" }
    @{ Table = "DMS_Attachment";       PK = "AttachmentID" }
    @{ Table = "DMS_SearchFieldIndexes"; PK = "SearchIndexID" }
)

foreach ($check in $dupChecks) {
    $dups = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM (SELECT [$($check.PK)] FROM dbo.[$($check.Table)] GROUP BY [$($check.PK)] HAVING COUNT(*) > 1) sub" -Database $TargetDB
    $color = if ([int]$dups -eq 0) { "Green" } else { "Red" }
    $status = if ([int]$dups -eq 0) { "OK - nessun duplicato" } else { "$dups DUPLICATI" }
    Write-Host ("  {0,-35} {1}" -f "$($check.Table).$($check.PK)", $status) -ForegroundColor $color
}

# =============================================================================
# VERIFICA 4: Campione PrimaryKeyValue (spot check)
# =============================================================================
Write-Host "`n--- VERIFICA 4: Campione PrimaryKeyValue ---" -ForegroundColor Yellow

$sampleQuery = @"
SELECT TOP 5 ErpDocumentID, DocNamespace, PrimaryKeyValue
FROM dbo.DMS_ErpDocument
WHERE PrimaryKeyValue LIKE 'SaleDocId:%'
ORDER BY ErpDocumentID DESC
"@

$rows = Invoke-SqlQuery -Database $TargetDB -Query $sampleQuery
foreach ($row in $rows) {
    Write-Host ("  ID={0,-8} | NS={1}" -f $row.ErpDocumentID, $row.DocNamespace)
    Write-Host ("             PKV={0}" -f $row.PrimaryKeyValue) -ForegroundColor DarkGray
}

# =============================================================================
# VERIFICA 5: IDENTITY seed corretto
# =============================================================================
Write-Host "`n--- VERIFICA 5: IDENTITY seed ---" -ForegroundColor Yellow

$identityCheck = @(
    @{ Table = "DMS_ArchivedDocument"; PK = "ArchivedDocID" }
    @{ Table = "DMS_ErpDocument";      PK = "ErpDocumentID" }
    @{ Table = "DMS_Attachment";       PK = "AttachmentID" }
    @{ Table = "DMS_SearchFieldIndexes"; PK = "SearchIndexID" }
)

foreach ($check in $identityCheck) {
    $maxId = Invoke-SqlScalar -Query "SELECT ISNULL(MAX([$($check.PK)]), 0) FROM dbo.[$($check.Table)]" -Database $TargetDB
    $currentSeed = Invoke-SqlScalar -Query "SELECT IDENT_CURRENT('dbo.$($check.Table)')" -Database $TargetDB
    $ok = [int]$currentSeed -ge [int]$maxId
    $color = if ($ok) { "Green" } else { "Red" }
    Write-Host ("  {0,-35} MAX={1,10} | SEED={2,10} | {3}" -f "$($check.Table)", $maxId, $currentSeed, $(if ($ok) { "OK" } else { "SEED TROPPO BASSO" })) -ForegroundColor $color
}

# =============================================================================
# VERIFICA 6: Dimensione totale DB
# =============================================================================
Write-Host "`n--- VERIFICA 6: Dimensione $TargetDB ---" -ForegroundColor Yellow

$sizeQuery = @"
SELECT
    SUM(CAST(size AS BIGINT)) * 8 / 1024 AS SizeMB
FROM sys.master_files
WHERE database_id = DB_ID('$TargetDB')
"@
$sizeMB = Invoke-SqlScalar -Query $sizeQuery -Database "master"
$sizeGB = [math]::Round([int64]$sizeMB / 1024, 1)
Write-Host "  Dimensione allocata: $sizeMB MB ($sizeGB GB)" -ForegroundColor White

Write-Host "`n"
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "FASE 4 COMPLETATA - VERIFICHE ESEGUITE" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
