# =============================================================================
# 06_TrasferisciInVedMasterDMS.ps1 - FASE 3
# Trasferisce i dati dai 4 cloni DMS in VedMasterDMS
# Ordine: Config (solo base) -> SearchIndexes -> Docs -> ERP -> Attachments
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$TargetDB = "vedDMS"

$BaseClone = "vedcontabdmsclone"
$AllClones = @("vedcontabdmsclone", "gpxnetdmsclone", "furmanetdmsclone", "vedbondifedmsclone", "VedMasterDMS")

Add-Type -AssemblyName System.Data

function Execute-SqlNonQuery {
    param([string]$Query, [string]$Database)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 0  # No timeout per trasferimenti grossi
        $result = $cmd.ExecuteNonQuery()
        return $result
    }
    catch {
        Write-Host "    ERRORE: $_" -ForegroundColor Red
        return -1
    }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

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

function Transfer-Table {
    param(
        [string]$SourceDB,
        [string]$TableName,
        [string]$Columns,
        [bool]$UseIdentityInsert = $false
    )

    $countBefore = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.[$TableName]" -Database $TargetDB
    $countSource = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.[$TableName]" -Database $SourceDB

    if ($countSource -eq 0) {
        Write-Host "      $SourceDB : 0 record - skip" -ForegroundColor DarkGray
        return 0
    }

    $identityOn = ""
    $identityOff = ""
    if ($UseIdentityInsert) {
        $identityOn = "SET IDENTITY_INSERT [$TargetDB].dbo.[$TableName] ON; "
        $identityOff = " SET IDENTITY_INSERT [$TargetDB].dbo.[$TableName] OFF;"
    }

    $insertQuery = "${identityOn}INSERT INTO [$TargetDB].dbo.[$TableName] ($Columns) SELECT $Columns FROM [$SourceDB].dbo.[$TableName];${identityOff}"

    $result = Execute-SqlNonQuery -Query $insertQuery -Database "master"
    $color = if ($result -ge 0) { "Green" } else { "Red" }
    Write-Host "      $SourceDB : $result record inseriti" -ForegroundColor $color
    return $result
}

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "FASE 3: TRASFERIMENTO DATI IN $TargetDB" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# =============================================================================
# STEP 0: Disabilita FK su VedMasterDMS
# =============================================================================
Write-Host "`n--- STEP 0: Disabilitazione FK su $TargetDB ---" -ForegroundColor Yellow

$disableAllFK = @"
EXEC sp_MSforeachtable @command1='ALTER TABLE ? NOCHECK CONSTRAINT ALL', @whereand='AND SCHEMA_NAME(schema_id) = ''dbo'''
"@
Execute-SqlNonQuery -Query $disableAllFK -Database $TargetDB | Out-Null
Write-Host "  FK disabilitate" -ForegroundColor Green

# =============================================================================
# STEP 1: Svuota tabelle dati su VedMasterDMS (preserva struttura)
# =============================================================================
Write-Host "`n--- STEP 1: Pulizia tabelle dati su $TargetDB ---" -ForegroundColor Yellow

$tablesToClean = @(
    "DMS_AttachmentSearchIndexes",
    "DMS_ArchivedDocSearchIndexes",
    "DMS_ArchivedDocTextContent",
    "DMS_ArchivedDocContent",
    "DMS_ErpDocBarcodes",
    "DMS_IndexesSynchronization",
    "DMS_SOSDocument",
    "DMS_Attachment",
    "DMS_ArchivedDocument",
    "DMS_ErpDocument",
    "DMS_SearchFieldIndexes",
    "DMS_SOSEnvelope",
    "DMS_DocumentToArchive",
    "DMS_CollectionsFields",
    "DMS_FieldProperties",
    "DMS_Collection",
    "DMS_Collector",
    "DMS_Field",
    "DMS_Settings"
)

foreach ($table in $tablesToClean) {
    $count = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.[$table]" -Database $TargetDB
    if ($count -gt 0) {
        Execute-SqlNonQuery -Query "DELETE FROM dbo.[$table]" -Database $TargetDB | Out-Null
        Write-Host "  $table : $count record rimossi" -ForegroundColor White
    }
}
Write-Host "  Pulizia completata" -ForegroundColor Green

# =============================================================================
# STEP 2: Tabelle di configurazione (solo da vedcontabdmsclone)
# =============================================================================
Write-Host "`n--- STEP 2: Configurazione (solo da $BaseClone) ---" -ForegroundColor Yellow

