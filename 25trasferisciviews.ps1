# Script PowerShell per trasferire tutte le Views da un database SQL Server a un altro
# Versione compatibile con SQL Server 2008 - Utilizza SqlConnection diretto
# Autore: Script generato per trasferimento viste
# Data: $(Get-Date)

# Parametri di connessione
$ServerName = "192.168.0.3\sql2008"
$Username = "sa"
$Password = "stream"
$SourceDB = "gpxnetclone"
$DestinationDB = "vedmaster"
$ScriptOutputPath = "e:\MigrazioneVed\Scripts\VisteMigrate"
$LogFilePath = "e:\MigrazioneVed\Scripts\VisteMigrate\log_viste_migrate.txt"

# Crea la directory di output se non esiste, oppure pulisci i vecchi file .sql
if (-not (Test-Path -Path $ScriptOutputPath)) {
    New-Item -Path $ScriptOutputPath -ItemType Directory -Force | Out-Null
} else {
    # Rimuovi i vecchi file .sql per evitare duplicati tra esecuzioni successive
    Get-ChildItem -Path $ScriptOutputPath -Filter "*.sql" | Remove-Item -Force
    Write-Host "Puliti vecchi file .sql dalla cartella $ScriptOutputPath" -ForegroundColor Yellow
}

# Inizializza il file di log
"# Log di migrazione viste - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $LogFilePath -Force
"# Database sorgente: $SourceDB" | Out-File -FilePath $LogFilePath -Append
"# Database destinazione: $DestinationDB" | Out-File -FilePath $LogFilePath -Append
"# Server: $ServerName" | Out-File -FilePath $LogFilePath -Append
"" | Out-File -FilePath $LogFilePath -Append

# Carica l'assembly System.Data
Add-Type -AssemblyName "System.Data"

# Funzione per scrivere log con timestamp
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $LogFilePath -Value $logEntry
    
    # Determina il colore in base al livello
    $color = switch($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "Gray" }
    }
    
    Write-Host $Message -ForegroundColor $color
}

# Funzione per creare la stringa di connessione
function Get-ConnectionString {
    param(
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$Username,
        [string]$Password
    )
    
    return "Server=$ServerName;Database=$DatabaseName;User Id=$Username;Password=$Password;Trusted_Connection=False;Connection Timeout=30;"
}

