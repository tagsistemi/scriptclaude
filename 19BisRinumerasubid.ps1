# ============================================
# SCRIPT COMPLETO: BACKUP E RINUMERAZIONE SubID
# ============================================
# Versione: 1.1
# Data: 2025-10-01
# Descrizione: Backup tabelle, rinumerazione SubID per consolidamento multi-azienda
# ============================================

# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"

# Database da processare (escludiamo vedcontab che rimane base con offset 0)
$SourceDBsToProcess = @(
    @{ Name = "gpxnetclone"; Offset = 100000 },
    @{ Name = "furmanetclone"; Offset = 200000 },
    @{ Name = "vedbondifeclone"; Offset = 300000 }
)

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

# Tabelle da processare con i rispettivi campi SubID
$TablesToProcess = @(
    @{ 
        TableName = "MA_CrossReferences"
        SubIDFields = @("OriginDocSubID", "DerivedDocSubID")
    },
    @{ 
        TableName = "MA_JournalEntriesGLDetail"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_InventoryEntriesDetail"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_SaleDocDetail"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_SaleOrdDetails"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_PurchaseOrdDetails"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_SaleDocPymtSched"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_SuppQuotasDetail"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_CustQuotasDetail"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_PurchaseDocDetail"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_ReceiptsBatch"
        SubIDFields = @("SubId")
    },
    @{ 
        TableName = "MA_CompanyFiscalYears"
        SubIDFields = @("SubId")
    }
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

function Get-TableRowCount {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    
    $query = "SELECT COUNT(*) AS C FROM $Database.dbo.$TableName;"
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        return $result.C
    }
    catch {
        return 0
    }
}

function Backup-Table {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    
    $backupTableName = "${TableName}_BACKUP"
    
    # Elimina backup precedente se esistente
    $dropQuery = @"
IF EXISTS (SELECT * FROM $Database.INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_NAME = '$backupTableName' AND TABLE_SCHEMA = 'dbo')
BEGIN
    DROP TABLE $Database.dbo.$backupTableName;
END
"@
    
    try {
        Invoke-Sqlcmd -Query $dropQuery -ConnectionString $ConnString -ErrorAction Stop
    }
    catch {
        Write-ColorOutput "  Avviso: impossibile eliminare backup precedente di $backupTableName" "Yellow"
    }
    
    # Crea backup
    $backupQuery = "SELECT * INTO $Database.dbo.$backupTableName FROM $Database.dbo.$TableName;"
    
    try {
        Invoke-Sqlcmd -Query $backupQuery -ConnectionString $ConnString -ErrorAction Stop
        $rowCount = Get-TableRowCount -Database $Database -TableName $backupTableName -ConnString $ConnectionString
        Write-ColorOutput "  ✓ Backup creato: $backupTableName ($rowCount record)" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "  ✗ ERRORE nella creazione backup di $TableName : $_" "Red"
        return $false
    }
}

function Test-ColumnExists {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ColumnName,
        [string]$ConnString
    )
    
    $query = @"
SELECT COUNT(*) AS C 
FROM $Database.INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = '$TableName' 
  AND TABLE_SCHEMA = 'dbo' 
  AND COLUMN_NAME = '$ColumnName';
"@
    
    try {
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        return ($result.C -gt 0)
    }
    catch {
        return $false
    }
}

function Get-SubIDStats {
    param(
        [string]$Database,
        [string]$TableName,
        [array]$SubIDFields,
        [string]$ConnString
    )
    
    $stats = @{}
    
    foreach ($field in $SubIDFields) {
        # Verifica che la colonna esista
        if (-not (Test-ColumnExists -Database $Database -TableName $TableName -ColumnName $field -ConnString $ConnString)) {
            Write-ColorOutput "    ⚠️  Colonna '$field' non trovata in $TableName" "Yellow"
            $stats[$field] = @{
                Min = "N/A"
                Max = "N/A"
                Distinct = "N/A"
                Error = "Colonna non trovata"
            }
            continue
        }
        
        $query = @"
SELECT 
    MIN($field) as MinVal,
    MAX($field) as MaxVal,
    COUNT(DISTINCT $field) as DistinctCount
FROM $Database.dbo.$TableName;
"@
        
        try {
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
            $stats[$field] = @{
                Min = $result.MinVal
                Max = $result.MaxVal
                Distinct = $result.DistinctCount
                Error = $null
            }
        }
        catch {
            Write-ColorOutput "    ⚠️  Errore nella lettura di '$field': $_" "Yellow"
            $stats[$field] = @{
                Min = "N/A"
                Max = "N/A"
                Distinct = "N/A"
                Error = $_.Exception.Message
            }
        }
    }
    
    return $stats
}