Write-Host "  DMS_Field:" -ForegroundColor White
# MERGE: prendi tutti i Field da tutti i cloni (furmanet/vedbondife ne hanno di piu)
foreach ($clone in $AllClones) {
    $mergeQuery = @"
INSERT INTO [$TargetDB].dbo.DMS_Field (FieldName, FieldDescription, ValueType, IsCategory)
SELECT s.FieldName, s.FieldDescription, s.ValueType, s.IsCategory
FROM [$clone].dbo.DMS_Field s
WHERE NOT EXISTS (SELECT 1 FROM [$TargetDB].dbo.DMS_Field t WHERE t.FieldName = s.FieldName)
"@
    $result = Execute-SqlNonQuery -Query $mergeQuery -Database "master"
    Write-Host "      $clone : $result nuovi Field" -ForegroundColor Green
}

Write-Host "  DMS_FieldProperties:" -ForegroundColor White
foreach ($clone in $AllClones) {
    $mergeQuery = @"
INSERT INTO [$TargetDB].dbo.DMS_FieldProperties (FieldName, XMLValues, FieldColor, Disabled)
SELECT s.FieldName, s.XMLValues, s.FieldColor, s.Disabled
FROM [$clone].dbo.DMS_FieldProperties s
WHERE NOT EXISTS (SELECT 1 FROM [$TargetDB].dbo.DMS_FieldProperties t WHERE t.FieldName = s.FieldName)
"@
    $result = Execute-SqlNonQuery -Query $mergeQuery -Database "master"
    Write-Host "      $clone : $result nuovi FieldProperties" -ForegroundColor Green
}

$configTables = @(
    @{ Table = "DMS_Collector"; Cols = "CollectorID, Name, IsStandard"; Identity = $true }
    @{ Table = "DMS_Collection"; Cols = "CollectionID, IsStandard, CollectorID, Name, TemplateName, SosDocClass, Version"; Identity = $true }
    @{ Table = "DMS_CollectionsFields"; Cols = "FieldName, CollectionID, ControlName, OCRPosition, PhysicalName, FieldGroup, ShowAsDescription, Disabled, SosPosition, HKLName, SosMandatory, SosKeyCode"; Identity = $false }
    @{ Table = "DMS_Settings"; Cols = "WorkerID, SettingType, Settings"; Identity = $false }
)

foreach ($cfg in $configTables) {
    Write-Host "  $($cfg.Table):" -ForegroundColor White
    Transfer-Table -SourceDB $BaseClone -TableName $cfg.Table -Columns $cfg.Cols -UseIdentityInsert $cfg.Identity
}

# =============================================================================
# STEP 3: DMS_SearchFieldIndexes (da tutti e 4, con IDENTITY_INSERT)
# =============================================================================
Write-Host "`n--- STEP 3: DMS_SearchFieldIndexes (da tutti e 4) ---" -ForegroundColor Yellow

$searchCols = "SearchIndexID, FieldName, FieldValue, FormattedValue"
foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_SearchFieldIndexes" -Columns $searchCols -UseIdentityInsert $true
}

# =============================================================================
# STEP 4: Documenti archiviati (da tutti e 4)
# =============================================================================
Write-Host "`n--- STEP 4: DMS_ArchivedDocument (da tutti e 4) ---" -ForegroundColor Yellow

$archDocCols = "ArchivedDocID, Language, Name, Description, ExtensionType, StorageType, Path, CreationTimeUtc, LastWriteTimeUtc, CRC, Size, TBCreatedID, TBModifiedID, TBCreated, TBModified, IsWoormReport, CollectionID, ModifierID, Barcode, BarcodeType"
foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_ArchivedDocument" -Columns $archDocCols -UseIdentityInsert $true
}

# =============================================================================
# STEP 5: Contenuto binario (ATTENZIONE: ~147 GB)
# Trasferimento batch per evitare timeout
# =============================================================================
Write-Host "`n--- STEP 5: DMS_ArchivedDocContent (~147 GB, batch) ---" -ForegroundColor Yellow

$batchSize = 5000

foreach ($clone in $AllClones) {
    $totalCount = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.DMS_ArchivedDocContent" -Database $clone
    if ($totalCount -eq 0) {
        Write-Host "      $clone : 0 record - skip" -ForegroundColor DarkGray
        continue
    }

    Write-Host "      $clone : $totalCount record da trasferire..." -ForegroundColor White
    $transferred = 0
    $minId = 0

    while ($transferred -lt $totalCount) {
        $batchQuery = @"
INSERT INTO [$TargetDB].dbo.DMS_ArchivedDocContent (ArchivedDocID, BinaryContent, ExtensionType, OCRProcess)
SELECT TOP $batchSize ArchivedDocID, BinaryContent, ExtensionType, OCRProcess
FROM [$clone].dbo.DMS_ArchivedDocContent
WHERE ArchivedDocID > $minId
ORDER BY ArchivedDocID;
"@
        # Trova il max ID del batch corrente per il prossimo ciclo
        $maxIdQuery = @"
SELECT MAX(ArchivedDocID) FROM (
    SELECT TOP $batchSize ArchivedDocID
    FROM [$clone].dbo.DMS_ArchivedDocContent
    WHERE ArchivedDocID > $minId
    ORDER BY ArchivedDocID
) sub
"@
        $nextMaxId = Invoke-SqlScalar -Query $maxIdQuery -Database $clone
        if ($nextMaxId -eq $null) { break }

        $result = Execute-SqlNonQuery -Query $batchQuery -Database "master"
        if ($result -lt 0) { Write-Host "    ERRORE nel batch, interruzione" -ForegroundColor Red; break }

        $transferred += $result
        $minId = $nextMaxId
        $pct = [math]::Round(($transferred / $totalCount) * 100, 1)
        Write-Host "        Batch: $transferred / $totalCount ($pct%)" -ForegroundColor DarkGray
    }
    Write-Host "      $clone : $transferred record trasferiti" -ForegroundColor Green
}

