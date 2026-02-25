# ============================================
# SCRIPT AGGIORNAMENTO SubID su VEDMaster DA ESEUIRE SOLO SE I TRASFERIMENTI SONO GIA STATI ESEGUITI !!!
# ============================================
# Versione: 2.0
# Data: 2025-10-01
# Descrizione: Aggiorna SubId in VEDMaster usando i valori rinumerati dai DB sorgenti
#              con rilevamento automatico delle chiavi primarie
# ============================================

# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"

# Database sorgenti con offset
$SourceDBs = @(
    @{ Name = "vedcontab"; Offset = 0 },
    @{ Name = "gpxnetclone"; Offset = 100000 },
    @{ Name = "furmanetclone"; Offset = 200000 },
    @{ Name = "vedbondifeclone"; Offset = 300000 }
)

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

# Tabelle da aggiornare (le PK verranno rilevate automaticamente)
$TablesToUpdate = @(
    "MA_JournalEntriesGLDetail",
    "MA_InventoryEntriesDetail",
    "MA_SaleDocDetail",
    "MA_SaleOrdDetails",
    "MA_PurchaseOrdDetails",
    "MA_SaleDocPymtSched",
    "MA_SuppQuotasDetail",
    "MA_CustQuotasDetail",
    "MA_PurchaseDocDetail",
    "MA_ReceiptsBatch"
)

# ============================================
# FUNZIONI HELPER
# ============================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-TablePrimaryKey {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    
    $query = @"
SELECT kcu.COLUMN_NAME
FROM $Database.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
JOIN $Database.INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
  ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
  AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
  AND tc.TABLE_NAME = kcu.TABLE_NAME
WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
  AND tc.TABLE_NAME = '$TableName'
ORDER BY kcu.ORDINAL_POSITION;
"@
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        return @($result.COLUMN_NAME)
    }
    catch {
        return $null
    }
}

function Get-TableColumns {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    
    $query = "SELECT COLUMN_NAME FROM $Database.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TableName' AND TABLE_SCHEMA = 'dbo' ORDER BY ORDINAL_POSITION;"
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        return @($result.COLUMN_NAME)
    }
    catch {
        return $null
    }
}

function Test-TableExists {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    
    $query = @"
SELECT COUNT(*) AS C 
FROM $Database.INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = '$TableName' AND TABLE_SCHEMA = 'dbo';
"@
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        return ($result.C -gt 0)
    }
    catch {
        return $false
    }
}

function Backup-DestinationTable {
    param(
        [string]$TableName,
        [string]$ConnString
    )
    
    $backupTableName = "${TableName}_BACKUP_BEFORESUBIDUPDATE"
    
    # Elimina backup precedente se esistente
    $dropQuery = @"
IF EXISTS (SELECT * FROM $DestinationDB.INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_NAME = '$backupTableName' AND TABLE_SCHEMA = 'dbo')
BEGIN
    DROP TABLE $DestinationDB.dbo.$backupTableName;
END
"@
    
    try {
        Invoke-Sqlcmd -Query $dropQuery -ConnectionString $ConnString -ErrorAction Stop
    }
    catch {
        # Ignora errori
    }
    
    # Crea backup
    $backupQuery = "SELECT * INTO $DestinationDB.dbo.$backupTableName FROM $DestinationDB.dbo.$TableName;"
    
    try {
        Invoke-Sqlcmd -Query $backupQuery -ConnectionString $ConnString -ErrorAction Stop
        Write-ColorOutput "  ✓ Backup creato: $backupTableName" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "  ✗ ERRORE backup: $_" "Red"
        return $false
    }
}

function Get-SubIdFieldName {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    
    # Cerca colonne che contengono "SubId" nel nome
    $query = @"
SELECT COLUMN_NAME 
FROM $Database.INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = '$TableName' 
  AND TABLE_SCHEMA = 'dbo'
  AND COLUMN_NAME LIKE '%SubId%'
ORDER BY ORDINAL_POSITION;
"@
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        if ($result -and $result.Count -gt 0) {
            # Preferisci "SubId" se esiste, altrimenti prendi il primo
            $subIdCols = @($result.COLUMN_NAME)
            if ($subIdCols -contains "SubId") {
                return "SubId"
            }
            else {
                return $subIdCols[0]
            }
        }
        return $null
    }
    catch {
        return $null
    }
}