function Update-SubIDFields {
    param(
        [string]$Database,
        [string]$TableName,
        [array]$SubIDFields,
        [int]$Offset,
        [string]$ConnString
    )

    # Filtra solo le colonne che esistono
    $existingFields = @()
    foreach ($field in $SubIDFields) {
        if (Test-ColumnExists -Database $Database -TableName $TableName -ColumnName $field -ConnString $ConnString) {
            $existingFields += $field
        }
        else {
            Write-ColorOutput "    ⚠️  Colonna '$field' non trovata, salto..." "Yellow"
        }
    }

    if ($existingFields.Count -eq 0) {
        Write-ColorOutput "    ⚠️  Nessuna colonna SubID trovata in $TableName" "Yellow"
        return $false
    }

    # Aggiorna ogni campo SubID separatamente con WHERE > 0
    # IMPORTANTE: non aggiornare SubId=0 (significa "nessun SubId associato")
    # Per tabelle con piu campi SubID (es. MA_CrossReferences con OriginDocSubID e DerivedDocSubID),
    # ogni campo va aggiornato indipendentemente perche uno potrebbe essere 0 e l'altro no
    $allSuccess = $true
    foreach ($field in $existingFields) {
        $updateQuery = "UPDATE $Database.dbo.$TableName SET $field = $field + $Offset WHERE $field > 0;"

        try {
            $result = Invoke-Sqlcmd -Query $updateQuery -ConnectionString $ConnString -ErrorAction Stop
            Write-ColorOutput "    ✓ $field aggiornato (WHERE $field > 0)" "Green"
        }
        catch {
            Write-ColorOutput "    ✗ ERRORE aggiornamento $field : $_" "Red"
            $allSuccess = $false
        }
    }

    return $allSuccess
}

# ============================================
# INIZIO SCRIPT PRINCIPALE
# ============================================

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  BACKUP E RINUMERAZIONE SubID" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$startTime = Get-Date
Write-ColorOutput "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
Write-Host ""

# ============================================
# FASE 1: ANALISI PRE-BACKUP
# ============================================

Write-ColorOutput "FASE 1: ANALISI TABELLE" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$tablesSummary = @()

foreach ($dbInfo in $SourceDBsToProcess) {
    $dbName = $dbInfo.Name
    Write-ColorOutput "Analisi database: $dbName" "Yellow"
    
    foreach ($tableInfo in $TablesToProcess) {
        $tableName = $tableInfo.TableName
        
        if (Test-TableExists -Database $dbName -TableName $tableName -ConnString $ConnectionString) {
            $rowCount = Get-TableRowCount -Database $dbName -TableName $tableName -ConnString $ConnectionString
            Write-ColorOutput "  ✓ $tableName : $rowCount record" "Green"
            
            $tablesSummary += [PSCustomObject]@{
                Database = $dbName
                Table = $tableName
                RowCount = $rowCount
                Status = "OK"
            }
        }
        else {
            Write-ColorOutput "  - $tableName : NON TROVATA" "DarkGray"
            
            $tablesSummary += [PSCustomObject]@{
                Database = $dbName
                Table = $tableName
                RowCount = 0
                Status = "ASSENTE"
            }
        }
    }
    Write-Host ""
}

# ============================================
# FASE 2: BACKUP TABELLE
# ============================================

Write-Host ""
Write-ColorOutput "FASE 2: BACKUP TABELLE" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$backupResults = @()
$backupSuccess = $true

foreach ($dbInfo in $SourceDBsToProcess) {
    $dbName = $dbInfo.Name
    Write-ColorOutput "Backup database: $dbName" "Yellow"
    
    foreach ($tableInfo in $TablesToProcess) {
        $tableName = $tableInfo.TableName
        
        if (Test-TableExists -Database $dbName -TableName $tableName -ConnString $ConnectionString) {
            $success = Backup-Table -Database $dbName -TableName $tableName -ConnString $ConnectionString
            
            if (-not $success) {
                $backupSuccess = $false
            }
            
            $backupResults += [PSCustomObject]@{
                Database = $dbName
                Table = $tableName
                BackupSuccess = $success
            }
        }
    }
    Write-Host ""
}