# Funzione per testare la connessione
function Test-SqlConnection {
    param(
        [string]$ConnectionString,
        [string]$DatabaseName
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        Write-Log "Connessione a $DatabaseName riuscita" -Level "SUCCESS"
        
        $connection.Close()
        return $true
    }
    catch {
        Write-Log "Errore nella connessione a $DatabaseName`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Funzione per recuperare le viste dal database sorgente

# Modifica la funzione Get-Views per garantire il ritorno di un DataTable corretto
function Get-Views {
    param(
        [string]$ConnectionString,
        [string]$DatabaseName
    )
    
    $query = @"
SELECT 
    s.name AS SchemaName,
    v.name AS ViewName,
    OBJECT_DEFINITION(v.object_id) AS ViewDefinition
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE v.is_ms_shipped = 0
ORDER BY s.name, v.name
"@
    
    Write-Log "Recupero viste dal database $DatabaseName..." -Level "INFO"
    
    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    
    try {
        $connection.Open()
        Write-Log "Connessione aperta" -Level "INFO"
        
        # Crea esplicitamente un DataTable con le colonne richieste
        $dataTable = New-Object System.Data.DataTable
        $dataTable.Columns.Add("SchemaName", [string])
        $dataTable.Columns.Add("ViewName", [string])
        $dataTable.Columns.Add("ViewDefinition", [string])
        
        $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
        $command.CommandTimeout = 120
        
        $reader = $command.ExecuteReader()
        
        # Popola manualmente il DataTable con i risultati del reader
        while ($reader.Read()) {
            $row = $dataTable.NewRow()
            $row["SchemaName"] = $reader.GetString(0)  # Prima colonna (SchemaName)
            $row["ViewName"] = $reader.GetString(1)    # Seconda colonna (ViewName)
            
            # Per la definizione della vista, gestisci eventuali NULL
            $row["ViewDefinition"] = if (!$reader.IsDBNull(2)) { $reader.GetString(2) } else { [string]::Empty }
            
            $dataTable.Rows.Add($row)
        }
        
        $reader.Close()
        
        Write-Log "Recuperate $($dataTable.Rows.Count) viste dal database $DatabaseName" -Level "SUCCESS"
        return $dataTable
    }
    catch {
        Write-Log "Errore nel recupero delle viste: $($_.Exception.Message)" -Level "ERROR"
        
        # Fallback al metodo INFORMATION_SCHEMA
        try {
            if ($connection.State -ne [System.Data.ConnectionState]::Open) {
                $connection.Open()
            }
            
            # Reset della tabella
            $dataTable = New-Object System.Data.DataTable
            $dataTable.Columns.Add("SchemaName", [string])
            $dataTable.Columns.Add("ViewName", [string])
            $dataTable.Columns.Add("ViewDefinition", [string])
            
            Write-Log "Tentativo con INFORMATION_SCHEMA.VIEWS..." -Level "WARNING"
            
            $fallbackQuery = @"
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY TABLE_SCHEMA, TABLE_NAME
"@
            
            $command = New-Object System.Data.SqlClient.SqlCommand($fallbackQuery, $connection)
            $reader = $command.ExecuteReader()
            
            while ($reader.Read()) {
                $row = $dataTable.NewRow()
                $row["SchemaName"] = $reader.GetString(0)
                $row["ViewName"] = $reader.GetString(1)
                
                # Gestisci eventuali NULL nella definizione
                $row["ViewDefinition"] = if (!$reader.IsDBNull(2)) { $reader.GetString(2) } else { [string]::Empty }
                
                $dataTable.Rows.Add($row)
            }
            
            $reader.Close()
            
            Write-Log "Recuperate $($dataTable.Rows.Count) viste usando INFORMATION_SCHEMA" -Level "SUCCESS"
            return $dataTable
        }
        catch {
            Write-Log "Anche il metodo alternativo è fallito: $($_.Exception.Message)" -Level "ERROR"
            
            # Restituisci un DataTable vuoto ma correttamente strutturato
            $emptyTable = New-Object System.Data.DataTable
            $emptyTable.Columns.Add("SchemaName", [string])
            $emptyTable.Columns.Add("ViewName", [string])
            $emptyTable.Columns.Add("ViewDefinition", [string])
            
            return $emptyTable
        }
    }
    finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
            Write-Log "Connessione chiusa" -Level "INFO"
        }
    }
}