function Build-UpdateQuery {
    param(
        [string]$SourceDB,
        [string]$TableName,
        [string]$SubIDField,
        [array]$PKFields,
        [string]$ConnString
    )
    
    # Rimuovi SubId dalle PK per il join (perché è quello che stiamo aggiornando)
    $joinFields = $PKFields | Where-Object { $_ -ne $SubIDField }
    
    if ($joinFields.Count -eq 0) {
        Write-ColorOutput "    ⚠️  Nessun campo di join disponibile (SubId è l'unica PK)" "Yellow"
        return $null
    }
    
    # Verifica che le colonne di join esistano in entrambe le tabelle
    $destCols = Get-TableColumns -Database $DestinationDB -TableName $TableName -ConnString $ConnString
    $srcCols = Get-TableColumns -Database $SourceDB -TableName $TableName -ConnString $ConnString
    
    $validJoinFields = @()
    foreach ($field in $joinFields) {
        if (($destCols -contains $field) -and ($srcCols -contains $field)) {
            $validJoinFields += $field
        }
        else {
            Write-ColorOutput "    ⚠️  Campo '$field' non trovato in entrambe le tabelle" "Yellow"
        }
    }
    
    if ($validJoinFields.Count -eq 0) {
        Write-ColorOutput "    ⚠️  Nessun campo valido per il JOIN" "Yellow"
        return $null
    }
    
    # Costruisci la condizione di JOIN
    $joinConditions = ($validJoinFields | ForEach-Object { "D.[$_] = S.[$_]" }) -join " AND "
    
    # Query di update
    $query = @"
UPDATE D
SET D.[$SubIDField] = S.[$SubIDField]
FROM $DestinationDB.dbo.[$TableName] AS D
INNER JOIN $SourceDB.dbo.[$TableName] AS S
    ON $joinConditions
WHERE D.[$SubIDField] <> S.[$SubIDField];
"@
    
    return $query
}

function Get-RowsAffectedEstimate {
    param(
        [string]$SourceDB,
        [string]$TableName,
        [string]$SubIDField,
        [array]$PKFields,
        [string]$ConnString
    )
    
    $joinFields = $PKFields | Where-Object { $_ -ne $SubIDField }
    
    if ($joinFields.Count -eq 0) {
        return 0
    }
    
    $joinConditions = ($joinFields | ForEach-Object { "D.[$_] = S.[$_]" }) -join " AND "
    
    $query = @"
SELECT COUNT(*) AS C
FROM $DestinationDB.dbo.[$TableName] AS D
INNER JOIN $SourceDB.dbo.[$TableName] AS S
    ON $joinConditions
WHERE D.[$SubIDField] <> S.[$SubIDField];
"@
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        return $result.C
    }
    catch {
        return -1
    }
}

# ============================================
# INIZIO SCRIPT PRINCIPALE
# ============================================

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  AGGIORNAMENTO SubID su VEDMaster" "Cyan"
Write-ColorOutput "  (con rilevamento automatico PK)" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$startTime = Get-Date
Write-ColorOutput "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-Host ""

# ============================================
# FASE 1: RILEVAMENTO CHIAVI PRIMARIE
# ============================================

Write-ColorOutput "FASE 1: RILEVAMENTO STRUTTURA TABELLE" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$tableStructures = @{}