if (-not $backupSuccess) {
    Write-ColorOutput "============================================" "Red"
    Write-ColorOutput "⚠️  ATTENZIONE: Alcuni backup sono falliti!" "Red"
    Write-ColorOutput "============================================" "Red"
    Write-Host ""
    Write-ColorOutput "Vuoi procedere comunque con la rinumerazione? (S/N)" "Yellow"
    $response = Read-Host
    
    if ($response -ne "S" -and $response -ne "s") {
        Write-ColorOutput "Operazione annullata dall'utente." "Red"
        exit
    }
}

# ============================================
# FASE 3: ANALISI PRE-RINUMERAZIONE
# ============================================

Write-Host ""
Write-ColorOutput "FASE 3: ANALISI RANGE SubID PRE-RINUMERAZIONE" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

foreach ($dbInfo in $SourceDBsToProcess) {
    $dbName = $dbInfo.Name
    $offset = $dbInfo.Offset
    
    Write-ColorOutput "Database: $dbName (Offset: +$offset)" "Yellow"
    
    foreach ($tableInfo in $TablesToProcess) {
        $tableName = $tableInfo.TableName
        
        if (Test-TableExists -Database $dbName -TableName $tableName -ConnString $ConnectionString) {
            $stats = Get-SubIDStats -Database $dbName -TableName $tableName -SubIDFields $tableInfo.SubIDFields -ConnString $ConnectionString
            
            Write-ColorOutput "  Tabella: $tableName" "White"
            foreach ($field in $tableInfo.SubIDFields) {
                $fieldStats = $stats[$field]
                if ($fieldStats.Error) {
                    Write-ColorOutput "    ⚠️  $field : $($fieldStats.Error)" "Yellow"
                }
                else {
                    Write-ColorOutput "    $field : Min=$($fieldStats.Min), Max=$($fieldStats.Max), Distinct=$($fieldStats.Distinct)" "Gray"
                }
            }
        }
    }
    Write-Host ""
}

# ============================================
# FASE 4: RINUMERAZIONE SubID
# ============================================

Write-Host ""
Write-ColorOutput "FASE 4: RINUMERAZIONE SubID" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

Write-ColorOutput "⚠️  ATTENZIONE: Si procederà con la rinumerazione dei SubID" "Yellow"
Write-ColorOutput "Confermi di voler procedere? (S/N)" "Yellow"
$confirmRenumber = Read-Host

if ($confirmRenumber -ne "S" -and $confirmRenumber -ne "s") {
    Write-ColorOutput "Operazione annullata dall'utente." "Red"
    exit
}

Write-Host ""

$updateResults = @()
$updateSuccess = $true

foreach ($dbInfo in $SourceDBsToProcess) {
    $dbName = $dbInfo.Name
    $offset = $dbInfo.Offset
    
    Write-ColorOutput "Rinumerazione database: $dbName (Offset: +$offset)" "Yellow"
    
    foreach ($tableInfo in $TablesToProcess) {
        $tableName = $tableInfo.TableName
        
        if (Test-TableExists -Database $dbName -TableName $tableName -ConnString $ConnectionString) {
            $rowCount = Get-TableRowCount -Database $dbName -TableName $tableName -ConnString $ConnectionString
            Write-ColorOutput "  Aggiornamento: $tableName ($rowCount record)..." "White"
            
            $success = Update-SubIDFields -Database $dbName -TableName $tableName -SubIDFields $tableInfo.SubIDFields -Offset $offset -ConnString $ConnectionString

            if ($success) {
                $updateResults += [PSCustomObject]@{
                    Database = $dbName
                    Table = $tableName
                    Offset = $offset
                    RowsAffected = $rowCount
                    Success = $true
                }
            }
            else {
                $updateSuccess = $false
                
                $updateResults += [PSCustomObject]@{
                    Database = $dbName
                    Table = $tableName
                    Offset = $offset
                    RowsAffected = 0
                    Success = $false
                }
            }
        }
    }
    Write-Host ""
}

# ============================================
# FASE 5: VERIFICA POST-RINUMERAZIONE
# ============================================