# =============================================================================
# STEP 6: ArchivedDocTextContent (da tutti e 4)
# =============================================================================
Write-Host "`n--- STEP 6: DMS_ArchivedDocTextContent (da tutti e 4) ---" -ForegroundColor Yellow

foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_ArchivedDocTextContent" -Columns "ArchivedDocID, TextContent" -UseIdentityInsert $false
}

# =============================================================================
# STEP 7: ArchivedDocSearchIndexes (da tutti e 4)
# =============================================================================
Write-Host "`n--- STEP 7: DMS_ArchivedDocSearchIndexes (da tutti e 4) ---" -ForegroundColor Yellow

foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_ArchivedDocSearchIndexes" -Columns "ArchivedDocID, SearchIndexID" -UseIdentityInsert $false
}

# =============================================================================
# STEP 8: ErpDocument (da tutti e 4)
# =============================================================================
Write-Host "`n--- STEP 8: DMS_ErpDocument (da tutti e 4) ---" -ForegroundColor Yellow

$erpDocCols = "ErpDocumentID, DocNamespace, PrimaryKeyValue, DescriptionValue, TBGuid"
foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_ErpDocument" -Columns $erpDocCols -UseIdentityInsert $true
}

# =============================================================================
# STEP 9: Attachment (da tutti e 4)
# =============================================================================
Write-Host "`n--- STEP 9: DMS_Attachment (da tutti e 4) ---" -ForegroundColor Yellow

$attCols = "AttachmentID, ErpDocumentID, CollectionID, ArchivedDocID, TBCreatedID, TBModifiedID, TBCreated, TBModified, IsMainDoc, Description, AbsoluteCode, LotID, RegistrationDate"
foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_Attachment" -Columns $attCols -UseIdentityInsert $true
}

# =============================================================================
# STEP 10: AttachmentSearchIndexes (da tutti e 4)
# =============================================================================
Write-Host "`n--- STEP 10: DMS_AttachmentSearchIndexes (da tutti e 4) ---" -ForegroundColor Yellow

foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_AttachmentSearchIndexes" -Columns "AttachmentID, SearchIndexID" -UseIdentityInsert $false
}

# =============================================================================
# STEP 11: ErpDocBarcodes (solo furmanet ha 16 record)
# =============================================================================
Write-Host "`n--- STEP 11: DMS_ErpDocBarcodes ---" -ForegroundColor Yellow

foreach ($clone in $AllClones) {
    Transfer-Table -SourceDB $clone -TableName "DMS_ErpDocBarcodes" -Columns "Barcode, BarcodeType, Notes, Name, ErpDocumentID" -UseIdentityInsert $false
}

# =============================================================================
# STEP 12: Riabilita FK su VedMasterDMS
# =============================================================================
Write-Host "`n--- STEP 12: Riabilitazione FK su $TargetDB ---" -ForegroundColor Yellow

$enableAllFK = @"
EXEC sp_MSforeachtable @command1='ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL', @whereand='AND SCHEMA_NAME(schema_id) = ''dbo'''
"@
Execute-SqlNonQuery -Query $enableAllFK -Database $TargetDB | Out-Null
Write-Host "  FK riabilitate" -ForegroundColor Green

# =============================================================================
# STEP 13: Aggiorna IDENTITY seed
# =============================================================================
Write-Host "`n--- STEP 13: Aggiornamento IDENTITY seed ---" -ForegroundColor Yellow

$identityTables = @(
    "DMS_ArchivedDocument",
    "DMS_ErpDocument",
    "DMS_Attachment",
    "DMS_SearchFieldIndexes",
    "DMS_Collection",
    "DMS_Collector",
    "DMS_SOSEnvelope"
)

foreach ($table in $identityTables) {
    Execute-SqlNonQuery -Query "DBCC CHECKIDENT ('dbo.$table', RESEED)" -Database $TargetDB | Out-Null
    Write-Host "  $table : IDENTITY reseed" -ForegroundColor Green
}

Write-Host "`n"
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "FASE 3 COMPLETATA - Dati trasferiti in $TargetDB" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
