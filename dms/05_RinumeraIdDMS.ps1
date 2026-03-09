# =============================================================================
# 05_RinumeraIdDMS.ps1 - FASE 2
# Rinumera gli ID interni DMS sui 3 cloni + VedMasterDMS
# Pattern: disabilita FK -> rinumera -> riabilita FK
# Le colonne IDENTITY vengono gestite con INSERT+DELETE (non UPDATE)
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Offset per ID interni DMS
$DmsClones = @(
    @{
        DmsDb = "gpxnetdmsclone"
        Label = "GPXNET"
        ArchivedDocID_Offset = 200000
        ErpDocumentID_Offset = 200000
        AttachmentID_Offset  = 200000
        SearchIndexID_Offset = 400000
    }
    @{
        DmsDb = "furmanetdmsclone"
        Label = "FURMANET"
        ArchivedDocID_Offset = 400000
        ErpDocumentID_Offset = 400000
        AttachmentID_Offset  = 400000
        SearchIndexID_Offset = 800000
    }
    @{
        DmsDb = "vedbondifedmsclone"
        Label = "VEDBONDIFE"
        ArchivedDocID_Offset = 600000
        ErpDocumentID_Offset = 600000
        AttachmentID_Offset  = 600000
        SearchIndexID_Offset = 1200000
    }
    @{
        DmsDb = "VedMasterDMS"
        Label = "VEDMASTERDMS"
        ArchivedDocID_Offset = 800000
        ErpDocumentID_Offset = 800000
        AttachmentID_Offset  = 800000
        SearchIndexID_Offset = 1600000
    }
)

Add-Type -AssemblyName System.Data

function Execute-SqlNonQuery {
    param([string]$Query, [string]$Database, [int]$Timeout = 0)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = $Timeout
        $result = $cmd.ExecuteNonQuery()
        return $result
    }
    catch {
        Write-Host "    ERRORE: $_" -ForegroundColor Red
        return -1
    }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

