# ============================================
# SCRIPT: Aggiornamento CrossReferences Completo
# ============================================
# Versione: 1.0
# Data: 2025-01-29
# Descrizione: Aggiorna TUTTI i cross-references usando le mappature complete
#              Risolve l'anomalia dello script 19 che gestiva solo alcuni DocType
# ============================================

# Carica la configurazione
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\00_Config.ps1"

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  AGGIORNAMENTO CROSSREFERENCES COMPLETO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$startTime = Get-Date
Write-ColorOutput "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-Host ""

# Funzione per creare backup
function Backup-CrossReferences {
    param([string]$Database)

    $backupTable = "MA_CrossReferences_BACKUP_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $query = @"
IF EXISTS (SELECT * FROM $Database.sys.objects WHERE object_id = OBJECT_ID(N'$Database.dbo.$backupTable'))
    DROP TABLE $Database.dbo.$backupTable;
SELECT * INTO $Database.dbo.$backupTable FROM $Database.dbo.MA_CrossReferences;
"@

    $result = Execute-SqlQuery -Query $query -Database $Database
    if ($result.Success) {
        Write-ColorOutput "  Backup creato: $backupTable" "Green"
        return $backupTable
    }
    else {
        Write-ColorOutput "  ERRORE backup: $($result.Error)" "Red"
        return $null
    }
}

