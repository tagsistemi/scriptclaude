
# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"

# Percorso del file di report da analizzare
$ReportFile = "e:\MigrazioneVed\Scripts\MigrazioneSottoinsiemeOrdiniFornitore\Analyze-PurchaseOrdTableSchemas_Report.txt"

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=$DestinationDB;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

Write-Host "Avvio dello script per la correzione della lunghezza delle colonne..." -ForegroundColor Cyan
Write-Host "Analisi del file di report: $ReportFile"

# Hashtable per memorizzare le modifiche necessarie: Key = "TableName.ColumnName", Value = { MaxLength = ..., DataType = ... }
$corrections = @{}

# Legge il contenuto del report
$reportContent = Get-Content -Path $ReportFile -Raw

# Regex per trovare i blocchi di errore di lunghezza
$regex = [regex]"(?ms)\[ERRORE\] Lunghezza: Tabella '(?<TableName>.+?)', Colonna '(?<ColumnName>.+?)'.+?- '(?<DBName>.+?)': (?<Length>\d+)"

$matches = $regex.Matches($reportContent)

if ($matches.Count -eq 0) {
    Write-Host "Nessun errore di lunghezza trovato nel report. Nessuna azione necessaria." -ForegroundColor Green
    exit
}

Write-Host "Trovati $($matches.Count) errori di lunghezza da analizzare..."

foreach ($match in $matches) {
    $tableName = $match.Groups['TableName'].Value
    $columnName = $match.Groups['ColumnName'].Value
    $dbName = $match.Groups['DBName'].Value
    $length = [int]$match.Groups['Length'].Value
    
    # Ignora il valore del DB di destinazione, ci interessa solo il massimo dei sorgenti
    if ($dbName -eq $DestinationDB) {
        continue
    }

    $key = "$tableName.$columnName"

    # Se la colonna non è ancora stata registrata, la aggiungiamo
    if (-not $corrections.ContainsKey($key)) {
        $corrections[$key] = @{ MaxLength = $length }
    }
    else {
        # Se la colonna esiste già, aggiorniamo la lunghezza solo se quella nuova è maggiore
        if ($length -gt $corrections[$key].MaxLength) {
            $corrections[$key].MaxLength = $length
        }
    }
}

Write-Host "Inizio applicazione delle correzioni sul database '$DestinationDB'..." -ForegroundColor Yellow

foreach ($key in $corrections.Keys) {
    $tableName = $key.Split('.')[0]
    $columnName = $key.Split('.')[1]
    $maxLength = $corrections[$key].MaxLength

    try {
        # 1. Ottieni il tipo di dato attuale e la nullability della colonna
        $typeQuery = "SELECT DATA_TYPE, IS_NULLABLE FROM $($DestinationDB).INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$tableName' AND COLUMN_NAME = '$columnName';"
        $columnInfo = Invoke-Sqlcmd -Query $typeQuery -ConnectionString $ConnectionString -ErrorAction Stop
        
        if (-not $columnInfo) {
            Write-Warning "Impossibile trovare informazioni per la colonna '$columnName' nella tabella '$tableName'. Salto."
            continue
        }
        
        $dataType = $columnInfo.DATA_TYPE
        $nullability = if ($columnInfo.IS_NULLABLE -eq 'YES') { 'NULL' } else { 'NOT NULL' }
        
        Write-Host "  - Informazioni colonna: Tipo=$dataType, Nullability=$nullability, Nuova lunghezza=$maxLength" -ForegroundColor Gray
        
        # Controlla se il tipo di dato è variabile (es. varchar, nvarchar)
        if ($dataType -notin @('varchar', 'nvarchar', 'char', 'nchar', 'varbinary')) {
            Write-Warning "La colonna '$columnName' in '$tableName' non è di un tipo di dato a lunghezza variabile (es. varchar). Lo script non la modificherà. Tipo trovato: $dataType."
            continue
        }

        # 2. Costruisci ed esegui la query di ALTER includendo la nullability
        $lengthForQuery = if ($maxLength -eq -1) { "MAX" } else { $maxLength }
        $alterQuery = "ALTER TABLE $($DestinationDB).dbo.$tableName ALTER COLUMN [$columnName] $dataType($lengthForQuery) $nullability;"
        
        Write-Host "  - Modifica colonna '$columnName' in tabella '$tableName' a $dataType($lengthForQuery) $nullability..." -ForegroundColor White
        Invoke-Sqlcmd -Query $alterQuery -ConnectionString $ConnectionString -ErrorAction Stop
        Write-Host "    -> OK" -ForegroundColor Green
    }
    catch {
        Write-Error "ERRORE durante la modifica della colonna '$columnName' nella tabella '$tableName'. Dettagli: $_"
    }
}

Write-Host "======================================="
Write-Host "PROCESSO DI CORREZIONE COMPLETATO." -ForegroundColor Cyan