function Invoke-SqlQuery {
    param([string]$Query, [string]$Database)
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

function Get-TableColumns {
    param([string]$TableName, [string]$Database)
    $query = @"
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '$TableName' AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION
"@
    $rows = Invoke-SqlQuery -Query $query -Database $Database
    return ($rows | ForEach-Object { $_.COLUMN_NAME })
}

function Update-IdentityColumn {
    # Per colonne IDENTITY: INSERT nuovi record con ID offsettato, DELETE vecchi
    param(
        [string]$TableName,
        [string]$IdentityColumn,
        [int]$Offset,
        [string]$Database
    )

    # Ottieni tutte le colonne della tabella
    $columns = Get-TableColumns -TableName $TableName -Database $Database
    if (-not $columns -or $columns.Count -eq 0) {
        Write-Host "    ERRORE: impossibile ottenere colonne per $TableName" -ForegroundColor Red
        return -1
    }

    # Conta record da spostare
    $count = Invoke-SqlScalar -Query "SELECT COUNT(*) FROM dbo.[$TableName] WHERE [$IdentityColumn] > 0" -Database $Database
    if ($count -eq 0) {
        Write-Host "    $TableName.$IdentityColumn : 0 record (vuota)" -ForegroundColor DarkGray
        return 0
    }

    # Costruisci lista colonne per INSERT e SELECT
    $insertCols = ($columns | ForEach-Object { "[$_]" }) -join ", "
    $selectCols = ($columns | ForEach-Object {
        if ($_ -eq $IdentityColumn) {
            "[$_] + $Offset"
        } else {
            "[$_]"
        }
    }) -join ", "

    # Salva il MAX ID originale prima dell'insert
    $maxOriginalId = Invoke-SqlScalar -Query "SELECT ISNULL(MAX([$IdentityColumn]), 0) FROM dbo.[$TableName]" -Database $Database

    # INSERT con IDENTITY_INSERT ON
    $insertQuery = @"
SET IDENTITY_INSERT dbo.[$TableName] ON

INSERT INTO dbo.[$TableName] ($insertCols)
SELECT $selectCols
FROM dbo.[$TableName]
WHERE [$IdentityColumn] > 0

SET IDENTITY_INSERT dbo.[$TableName] OFF
"@

    $inserted = Execute-SqlNonQuery -Query $insertQuery -Database $Database
    if ($inserted -lt 0) {
        Write-Host "    $TableName.$IdentityColumn : INSERT FALLITO" -ForegroundColor Red
        # Tenta di spegnere IDENTITY_INSERT in caso di errore
        Execute-SqlNonQuery -Query "SET IDENTITY_INSERT dbo.[$TableName] OFF" -Database $Database | Out-Null
        return -1
    }

    # DELETE vecchi record (quelli con ID <= maxOriginalId)
    $deleteQuery = "DELETE FROM dbo.[$TableName] WHERE [$IdentityColumn] <= $maxOriginalId AND [$IdentityColumn] > 0"
    $deleted = Execute-SqlNonQuery -Query $deleteQuery -Database $Database
    if ($deleted -lt 0) {
        Write-Host "    $TableName.$IdentityColumn : DELETE vecchi record FALLITO" -ForegroundColor Red
        return -1
    }

    Write-Host "    $TableName.$IdentityColumn : $inserted record (IDENTITY INSERT+DELETE)" -ForegroundColor Green
    return $inserted
}

# =============================================================================
# FK da disabilitare/riabilitare
# =============================================================================
$DisableFKQuery = @"
ALTER TABLE dbo.DMS_ArchivedDocContent NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ArchivedDocTextContent NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ArchivedDocSearchIndexes NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ArchivedDocument NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_Attachment NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_AttachmentSearchIndexes NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ErpDocument NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ErpDocBarcodes NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_IndexesSynchronization NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_SearchFieldIndexes NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_SOSDocument NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_SOSEnvelope NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_Collection NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_CollectionsFields NOCHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_FieldProperties NOCHECK CONSTRAINT ALL
"@

$EnableFKQuery = @"
ALTER TABLE dbo.DMS_FieldProperties WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_CollectionsFields WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_Collection WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_SOSEnvelope WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_SOSDocument WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_SearchFieldIndexes WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_IndexesSynchronization WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ErpDocBarcodes WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ErpDocument WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_AttachmentSearchIndexes WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_Attachment WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ArchivedDocument WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ArchivedDocSearchIndexes WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ArchivedDocTextContent WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE dbo.DMS_ArchivedDocContent WITH CHECK CHECK CONSTRAINT ALL
"@

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "FASE 2: RINUMERAZIONE ID INTERNI DMS" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

foreach ($clone in $DmsClones) {
    $db = $clone.DmsDb
    Write-Host "`n$("=" * 60)" -ForegroundColor Yellow
    Write-Host "DATABASE: $db ($($clone.Label))" -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Yellow

    # STEP 1: Disabilita FK
    Write-Host "`n  [1/6] Disabilitazione FK..." -ForegroundColor White
    Execute-SqlNonQuery -Query $DisableFKQuery -Database $db | Out-Null
    Write-Host "    FK disabilitate" -ForegroundColor Green

    # STEP 2: Rinumera ArchivedDocID
    $offset = $clone.ArchivedDocID_Offset
    Write-Host "`n  [2/6] Rinumerazione ArchivedDocID (offset +$offset)..." -ForegroundColor White

    # Tabelle figlie: UPDATE normale (non hanno ArchivedDocID come identity)
    $childTables = @(
        "DMS_ArchivedDocContent",
        "DMS_ArchivedDocTextContent",
        "DMS_ArchivedDocSearchIndexes",
        "DMS_Attachment"
    )
    foreach ($t in $childTables) {
        $result = Execute-SqlNonQuery -Query "UPDATE dbo.[$t] SET [ArchivedDocID] = [ArchivedDocID] + $offset WHERE [ArchivedDocID] > 0" -Database $db
        Write-Host "    $t.ArchivedDocID : $result record" -ForegroundColor $(if ($result -ge 0) { "Green" } else { "Red" })
    }
    # Tabella principale: IDENTITY -> INSERT+DELETE
    Update-IdentityColumn -TableName "DMS_ArchivedDocument" -IdentityColumn "ArchivedDocID" -Offset $offset -Database $db

    # STEP 3: Rinumera ErpDocumentID
    $offset = $clone.ErpDocumentID_Offset
    Write-Host "`n  [3/6] Rinumerazione ErpDocumentID (offset +$offset)..." -ForegroundColor White

    $childTables = @(
        "DMS_Attachment",
        "DMS_ErpDocBarcodes",
        "DMS_IndexesSynchronization"
    )
    foreach ($t in $childTables) {
        $result = Execute-SqlNonQuery -Query "UPDATE dbo.[$t] SET [ErpDocumentID] = [ErpDocumentID] + $offset WHERE [ErpDocumentID] > 0" -Database $db
        Write-Host "    $t.ErpDocumentID : $result record" -ForegroundColor $(if ($result -ge 0) { "Green" } else { "Red" })
    }
    # Tabella principale: IDENTITY -> INSERT+DELETE
    Update-IdentityColumn -TableName "DMS_ErpDocument" -IdentityColumn "ErpDocumentID" -Offset $offset -Database $db

    # STEP 4: Rinumera AttachmentID
    $offset = $clone.AttachmentID_Offset
    Write-Host "`n  [4/6] Rinumerazione AttachmentID (offset +$offset)..." -ForegroundColor White

    $childTables = @(
        "DMS_AttachmentSearchIndexes",
        "DMS_SOSDocument"
    )
    foreach ($t in $childTables) {
        $result = Execute-SqlNonQuery -Query "UPDATE dbo.[$t] SET [AttachmentID] = [AttachmentID] + $offset WHERE [AttachmentID] > 0" -Database $db
        Write-Host "    $t.AttachmentID : $result record" -ForegroundColor $(if ($result -ge 0) { "Green" } else { "Red" })
    }
    # Tabella principale: IDENTITY -> INSERT+DELETE
    Update-IdentityColumn -TableName "DMS_Attachment" -IdentityColumn "AttachmentID" -Offset $offset -Database $db

    # STEP 5: Rinumera SearchIndexID
    $offset = $clone.SearchIndexID_Offset
    Write-Host "`n  [5/6] Rinumerazione SearchIndexID (offset +$offset)..." -ForegroundColor White

    $childTables = @(
        "DMS_ArchivedDocSearchIndexes",
        "DMS_AttachmentSearchIndexes"
    )
    foreach ($t in $childTables) {
        $result = Execute-SqlNonQuery -Query "UPDATE dbo.[$t] SET [SearchIndexID] = [SearchIndexID] + $offset WHERE [SearchIndexID] > 0" -Database $db
        Write-Host "    $t.SearchIndexID : $result record" -ForegroundColor $(if ($result -ge 0) { "Green" } else { "Red" })
    }
    # Tabella principale: IDENTITY -> INSERT+DELETE
    Update-IdentityColumn -TableName "DMS_SearchFieldIndexes" -IdentityColumn "SearchIndexID" -Offset $offset -Database $db

    # STEP 6: Riabilita FK
    Write-Host "`n  [6/6] Riabilitazione FK..." -ForegroundColor White
    $fkResult = Execute-SqlNonQuery -Query $EnableFKQuery -Database $db
    if ($fkResult -ge 0) {
        Write-Host "    FK riabilitate" -ForegroundColor Green
    } else {
        Write-Host "    ATTENZIONE: errore riabilitazione FK - verificare manualmente" -ForegroundColor Red
    }
}

Write-Host "`n"
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "FASE 2 COMPLETATA - ID interni DMS rinumerati" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
