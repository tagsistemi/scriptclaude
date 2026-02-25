# ============================================
# SCRIPT 29a: Creazione MA_CrossReferencesOrigin su VEDMaster
# ============================================
# Prerequisito per lo script 29CorrettivoFixDerivedDocIdFatture.ps1
#
# Crea la tabella MA_CrossReferencesOrigin su VEDMaster
# e la popola con i cross-references originali letti da VedContab.
# ============================================

$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"

$connString = "Server=$serverName;Database=VEDMaster;User ID=$userName;Password=$password;"

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
    param ([string]$query, [string]$connString)
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
        Write-Host "Errore: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return $null
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Creazione MA_CrossReferencesOrigin" -ForegroundColor Cyan
Write-Host "  da VedContab -> VEDMaster" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verifica che VedContab sia raggiungibile
$vedcontabCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM VedContab.dbo.MA_CrossReferences" -connString $connString
if ($null -eq $vedcontabCount) {
    Write-Host "ERRORE: impossibile leggere VedContab.dbo.MA_CrossReferences" -ForegroundColor Red
    exit
}
Write-Host "  Record in VedContab.dbo.MA_CrossReferences: $vedcontabCount" -ForegroundColor White

# Drop + Create
Write-Host ""
Write-Host "  Creazione tabella MA_CrossReferencesOrigin..." -ForegroundColor Yellow
Execute-SqlNonQuery -query @"
IF OBJECT_ID('VEDMaster.dbo.MA_CrossReferencesOrigin') IS NOT NULL
    DROP TABLE VEDMaster.dbo.MA_CrossReferencesOrigin;

CREATE TABLE VEDMaster.dbo.MA_CrossReferencesOrigin (
    [OriginDocType]  [int]      NOT NULL,
    [OriginDocID]    [int]      NOT NULL,
    [OriginDocSubID] [int]      NOT NULL,
    [DerivedDocType] [int]      NOT NULL,
    [DerivedDocID]   [int]      NOT NULL,
    [DerivedDocSubID][int]      NOT NULL,
    [Manual]         [char](1)  NULL,
    [TBCreated]      [datetime] NOT NULL,
    [TBModified]     [datetime] NOT NULL,
    [TBCreatedID]    [int]      NOT NULL,
    [TBModifiedID]   [int]      NOT NULL,
    [OriginDocLine]  [smallint] NOT NULL,
    [DerivedDocLine] [smallint] NOT NULL
);
"@ -connString $connString `
    -msgOk "  Tabella creata" `
    -msgErr "  Errore creazione tabella"

# Popolamento da VedContab
Write-Host ""
Write-Host "  Popolamento da VedContab.dbo.MA_CrossReferences..." -ForegroundColor Yellow
Execute-SqlNonQuery -query @"
INSERT INTO VEDMaster.dbo.MA_CrossReferencesOrigin
    (OriginDocType, OriginDocID, OriginDocSubID,
     DerivedDocType, DerivedDocID, DerivedDocSubID,
     [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID,
     OriginDocLine, DerivedDocLine)
SELECT
    OriginDocType, OriginDocID, OriginDocSubID,
    DerivedDocType, DerivedDocID, DerivedDocSubID,
    [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID,
    OriginDocLine, DerivedDocLine
FROM VedContab.dbo.MA_CrossReferences
"@ -connString $connString `
    -msgOk "  Popolamento completato" `
    -msgErr "  Errore popolamento"

# Verifica
$finalCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM VEDMaster.dbo.MA_CrossReferencesOrigin" -connString $connString
Write-Host ""
Write-Host "  Record copiati: $finalCount (attesi: $vedcontabCount)" -ForegroundColor $(if ($finalCount -eq $vedcontabCount) { "Green" } else { "Red" })

# ============================================
# BACKUP MA_CrossReferences attuale di VEDMaster
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Backup MA_CrossReferences di VEDMaster" -ForegroundColor Cyan
Write-Host "  -> MA_CrossReferencesBackup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$vedmasterCRCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM VEDMaster.dbo.MA_CrossReferences" -connString $connString
Write-Host "  Record in VEDMaster.dbo.MA_CrossReferences: $vedmasterCRCount" -ForegroundColor White

Write-Host ""
Write-Host "  Creazione tabella MA_CrossReferencesBackup..." -ForegroundColor Yellow
Execute-SqlNonQuery -query @"
IF OBJECT_ID('VEDMaster.dbo.MA_CrossReferencesBackup') IS NOT NULL
    DROP TABLE VEDMaster.dbo.MA_CrossReferencesBackup;

CREATE TABLE VEDMaster.dbo.MA_CrossReferencesBackup (
    [OriginDocType]  [int]      NOT NULL,
    [OriginDocID]    [int]      NOT NULL,
    [OriginDocSubID] [int]      NOT NULL,
    [DerivedDocType] [int]      NOT NULL,
    [DerivedDocID]   [int]      NOT NULL,
    [DerivedDocSubID][int]      NOT NULL,
    [Manual]         [char](1)  NULL,
    [TBCreated]      [datetime] NOT NULL,
    [TBModified]     [datetime] NOT NULL,
    [TBCreatedID]    [int]      NOT NULL,
    [TBModifiedID]   [int]      NOT NULL,
    [OriginDocLine]  [smallint] NOT NULL,
    [DerivedDocLine] [smallint] NOT NULL
);
"@ -connString $connString `
    -msgOk "  Tabella backup creata" `
    -msgErr "  Errore creazione tabella backup"

Write-Host ""
Write-Host "  Popolamento backup da VEDMaster.dbo.MA_CrossReferences..." -ForegroundColor Yellow
Execute-SqlNonQuery -query @"
INSERT INTO VEDMaster.dbo.MA_CrossReferencesBackup
    (OriginDocType, OriginDocID, OriginDocSubID,
     DerivedDocType, DerivedDocID, DerivedDocSubID,
     [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID,
     OriginDocLine, DerivedDocLine)
SELECT
    OriginDocType, OriginDocID, OriginDocSubID,
    DerivedDocType, DerivedDocID, DerivedDocSubID,
    [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID,
    OriginDocLine, DerivedDocLine
FROM VEDMaster.dbo.MA_CrossReferences
"@ -connString $connString `
    -msgOk "  Backup completato" `
    -msgErr "  Errore backup"

$backupCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM VEDMaster.dbo.MA_CrossReferencesBackup" -connString $connString
Write-Host ""
Write-Host "  Record nel backup: $backupCount (attesi: $vedmasterCRCount)" -ForegroundColor $(if ($backupCount -eq $vedmasterCRCount) { "Green" } else { "Red" })

# ============================================
# RIEPILOGO
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RIEPILOGO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  MA_CrossReferencesOrigin (da VedContab):  $finalCount record" -ForegroundColor White
Write-Host "  MA_CrossReferencesBackup (da VEDMaster):  $backupCount record" -ForegroundColor White
Write-Host ""
Write-Host "Operazione completata! Ora puoi eseguire 29CorrettivoFixDerivedDocIdFatture.ps1" -ForegroundColor Green