# Processa ogni database clone
foreach ($db in $Global:CloneDatabases) {
    Write-ColorOutput "============================================" "Yellow"
    Write-ColorOutput "Processando database: $db" "Yellow"
    Write-ColorOutput "============================================" "Yellow"
    Write-Host ""

    # Verifica prerequisiti
    if (-not (Test-TableExists -Database $db -TableName "TAG_CrMaps")) {
        Write-ColorOutput "  ERRORE: TAG_CrMaps non esiste! Eseguire prima gli script di rinumerazione." "Red"
        continue
    }

    if (-not (Test-TableExists -Database $db -TableName "TAG_DocumentTypesCr")) {
        Write-ColorOutput "  ERRORE: TAG_DocumentTypesCr non esiste! Eseguire prima 01_CreaMappaDocTypeCompleta.ps1" "Red"
        continue
    }

    # Crea backup
    Write-ColorOutput "Creazione backup..." "White"
    $backupTable = Backup-CrossReferences -Database $db
    if (-not $backupTable) {
        Write-ColorOutput "  Backup fallito. Continuare comunque? (S/N)" "Yellow"
        $response = Read-Host
        if ($response -ne "S" -and $response -ne "s") {
            continue
        }
    }

    # Conta record prima dell'aggiornamento
    $countBefore = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $db.dbo.MA_CrossReferences"
    Write-ColorOutput "Record CrossReferences: $countBefore" "White"

    # ============================================
    # FASE 1: Aggiornamento OriginDocID
    # ============================================
    Write-ColorOutput "FASE 1: Aggiornamento OriginDocID..." "Cyan"

    $queryOriginDocID = @"
UPDATE cr
SET cr.OriginDocID = cm.NewDocId
FROM $db.dbo.MA_CrossReferences cr
INNER JOIN $db.dbo.TAG_CrMaps cm ON cm.OldId = cr.OriginDocID
INNER JOIN $db.dbo.TAG_DocumentTypesCr dt ON dt.EnumValue = cm.DocumentType AND dt.ReferenceCode = cr.OriginDocType
WHERE cr.OriginDocID <> cm.NewDocId;
"@

    $result = Execute-SqlQuery -Query $queryOriginDocID -Database $db -Timeout 600
    if ($result.Success) {
        Write-ColorOutput "  OriginDocID aggiornati: $($result.RowsAffected) record" "Green"
    }
    else {
        Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
    }

    # ============================================
    # FASE 2: Aggiornamento DerivedDocID
    # ============================================
    Write-ColorOutput "FASE 2: Aggiornamento DerivedDocID..." "Cyan"

    $queryDerivedDocID = @"
UPDATE cr
SET cr.DerivedDocID = cm.NewDocId
FROM $db.dbo.MA_CrossReferences cr
INNER JOIN $db.dbo.TAG_CrMaps cm ON cm.OldId = cr.DerivedDocID
INNER JOIN $db.dbo.TAG_DocumentTypesCr dt ON dt.EnumValue = cm.DocumentType AND dt.ReferenceCode = cr.DerivedDocType
WHERE cr.DerivedDocID <> cm.NewDocId;
"@

    $result = Execute-SqlQuery -Query $queryDerivedDocID -Database $db -Timeout 600
    if ($result.Success) {
        Write-ColorOutput "  DerivedDocID aggiornati: $($result.RowsAffected) record" "Green"
    }
    else {
        Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
    }

    # ============================================
    # FASE 2B: Aggiornamento MA_CrossReferencesNotes
    # ============================================
    Write-ColorOutput "FASE 2B: Aggiornamento MA_CrossReferencesNotes..." "Cyan"

    if (Test-TableExists -Database $db -TableName "MA_CrossReferencesNotes") {
        $queryOriginNotes = @"
UPDATE cr
SET cr.OriginDocID = cm.NewDocId
FROM $db.dbo.MA_CrossReferencesNotes cr
INNER JOIN $db.dbo.TAG_CrMaps cm ON cm.OldId = cr.OriginDocID
INNER JOIN $db.dbo.TAG_DocumentTypesCr dt ON dt.EnumValue = cm.DocumentType AND dt.ReferenceCode = cr.OriginDocType
WHERE cr.OriginDocID <> cm.NewDocId;
"@

        $result = Execute-SqlQuery -Query $queryOriginNotes -Database $db -Timeout 600
        if ($result.Success) {
            Write-ColorOutput "  Notes OriginDocID aggiornati: $($result.RowsAffected) record" "Green"
        }
        else {
            Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
        }

        $queryDerivedNotes = @"
UPDATE cr
SET cr.DerivedDocID = cm.NewDocId
FROM $db.dbo.MA_CrossReferencesNotes cr
INNER JOIN $db.dbo.TAG_CrMaps cm ON cm.OldId = cr.DerivedDocID
INNER JOIN $db.dbo.TAG_DocumentTypesCr dt ON dt.EnumValue = cm.DocumentType AND dt.ReferenceCode = cr.DerivedDocType
WHERE cr.DerivedDocID <> cm.NewDocId;
"@

        $result = Execute-SqlQuery -Query $queryDerivedNotes -Database $db -Timeout 600
        if ($result.Success) {
            Write-ColorOutput "  Notes DerivedDocID aggiornati: $($result.RowsAffected) record" "Green"
        }
        else {
            Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
        }
    }
    else {
        Write-ColorOutput "  MA_CrossReferencesNotes non presente, salto" "Gray"
    }

    # ============================================
    # FASE 3: Aggiornamento diretto per DocType non in TAG_CrMaps
    # (es. Commesse che potrebbero avere mappatura separata)
    # ============================================
    Write-ColorOutput "FASE 3: Verifica DocType non mappati..." "Cyan"

    # Trova DocType in CrossReferences che non hanno corrispondenza in TAG_CrMaps
    $queryUnmapped = @"
SELECT DISTINCT
    'Origin' as RefType,
    cr.OriginDocType as DocType,
    COUNT(*) as RecordCount
FROM $db.dbo.MA_CrossReferences cr
LEFT JOIN $db.dbo.TAG_CrMaps cm ON cm.OldId = cr.OriginDocID
LEFT JOIN $db.dbo.TAG_DocumentTypesCr dt ON dt.ReferenceCode = cr.OriginDocType
WHERE cm.OldId IS NULL AND dt.ReferenceCode IS NOT NULL
GROUP BY cr.OriginDocType

UNION ALL

SELECT DISTINCT
    'Derived' as RefType,
    cr.DerivedDocType as DocType,
    COUNT(*) as RecordCount
FROM $db.dbo.MA_CrossReferences cr
LEFT JOIN $db.dbo.TAG_CrMaps cm ON cm.OldId = cr.DerivedDocID
LEFT JOIN $db.dbo.TAG_DocumentTypesCr dt ON dt.ReferenceCode = cr.DerivedDocType
WHERE cm.OldId IS NULL AND dt.ReferenceCode IS NOT NULL
GROUP BY cr.DerivedDocType
"@

    $unmappedData = Execute-SqlReader -Query $queryUnmapped -Database $db
    if ($unmappedData -and $unmappedData.Rows.Count -gt 0) {
        Write-ColorOutput "  DocType con record non mappati:" "Yellow"
        foreach ($row in $unmappedData.Rows) {
            Write-ColorOutput "    $($row.RefType) DocType $($row.DocType): $($row.RecordCount) record" "Yellow"
        }
    }
    else {
        Write-ColorOutput "  Tutti i record sono stati mappati correttamente" "Green"
    }

    # ============================================
    # FASE 4: Aggiornamento SubID (se necessario)
    # ============================================
    Write-ColorOutput "FASE 4: Verifica SubID..." "Cyan"

    $offset = Get-DatabaseOffset -DatabaseName $db

    # Verifica se i SubID sono gia stati aggiornati
    $querySubIdCheck = @"
SELECT
    MIN(OriginDocSubID) as MinOriginSubId,
    MAX(OriginDocSubID) as MaxOriginSubId,
    MIN(DerivedDocSubID) as MinDerivedSubId,
    MAX(DerivedDocSubID) as MaxDerivedSubId
FROM $db.dbo.MA_CrossReferences
WHERE OriginDocSubID > 0 OR DerivedDocSubID > 0
"@

    $subIdData = Execute-SqlReader -Query $querySubIdCheck -Database $db
    if ($subIdData -and $subIdData.Rows.Count -gt 0) {
        $row = $subIdData.Rows[0]
        $maxSubId = [Math]::Max($row.MaxOriginSubId, $row.MaxDerivedSubId)

        if ($maxSubId -lt $offset) {
            Write-ColorOutput "  SubID potrebbero non essere stati rinumerati (max: $maxSubId, offset atteso: $offset)" "Yellow"
            Write-ColorOutput "  Eseguire 19BisRinumerasubid.ps1 se necessario" "Yellow"
        }
        else {
            Write-ColorOutput "  SubID sembrano gia rinumerati (max: $maxSubId)" "Green"
        }
    }

    Write-Host ""
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

# Mostra statistiche per ogni database
foreach ($db in $Global:CloneDatabases) {
    Write-ColorOutput "Database: $db" "Yellow"

    if (Test-TableExists -Database $db -TableName "MA_CrossReferences") {
        $stats = Execute-SqlReader -Query @"
SELECT
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT OriginDocType) as DistinctOriginTypes,
    COUNT(DISTINCT DerivedDocType) as DistinctDerivedTypes,
    MIN(OriginDocID) as MinOriginId,
    MAX(OriginDocID) as MaxOriginId,
    MIN(DerivedDocID) as MinDerivedId,
    MAX(DerivedDocID) as MaxDerivedId
FROM $db.dbo.MA_CrossReferences
"@ -Database $db

        if ($stats -and $stats.Rows.Count -gt 0) {
            $row = $stats.Rows[0]
            Write-ColorOutput "  Record totali: $($row.TotalRecords)" "White"
            Write-ColorOutput "  OriginDocType distinti: $($row.DistinctOriginTypes)" "Gray"
            Write-ColorOutput "  DerivedDocType distinti: $($row.DistinctDerivedTypes)" "Gray"
            Write-ColorOutput "  Range OriginDocID: $($row.MinOriginId) - $($row.MaxOriginId)" "Gray"
            Write-ColorOutput "  Range DerivedDocID: $($row.MinDerivedId) - $($row.MaxDerivedId)" "Gray"
        }
    }
    Write-Host ""
}

Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  AGGIORNAMENTO COMPLETATO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""
Write-ColorOutput "PROSSIMI PASSI:" "Yellow"
Write-ColorOutput "1. Eseguire la migrazione dati verso VEDMaster" "White"
Write-ColorOutput "2. Eseguire 04_PostTrasfAggiornaRiferimentiCompleto.ps1" "White"
Write-ColorOutput "3. Eseguire 05_VerificaIntegritaCrossRef.ps1" "White"