Write-Host ""
Write-ColorOutput "FASE 5: VERIFICA RANGE SubID POST-RINUMERAZIONE" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

foreach ($dbInfo in $SourceDBsToProcess) {
    $dbName = $dbInfo.Name
    $offset = $dbInfo.Offset
    
    Write-ColorOutput "Database: $dbName (Offset applicato: +$offset)" "Yellow"
    
    foreach ($tableInfo in $TablesToProcess) {
        $tableName = $tableInfo.TableName
        
        if (Test-TableExists -Database $dbName -TableName $tableName -ConnString $ConnectionString) {
            $stats = Get-SubIDStats -Database $dbName -TableName $tableName -SubIDFields $tableInfo.SubIDFields -ConnString $ConnectionString
            
            Write-ColorOutput "  Tabella: $tableName" "White"
            foreach ($field in $tableInfo.SubIDFields) {
                $fieldStats = $stats[$field]
                
                if ($fieldStats.Error) {
                    Write-ColorOutput "    ⚠️  $field : $($fieldStats.Error)" "Yellow"
                }
                else {
                    # Min puo essere 0 (record senza SubId, non rinumerati) oppure >= offset
                    # Verifica che non ci siano valori nel range 1..(offset-1), il che indicherebbe
                    # record che dovevano essere rinumerati ma non lo sono stati
                    $minNonZero = $fieldStats.Min
                    if ($minNonZero -eq 0) {
                        # Il min e' 0, controlliamo il min dei valori > 0
                        $checkQuery = "SELECT MIN($field) AS MinVal FROM $dbName.dbo.$tableName WHERE $field > 0;"
                        try {
                            $checkResult = Invoke-Sqlcmd -Query $checkQuery -ConnectionString $ConnectionString -ErrorAction Stop
                            $minNonZero = $checkResult.MinVal
                        }
                        catch { $minNonZero = $null }
                    }
                    $rangeOK = ($null -eq $minNonZero -or $minNonZero -eq '' -or $minNonZero -eq [System.DBNull]::Value -or $minNonZero -eq 0 -or $minNonZero -ge $offset)
                    $statusColor = if ($rangeOK) { "Green" } else { "Red" }
                    $statusSymbol = if ($rangeOK) { "✓" } else { "✗" }

                    Write-ColorOutput "    $statusSymbol $field : Min=$($fieldStats.Min), MinNonZero=$minNonZero, Max=$($fieldStats.Max), Distinct=$($fieldStats.Distinct)" $statusColor
                }
            }
        }
    }
    Write-Host ""
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

Write-ColorOutput "BACKUP ESEGUITI:" "White"
$backupResults | Format-Table -AutoSize | Out-String | Write-Host

Write-ColorOutput "AGGIORNAMENTI ESEGUITI:" "White"
$updateResults | Format-Table -AutoSize | Out-String | Write-Host

if ($updateSuccess) {
    Write-ColorOutput "✓ RINUMERAZIONE COMPLETATA CON SUCCESSO!" "Green"
    Write-Host ""
    Write-ColorOutput "PROSSIMI PASSI:" "Yellow"
    Write-ColorOutput "1. Verifica i range SubID sopra riportati" "White"
    Write-ColorOutput "2. Esegui lo script di consolidamento su MA_CrossReferences" "White"
    Write-ColorOutput "3. Controlla che i duplicati siano drasticamente ridotti" "White"
    Write-Host ""
    Write-ColorOutput "NOTA: Le tabelle di backup sono disponibili con suffisso _BACKUP" "Cyan"
    Write-ColorOutput "      Es: MA_CrossReferences_BACKUP" "Cyan"
}
else {
    Write-ColorOutput "⚠️  ATTENZIONE: Alcuni aggiornamenti sono falliti!" "Red"
    Write-ColorOutput "Controlla i log sopra e verifica lo stato dei database." "Red"
    Write-Host ""
    Write-ColorOutput "RIPRISTINO DA BACKUP:" "Yellow"
    Write-ColorOutput "Per ripristinare una tabella da backup, esegui:" "White"
    Write-ColorOutput "  DROP TABLE database.dbo.NomeTabella;" "Gray"
    Write-ColorOutput "  SELECT * INTO database.dbo.NomeTabella FROM database.dbo.NomeTabella_BACKUP;" "Gray"
}

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "PROCESSO COMPLETATO" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""