# Funzione per verificare l'esistenza di una vista nel database destinazione
function Test-ViewExists {
    param(
        [string]$ConnectionString,
        [string]$SchemaName,
        [string]$ViewName
    )
    
    $query = @"
SELECT COUNT(*) FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name = '$SchemaName' AND v.name = '$ViewName'
"@
    
    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    
    try {
        $connection.Open()
        $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
        $result = $command.ExecuteScalar()
        
        return [int]$result -gt 0
    }
    catch {
        Write-Log "Errore nel verificare l'esistenza della vista [$SchemaName].[$ViewName]: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# Funzione per generare gli script SQL
function Generate-ViewScripts {
    param(
        [System.Data.DataTable]$Views,
        [string]$OutputFolder,
        [string]$DestinationConnectionString
    )
    
    if ($Views -eq $null -or $Views.Rows.Count -eq 0) {
        Write-Log "Nessuna vista da elaborare" -Level "WARNING"
        return $null
    }
    
    $masterScriptPath = Join-Path -Path $OutputFolder -ChildPath "00_master_script_viste.sql"
    
    # Crea lo script master
    @"
-- Script di creazione viste generato automaticamente
-- Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Database origine: $SourceDB
-- Database destinazione: $DestinationDB

USE [$DestinationDB]
GO

"@ | Out-File -FilePath $masterScriptPath -Force -Encoding UTF8
    
    Write-Log "Generazione script per $($Views.Rows.Count) viste..." -Level "INFO"
    
    $successCount = 0
    $errorCount = 0
    $skipCount = 0
    
    for ($i = 0; $i -lt $Views.Rows.Count; $i++) {
        try {
            $row = $Views.Rows[$i]
            
            if ($row["SchemaName"] -eq $null -or $row["ViewName"] -eq $null) {
                Write-Log "Riga $i  dati incompleti, schema o nome vista mancante" -Level "WARNING"
                $skipCount++
                continue
            }
            
            $schemaName = $row["SchemaName"].ToString().Trim()
            $viewName = $row["ViewName"].ToString().Trim()
            
            Write-Log "Elaborazione vista $($i+1)/$($Views.Rows.Count): [$schemaName].[$viewName]" -Level "INFO"
            
            # Se ViewDefinition è NULL o vuota, salta
            if ($row["ViewDefinition"] -eq $null -or $row["ViewDefinition"].ToString().Trim() -eq "") {
                Write-Log "  Vista [$schemaName].[$viewName] saltata: definizione mancante" -Level "WARNING"
                "[$schemaName].[$viewName] - SALTATA: definizione mancante" | Out-File -FilePath $LogFilePath -Append
                $skipCount++
                continue
            }
            
            $viewDefinition = $row["ViewDefinition"].ToString().Trim()

            # Fix: sostituisci il nome della vista nella definizione con il nome reale corrente
            # (necessario per viste rinominate con sp_rename dove OBJECT_DEFINITION conserva il nome originale)
            # Regex: schema opzionale ([schema]. o schema.) + nome vista ([nome] o nome senza spazi)
            $viewDefinition = $viewDefinition -replace '(?i)(CREATE\s+VIEW\s+)(\[[^\]]+\]\.|[\w]+\.)?(\[[^\]]+\]|[\w]+)', "`$1[$schemaName].[$viewName]"

            # Nome del file per lo script individuale
            $scriptFileName = "{0:D3}_{1}_{2}.sql" -f ($i+1), $schemaName, $viewName
            $scriptFilePath = Join-Path -Path $OutputFolder -ChildPath $scriptFileName
            
            # Verifica se la vista esiste già
            $viewExists = Test-ViewExists -ConnectionString $DestinationConnectionString -SchemaName $schemaName -ViewName $viewName
            
            # Genera lo script appropriato
            $scriptContent = ""
            
            if ($viewExists) {
                $scriptContent = @"
-- Vista [$schemaName].[$viewName] - Aggiornamento
-- Generato: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'$schemaName' AND v.name = N'$viewName')
BEGIN
    DROP VIEW [$schemaName].[$viewName]
    PRINT 'Vista [$schemaName].[$viewName] eliminata'
END
GO

-- Ricreazione vista
$viewDefinition
GO

PRINT 'Vista [$schemaName].[$viewName] creata con successo'
GO

"@
                Write-Log "  Vista già esistente, sarà ricreata" -Level "INFO"
            }
            else {
                $scriptContent = @"
-- Vista [$schemaName].[$viewName] - Creazione
-- Generato: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'$schemaName')
BEGIN
    EXEC('CREATE SCHEMA [$schemaName]')
    PRINT 'Schema [$schemaName] creato'
END
GO

-- Creazione vista
$viewDefinition
GO

PRINT 'Vista [$schemaName].[$viewName] creata con successo'
GO

"@
            }
            
            # Salva lo script individuale
            $scriptContent | Out-File -FilePath $scriptFilePath -Force -Encoding UTF8
            
            # Aggiungi riferimento allo script master
            ":r $scriptFileName" | Out-File -FilePath $masterScriptPath -Append -Encoding UTF8
            "GO" | Out-File -FilePath $masterScriptPath -Append -Encoding UTF8
            "" | Out-File -FilePath $masterScriptPath -Append -Encoding UTF8
            
            Write-Log "  Script generato: $scriptFileName" -Level "SUCCESS"
            $successCount++
        }
        catch {
            Write-Log "Errore nella generazione dello script per vista #$($i+1): $($_.Exception.Message)" -Level "ERROR"
            $errorCount++
        }
    }
    
    Write-Log "" -Level "INFO"
    Write-Log "=== RIEPILOGO GENERAZIONE SCRIPT ===" -Level "INFO"
    Write-Log "Script generati con successo: $successCount" -Level "SUCCESS"
    Write-Log "Script con errori: $errorCount" -Level "ERROR"
    Write-Log "Viste saltate: $skipCount" -Level "WARNING"
    Write-Log "Script master: $masterScriptPath" -Level "INFO"
    
    return $masterScriptPath
}

