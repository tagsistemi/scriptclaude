# ============================================
# SCRIPT 29b: Ripristino MA_CrossReferences da Backup
# ============================================
# Ripristina VEDMaster.dbo.MA_CrossReferences
# dalla copia MA_CrossReferencesBackup creata dallo script 29a.
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
Write-Host "  RIPRISTINO MA_CrossReferences da Backup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verifica che il backup esista
$backupExists = Execute-SqlScalar -query "SELECT COUNT(*) FROM VEDMaster.sys.objects WHERE object_id = OBJECT_ID(N'VEDMaster.dbo.MA_CrossReferencesBackup') AND type = 'U'" -connString $connString
if ($backupExists -eq 0) {
    Write-Host "ERRORE: MA_CrossReferencesBackup non trovata su VEDMaster!" -ForegroundColor Red
    Write-Host "Esegui prima 29a_CreaMA_CrossReferencesOrigin.ps1 per creare il backup." -ForegroundColor Yellow
    exit
}

$backupCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM VEDMaster.dbo.MA_CrossReferencesBackup" -connString $connString
$currentCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM VEDMaster.dbo.MA_CrossReferences" -connString $connString

Write-Host "  Record nel backup:  $backupCount" -ForegroundColor White
Write-Host "  Record attuali:     $currentCount" -ForegroundColor White
Write-Host ""

# Svuota e ripopola
Write-Host "  Svuotamento MA_CrossReferences..." -ForegroundColor Yellow
Execute-SqlNonQuery -query "DELETE FROM VEDMaster.dbo.MA_CrossReferences" -connString $connString `
    -msgOk "  Tabella svuotata" `
    -msgErr "  Errore svuotamento"

Write-Host ""
Write-Host "  Ripristino da backup..." -ForegroundColor Yellow
Execute-SqlNonQuery -query @"
INSERT INTO VEDMaster.dbo.MA_CrossReferences
    (OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
     DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
     [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID)
SELECT
    OriginDocType, OriginDocID, OriginDocSubID, OriginDocLine,
    DerivedDocType, DerivedDocID, DerivedDocSubID, DerivedDocLine,
    [Manual], TBCreated, TBModified, TBCreatedID, TBModifiedID
FROM VEDMaster.dbo.MA_CrossReferencesBackup
"@ -connString $connString `
    -msgOk "  Ripristino completato" `
    -msgErr "  Errore ripristino"

# Verifica
$restoredCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM VEDMaster.dbo.MA_CrossReferences" -connString $connString
Write-Host ""
Write-Host "  Record ripristinati: $restoredCount (attesi: $backupCount)" -ForegroundColor $(if ($restoredCount -eq $backupCount) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Ripristino completato!" -ForegroundColor Green