foreach ($tableName in $TablesToUpdate) {
    
    if (-not (Test-TableExists -Database $DestinationDB -TableName $tableName -ConnString $ConnectionString)) {
        Write-ColorOutput "⚠️  Tabella $tableName non trovata in $DestinationDB, salto..." "Yellow"
        continue
    }
    
    Write-ColorOutput "Tabella: $tableName" "White"
    
    # Rileva chiave primaria
    $pkFields = Get-TablePrimaryKey -Database $DestinationDB -TableName $tableName -ConnString $ConnectionString
    
    if (-not $pkFields -or $pkFields.Count -eq 0) {
        Write-ColorOutput "  ⚠️  NESSUNA CHIAVE PRIMARIA TROVATA! Salto questa tabella." "Red"
        continue
    }
    
    Write-ColorOutput "  Chiave Primaria: $($pkFields -join ', ')" "Gray"
    
    # Rileva campo SubId
    $subIdField = Get-SubIdFieldName -Database $DestinationDB -TableName $tableName -ConnString $ConnectionString
    
    if (-not $subIdField) {
        Write-ColorOutput "  ⚠️  NESSUN CAMPO SubId TROVATO! Salto questa tabella." "Red"
        continue
    }
    
    Write-ColorOutput "  Campo SubId: $subIdField" "Gray"
    
    # Verifica che SubId sia parte della PK
    if ($pkFields -contains $subIdField) {
        Write-ColorOutput "  ✓ SubId è parte della chiave primaria" "Green"
        
        # Salva la struttura
        $tableStructures[$tableName] = @{
            PKFields = $pkFields
            SubIdField = $subIdField
        }
    }
    else {
        Write-ColorOutput "  ⚠️  SubId NON è parte della PK. Potrebbe non essere sicuro aggiornarlo." "Yellow"
        
        # Salva comunque, ma con warning
        $tableStructures[$tableName] = @{
            PKFields = $pkFields
            SubIdField = $subIdField
            Warning = "SubId non in PK"
        }
    }
    
    Write-Host ""
}

if ($tableStructures.Count -eq 0) {
    Write-ColorOutput "❌ NESSUNA TABELLA VALIDA TROVATA! Impossibile procedere." "Red"
    exit
}

Write-ColorOutput "Trovate $($tableStructures.Count) tabelle valide da aggiornare." "Green"
Write-Host ""

Write-ColorOutput "Vuoi procedere con il backup e l'aggiornamento? (S/N)" "Yellow"
$response = Read-Host

if ($response -ne "S" -and $response -ne "s") {
    Write-ColorOutput "Operazione annullata." "Red"
    exit
}

# ============================================
# FASE 2: BACKUP TABELLE DESTINAZIONE
# ============================================

Write-Host ""
Write-ColorOutput "FASE 2: BACKUP TABELLE VEDMaster" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$backupSuccess = $true

foreach ($tableName in $tableStructures.Keys) {
    Write-ColorOutput "Backup: $tableName" "White"
    $success = Backup-DestinationTable -TableName $tableName -ConnString $ConnectionString
    
    if (-not $success) {
        $backupSuccess = $false
    }
}

if (-not $backupSuccess) {
    Write-ColorOutput "⚠️  Alcuni backup sono falliti. Vuoi continuare? (S/N)" "Yellow"
    $response = Read-Host
    
    if ($response -ne "S" -and $response -ne "s") {
        Write-ColorOutput "Operazione annullata." "Red"
        exit
    }
}

# ============================================
# FASE 3: ANALISI PRE-AGGIORNAMENTO
# ============================================

Write-Host ""
Write-ColorOutput "FASE 3: ANALISI RECORD DA AGGIORNARE" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$preUpdateAnalysis = @()

foreach ($tableName in $tableStructures.Keys) {
    $tableInfo = $tableStructures[$tableName]
    
    Write-ColorOutput "Tabella: $tableName" "Yellow"
    
    foreach ($dbInfo in $SourceDBs) {
        $sourceDB = $dbInfo.Name
        $offset = $dbInfo.Offset
        
        if (-not (Test-TableExists -Database $sourceDB -TableName $tableName -ConnString $ConnectionString)) {
            continue
        }
        
        $estimatedRows = Get-RowsAffectedEstimate -SourceDB $sourceDB -TableName $tableName -SubIDField $tableInfo.SubIdField -PKFields $tableInfo.PKFields -ConnString $ConnectionString
        
        if ($estimatedRows -gt 0) {
            Write-ColorOutput "  $sourceDB : ~$estimatedRows record da aggiornare" "White"
            
            $preUpdateAnalysis += [PSCustomObject]@{
                Table = $tableName
                SourceDB = $sourceDB
                EstimatedRows = $estimatedRows
            }
        }
        elseif ($estimatedRows -eq 0) {
            Write-ColorOutput "  $sourceDB : Nessun record da aggiornare (già sincronizzato)" "DarkGray"
        }
        else {
            Write-ColorOutput "  $sourceDB : Impossibile stimare (errore query)" "Yellow"
        }
    }
    Write-Host ""
}

