# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$CsvFile = "commesse duplicate.CSV"

# Mapping tra i nomi nel CSV e i nomi dei database effettivi
$databaseMapping = @{
    "FurmaNet" = "furmanetclone"
    "VEDBondife" = "vedbondifeclone"
}

# Funzione per eseguire una query SQL
function Execute-SqlQuery {
    param (
        [string]$database,
        [string]$query
    )
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server=$ServerInstance;Database=$database;User Id=$SqlUsername;Password=$SqlPassword;"
        $conn.Open()
        
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 0
        
        $rowsAffected = $cmd.ExecuteNonQuery()
        Write-Host "Query eseguita con successo su $database. Righe modificate: $rowsAffected"
        return $true
    }
    catch {
        Write-Error "Errore nell'esecuzione della query su $database : $_"
        return $false
    }
    finally {
        if ($conn -and $conn.State -eq 'Open') {
            $conn.Close()
        }
    }
}

# Script per creare/pulire la tabella
$createTableQuery = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_MappaJobsCodes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[MM4_MappaJobsCodes](
        [db] [varchar](50) NULL,
        [vecchiocodice] [varchar](20) NULL,
        [nuovocodice] [varchar](20) NULL
    ) ON [PRIMARY]
END
ELSE
BEGIN
    TRUNCATE TABLE [dbo].[MM4_MappaJobsCodes]
END
"@

# Crea/pulisci la tabella in ogni database
foreach ($targetDb in $databaseMapping.Values) {
    Write-Host "`nProcessando database: $targetDb"
    Write-Host "Controllo/creazione tabella..."
    Execute-SqlQuery -database $targetDb -query $createTableQuery
}

# Leggi il file CSV
Write-Host "`nLettura file CSV..."
$csvContent = Get-Content $CsvFile -Encoding UTF8 | Select-Object -Skip 1  # Skip dell'header

# Raggruppa i dati per database di destinazione
$groupedData = @{}
foreach ($line in $csvContent) {
    $fields = $line -split ";"
    if ($fields.Count -ge 3) {
        $sourceDb = $fields[0].Trim()
        $vecchiocodice = $fields[1].Trim()
        $nuovocodice = $fields[2].Trim()
        
        # Escape single quotes in values
        $sourceDb = $sourceDb -replace "'", "''"
        $vecchiocodice = $vecchiocodice -replace "'", "''"
        $nuovocodice = $nuovocodice -replace "'", "''"
        
        # Inserisci solo nel database corrispondente
        if ($databaseMapping.ContainsKey($sourceDb)) {
            $targetDb = $databaseMapping[$sourceDb]
            if (-not $groupedData.ContainsKey($targetDb)) {
                $groupedData[$targetDb] = @()
            }
            $groupedData[$targetDb] += "('$sourceDb', '$vecchiocodice', '$nuovocodice')"
        }
    }
}

# Inserisci i dati in ogni database
foreach ($targetDb in $groupedData.Keys) {
    $values = $groupedData[$targetDb]
    if ($values.Count -gt 0) {
        Write-Host "`nInserimento dati nel database $targetDb..."
        
        $insertQuery = "INSERT INTO [dbo].[MM4_MappaJobsCodes] ([db], [vecchiocodice], [nuovocodice]) VALUES`n"
        $insertQuery += $values -join ",`n"
        
        Execute-SqlQuery -database $targetDb -query $insertQuery
    }
}

Write-Host "`nOperazione completata!"