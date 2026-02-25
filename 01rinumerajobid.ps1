# Script per aggiornare IM_JobId nella tabella MA_Jobs per database specifici

# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Definizione dei database e dei loro incrementi
$databaseIncrements = @{
    "gpxnetclone" = 100000
    "furmanetclone" = 200000
    "vedbondifeclone" = 300000
    "vedmaster" = 400000
}

# Funzione per verificare l'esistenza del database
function Test-DatabaseExists {
    param (
        [string]$DatabaseName
    )
    
    try {
        $connectionString = "Server=$ServerInstance;Database=master;User Id=$SqlUsername;Password=$SqlPassword;"
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString

        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.CommandText = "SELECT COUNT(*) FROM sys.databases WHERE name = @dbName"
        $command.Parameters.AddWithValue("@dbName", $DatabaseName)
        $command.Connection = $connection

        $connection.Open()
        $exists = [int]$command.ExecuteScalar() -eq 1
        return $exists
    }
    catch {
        Write-Host "Errore nella verifica del database $DatabaseName" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# Funzione per eseguire l'update su un database
function Update-JobIds {
    param (
        [string]$DatabaseName,
        [int]$IncrementValue
    )
    
    try {
        # Verifica se il database esiste
        if (-not (Test-DatabaseExists -DatabaseName $DatabaseName)) {
            Write-Host "Il database $DatabaseName non esiste sul server" -ForegroundColor Yellow
            return
        }

        # Query SQL per l'update
        $updateQuery = @"
         -- Update MA_Jobs
        UPDATE dbo.MA_Jobs 
        SET IM_JobId = IM_JobId + $IncrementValue 
        WHERE IM_JobId IS NOT NULL;
        SELECT @@ROWCOUNT as JobsRowsAffected;

        -- Update IM_JobsDetails
        UPDATE dbo.IM_JobsDetails 
        SET JobId = JobId + $IncrementValue 
        WHERE JobId IS NOT NULL;
        SELECT @@ROWCOUNT as DetailsRowsAffected;
"@

        # Crea la connessione
        $connectionString = "Server=$ServerInstance;Database=$DatabaseName;User Id=$SqlUsername;Password=$SqlPassword;"
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString

        # Crea il comando
        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.CommandText = $updateQuery
        $command.Connection = $connection

        # Esegui l'update
        $connection.Open()
        $reader = $command.ExecuteReader()
        
        if ($reader.Read()) {
            $jobsAffected = $reader["JobsRowsAffected"]
            $reader.NextResult()
            $reader.Read()
            $detailsAffected = $reader["DetailsRowsAffected"]
            Write-Host "Database $DatabaseName (Incremento: $IncrementValue):" -ForegroundColor Green
            Write-Host "  - MA_Jobs: Aggiornate $jobsAffected righe" -ForegroundColor Green
            Write-Host "  - IM_JobsDetails: Aggiornate $detailsAffected righe" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Errore nell'aggiornamento del database $DatabaseName" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# Carica l'assembly SQL Client
Add-Type -AssemblyName System.Data

# Conferma prima di procedere
Write-Host "Si procederà con l'aggiornamento dei seguenti database:" -ForegroundColor Cyan
foreach ($db in $databaseIncrements.Keys) {
    Write-Host "- $db (Incremento: $($databaseIncrements[$db]))" -ForegroundColor Yellow
}

$confirm = Read-Host "`nVuoi procedere con l'aggiornamento? (S/N)"
if ($confirm -ne "S") {
    Write-Host "Operazione annullata" -ForegroundColor Yellow
    exit
}

# Esegui l'update per ogni database
Write-Host "`nInizio aggiornamento databases..." -ForegroundColor Yellow
foreach ($db in $databaseIncrements.Keys) {
    Write-Host "`nProcessing database: $db" -ForegroundColor Cyan
    Update-JobIds -DatabaseName $db -IncrementValue $databaseIncrements[$db]
}

Write-Host "`nOperazione completata!" -ForegroundColor Green