# Funzione per eseguire gli script SQL
function Execute-SqlScript {
    param(
        [string]$FilePath,
        [string]$ConnectionString,
        [string]$Description = ""
    )
    
    try {
        $scriptContent = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($scriptContent)) {
            Write-Log "Script vuoto: $FilePath" -Level "WARNING"
            return $false
        }
        
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        # Dividi lo script in batch separati da GO
        $batches = @()
        $currentBatch = ""
        
        foreach ($line in $scriptContent.Split("`n")) {
            $trimmedLine = $line.Trim()
            
            if ($trimmedLine -eq "GO") {
                if (-not [string]::IsNullOrWhiteSpace($currentBatch)) {
                    $batches += $currentBatch
                    $currentBatch = ""
                }
            }
            else {
                $currentBatch += "$line`n"
            }
        }
        
        # Aggiungi l'ultimo batch se non vuoto
        if (-not [string]::IsNullOrWhiteSpace($currentBatch)) {
            $batches += $currentBatch
        }
        
        # Esegui ogni batch
        foreach ($batch in $batches) {
            if (-not [string]::IsNullOrWhiteSpace($batch)) {
                $command = New-Object System.Data.SqlClient.SqlCommand($batch, $connection)
                $command.CommandTimeout = 120
                $command.ExecuteNonQuery() | Out-Null
            }
        }
        
        $connection.Close()
        return $true
    }
    catch {
        Write-Log "Errore nell'esecuzione dello script $Description`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Funzione per eseguire tutti gli script generati
function Execute-AllScripts {
    param(
        [string]$ScriptFolder,
        [string]$ConnectionString
    )
    
    $scriptFiles = Get-ChildItem -Path $ScriptFolder -Filter "*.sql" | Sort-Object Name
    
    if ($scriptFiles.Count -eq 0) {
        Write-Log "Nessuno script trovato nella cartella $ScriptFolder" -Level "WARNING"
        return
    }
    
    $totalScripts = $scriptFiles.Count
    $successCount = 0
    $errorCount = 0
    
    Write-Log "Inizio esecuzione di $totalScripts script..." -Level "INFO"
    
    foreach ($scriptFile in $scriptFiles) {
        # Salta il master script, verrà eseguito separatamente se necessario
        if ($scriptFile.Name -eq "00_master_script_viste.sql") {
            continue
        }
        
        Write-Log "Esecuzione: $($scriptFile.Name)" -Level "INFO"
        
        if (Execute-SqlScript -FilePath $scriptFile.FullName -ConnectionString $ConnectionString -Description $scriptFile.Name) {
            Write-Log "  Esecuzione completata con successo" -Level "SUCCESS"
            $successCount++
        }
        else {
            Write-Log "  Errore nell'esecuzione" -Level "ERROR"
            $errorCount++
        }
    }
    
    Write-Log "" -Level "INFO"
    Write-Log "=== RIEPILOGO ESECUZIONE SCRIPT ===" -Level "INFO"
    Write-Log "Script eseguiti con successo: $successCount" -Level "SUCCESS"
    Write-Log "Script falliti: $errorCount" -Level "ERROR"
    Write-Log "Totale script: $($totalScripts - 1)" -Level "INFO"
}

# MAIN SCRIPT

Write-Log "=== INIZIO MIGRAZIONE VISTE DA $SourceDB A $DestinationDB ===" -Level "INFO"

# Crea le stringhe di connessione
$sourceConnString = Get-ConnectionString -ServerName $ServerName -DatabaseName $SourceDB -Username $Username -Password $Password
$destConnString = Get-ConnectionString -ServerName $ServerName -DatabaseName $DestinationDB -Username $Username -Password $Password

# Test connessioni
Write-Log "Test connessione al database sorgente..." -Level "INFO"
if (-not (Test-SqlConnection -ConnectionString $sourceConnString -DatabaseName $SourceDB)) {
    Write-Log "Impossibile connettersi al database sorgente. Operazione annullata." -Level "ERROR"
    exit 1
}

Write-Log "Test connessione al database destinazione..." -Level "INFO"
if (-not (Test-SqlConnection -ConnectionString $destConnString -DatabaseName $DestinationDB)) {
    Write-Log "Impossibile connettersi al database destinazione. Operazione annullata." -Level "ERROR"
    exit 1
}

# Recupero delle viste dal database sorgente
$visteSorgente = Get-Views -ConnectionString $sourceConnString -DatabaseName $SourceDB

if ($visteSorgente -eq $null) {
    Write-Log "Impossibile recuperare le viste dal database sorgente. Operazione annullata." -Level "ERROR"
    exit 1
}

if ($visteSorgente.Rows.Count -eq 0) {
    Write-Log "Nessuna vista trovata nel database sorgente. Operazione annullata." -Level "WARNING"
    exit 0
}

# Mostra le prime 5 viste per verifica
$maxVisteVisualizzate = [Math]::Min(5, $visteSorgente.Rows.Count)
Write-Log "Elenco delle prime $maxVisteVisualizzate viste trovate:" -Level "INFO"

for ($i = 0; $i -lt $maxVisteVisualizzate; $i++) {
    try {
        $row = $visteSorgente.Rows[$i]
        
        if ($row -eq $null) {
            Write-Log "  Vista #$($i+1): Riga nulla" -Level "WARNING"
            continue
        }
        
        $schema = if ($row["SchemaName"] -ne $null) { $row["SchemaName"].ToString() } else { "schema sconosciuto" }
        $nome = if ($row["ViewName"] -ne $null) { $row["ViewName"].ToString() } else { "nome sconosciuto" }
        $def = if ($row["ViewDefinition"] -ne $null) { 
            $defText = $row["ViewDefinition"].ToString()
            if ($defText.Length > 80) {
                $defText = $defText.Substring(0, 80) + "..."
            }
            $defText
        } else { "definizione mancante" }
        
        Write-Log "  Vista #$($i+1): [$schema].[$nome] - $def" -Level "INFO"
    }
    catch {
        Write-Log "  Errore nell'accesso alla vista #$($i+1): $($_.Exception.Message)" -Level "ERROR"
    }
}

# Chiedi conferma per procedere
$continua = Read-Host "Trovate $($visteSorgente.Rows.Count) viste. Procedere con la generazione degli script? (S/N)"
if ($continua -ne "S" -and $continua -ne "s" -and $continua -ne "Y" -and $continua -ne "y") {
    Write-Log "Operazione annullata dall'utente." -Level "WARNING"
    exit 0
}

# Conversione a DataTable se necessario (spostata qui, nel MAIN SCRIPT)
if (-not ($visteSorgente -is [System.Data.DataTable])) {
    Write-Log "Il risultato non è un DataTable. Conversione in corso..." -Level "WARNING"
    
    $dataTableCorretto = New-Object System.Data.DataTable
    $null = $dataTableCorretto.Columns.Add("SchemaName", [string])
    $null = $dataTableCorretto.Columns.Add("ViewName", [string])
    $null = $dataTableCorretto.Columns.Add("ViewDefinition", [string])
    
    foreach ($vista in $visteSorgente) {
        if ($vista -ne $null) {
            $row = $dataTableCorretto.NewRow()
            if ($vista.PSObject.Properties.Name -contains 'SchemaName') { $row["SchemaName"] = $vista.SchemaName }
            if ($vista.PSObject.Properties.Name -contains 'ViewName') { $row["ViewName"] = $vista.ViewName }
            if ($vista.PSObject.Properties.Name -contains 'ViewDefinition') { $row["ViewDefinition"] = $vista.ViewDefinition }
            $null = $dataTableCorretto.Rows.Add($row)
        }
    }
    
    $visteSorgente = $dataTableCorretto
    Write-Log "Conversione completata. Viste convertite: $($visteSorgente.Rows.Count)" -Level "SUCCESS"
}

# Genera gli script SQL
$masterScript = Generate-ViewScripts -Views $visteSorgente -OutputFolder $ScriptOutputPath -DestinationConnectionString $destConnString

if ($masterScript -eq $null) {
    Write-Log "Generazione script non riuscita. Operazione annullata." -Level "ERROR"
    exit 1
}

# Chiedi conferma per eseguire gli script
$esegui = Read-Host "Eseguire gli script generati nel database destinazione? (S/N)"
if ($esegui -eq "S" -or $esegui -eq "s" -or $esegui -eq "Y" -or $esegui -eq "y") {
    Write-Log "Esecuzione degli script..." -Level "INFO"
    Execute-AllScripts -ScriptFolder $ScriptOutputPath -ConnectionString $destConnString
}
else {
    Write-Log "Esecuzione script annullata. Gli script sono disponibili in: $ScriptOutputPath" -Level "INFO"
}

Write-Log "=== MIGRAZIONE COMPLETATA ===" -Level "INFO"
Write-Log "Script disponibili in: $ScriptOutputPath" -Level "INFO"
Write-Log "Log dettagliato: $LogFilePath" -Level "INFO"