$totalEstimated = ($preUpdateAnalysis | Measure-Object -Property EstimatedRows -Sum).Sum
Write-ColorOutput "Totale stimato record da aggiornare: $totalEstimated" "Cyan"
Write-Host ""

if ($totalEstimated -eq 0) {
    Write-ColorOutput "✓ Nessun record da aggiornare. Tutti i SubId sono già sincronizzati!" "Green"
    exit
}

Write-ColorOutput "Confermi di procedere con l'aggiornamento di ~$totalEstimated record? (S/N)" "Yellow"
$response = Read-Host

if ($response -ne "S" -and $response -ne "s") {
    Write-ColorOutput "Operazione annullata." "Red"
    exit
}

# ============================================
# FASE 4: AGGIORNAMENTO SubID
# ============================================

Write-Host ""
Write-ColorOutput "FASE 4: AGGIORNAMENTO SubID" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$updateResults = @()

foreach ($tableName in $tableStructures.Keys) {
    $tableInfo = $tableStructures[$tableName]
    
    Write-ColorOutput "Tabella: $tableName" "Yellow"
    
    foreach ($dbInfo in $SourceDBs) {
        $sourceDB = $dbInfo.Name
        $offset = $dbInfo.Offset
        
        if (-not (Test-TableExists -Database $sourceDB -TableName $tableName -ConnString $ConnectionString)) {
            continue
        }
        
        Write-ColorOutput "  Aggiornamento da: $sourceDB (offset: $offset)" "White"
        
        # Costruisci query di update
        $updateQuery = Build-UpdateQuery -SourceDB $sourceDB -TableName $tableName -SubIDField $tableInfo.SubIdField -PKFields $tableInfo.PKFields -ConnString $ConnectionString
        
        if (-not $updateQuery) {
            Write-ColorOutput "    ⚠️  Impossibile costruire query di update" "Yellow"
            continue
        }
        
        # Mostra la query (opzionale, per debug)
        # Write-ColorOutput "    Query:" "DarkGray"
        # Write-ColorOutput $updateQuery "DarkGray"
        
        try {
            $beforeCount = Invoke-Sqlcmd -Query "SELECT @@ROWCOUNT AS C" -ConnectionString $ConnectionString -ErrorAction Stop
            Invoke-Sqlcmd -Query $updateQuery -ConnectionString $ConnectionString -ErrorAction Stop
            $rowsAffected = Invoke-Sqlcmd -Query "SELECT @@ROWCOUNT AS C" -ConnectionString $ConnectionString -ErrorAction Stop
            
            $actualRows = $rowsAffected.C
            
            if ($actualRows -gt 0) {
                Write-ColorOutput "    ✓ Record aggiornati: $actualRows" "Green"
            }
            else {
                Write-ColorOutput "    - Nessun record aggiornato (già sincronizzato)" "DarkGray"
            }
            
            $updateResults += [PSCustomObject]@{
                Table = $tableName
                SourceDB = $sourceDB
                Offset = $offset
                RowsUpdated = $actualRows
                Success = $true
            }
        }
        catch {
            Write-ColorOutput "    ✗ ERRORE: $_" "Red"
            
            $updateResults += [PSCustomObject]@{
                Table = $tableName
                SourceDB = $sourceDB
                Offset = $offset
                RowsUpdated = 0
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    Write-Host ""
}

# ============================================
# FASE 5: VERIFICA POST-AGGIORNAMENTO
# ============================================

Write-Host ""
Write-ColorOutput "FASE 5: VERIFICA SubID POST-AGGIORNAMENTO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

foreach ($tableName in $tableStructures.Keys) {
    $tableInfo = $tableStructures[$tableName]
    $subIDField = $tableInfo.SubIdField
    
    $query = @"
SELECT 
    MIN([$subIDField]) as MinSubId,
    MAX([$subIDField]) as MaxSubId,
    COUNT(DISTINCT [$subIDField]) as DistinctSubId,
    COUNT(*) as TotalRecords
FROM $DestinationDB.dbo.[$tableName];
"@
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnectionString -ErrorAction Stop
        
        Write-ColorOutput "Tabella: $tableName" "White"
        Write-ColorOutput "  Campo SubId: $subIDField" "Gray"
        Write-ColorOutput "  Min SubId: $($result.MinSubId)" "Gray"
        Write-ColorOutput "  Max SubId: $($result.MaxSubId)" "Gray"
        Write-ColorOutput "  Distinct SubId: $($result.DistinctSubId)" "Gray"
        Write-ColorOutput "  Totale Record: $($result.TotalRecords)" "Gray"
        
        # Verifica range
        $hasLowRange = $result.MinSubId -lt 100000
        $hasMidRange1 = $result.MinSubId -ge 100000 -and $result.MaxSubId -lt 200000
        $hasMidRange2 = $result.MinSubId -ge 200000 -and $result.MaxSubId -lt 300000
        $hasHighRange = $result.MaxSubId -ge 300000
        
        if ($hasLowRange -and $hasHighRange) {
            Write-ColorOutput "  ✓ Range multipli rilevati (consolidamento OK)" "Green"
        }
        elseif ($result.MaxSubId -lt 100000) {
            Write-ColorOutput "  ℹ️  Solo range base (0-99999)" "Cyan"
        }
        
        Write-Host ""
    }
    catch {
        Write-ColorOutput "  ⚠️  Errore nella verifica: $_" "Yellow"
        Write-Host ""
    }
}

# ============================================
# RIEPILOGO FINALE
# ============================================

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  RIEPILOGO OPERAZIONI" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$endTime = Get-Date
$duration = $endTime - $startTime

Write-ColorOutput "Ora inizio:  $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-ColorOutput "Ora fine:    $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-ColorOutput "Durata:      $($duration.ToString('hh\:mm\:ss'))" "Gray"
Write-Host ""

Write-ColorOutput "TABELLE PROCESSATE:" "White"
foreach ($tableName in $tableStructures.Keys) {
    $tableInfo = $tableStructures[$tableName]
    Write-ColorOutput "  • $tableName" "White"
    Write-ColorOutput "    - PK: $($tableInfo.PKFields -join ', ')" "Gray"
    Write-ColorOutput "    - SubId: $($tableInfo.SubIdField)" "Gray"
}
Write-Host ""

Write-ColorOutput "AGGIORNAMENTI ESEGUITI:" "White"
$updateResults | Format-Table -AutoSize | Out-String | Write-Host

$totalUpdated = ($updateResults | Where-Object { $_.Success } | Measure-Object -Property RowsUpdated -Sum).Sum
$failedUpdates = ($updateResults | Where-Object { -not $_.Success }).Count

Write-ColorOutput "Totale record aggiornati: $totalUpdated" "White"

if ($failedUpdates -gt 0) {
    Write-ColorOutput "⚠️  Aggiornamenti falliti: $failedUpdates" "Red"
    Write-Host ""
    Write-ColorOutput "Dettagli errori:" "Yellow"
    $updateResults | Where-Object { -not $_.Success } | ForEach-Object {
        Write-ColorOutput "  • $($_.Table) <- $($_.SourceDB): $($_.Error)" "Red"
    }
}
else {
    Write-ColorOutput "✓ TUTTI GLI AGGIORNAMENTI COMPLETATI CON SUCCESSO!" "Green"
}

Write-Host ""
Write-ColorOutput "NOTA: I backup sono disponibili con suffisso _BACKUP_BEFORESUBIDUPDATE" "Cyan"
Write-ColorOutput "      Per ripristinare: DROP TABLE + SELECT INTO dalla tabella _BACKUP" "Cyan"
Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "PROCESSO COMPLETATO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""