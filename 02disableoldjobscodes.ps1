# Script per disabilitare jobs basati su vecchi codici

# Parametri di connessione
$ServerInstance = "192.168.0.3\sql2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Database da processare 
$databases = @("vedbondifeclone", "furmanetclone")

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
function Update-DisabledJobs {
   param (
       [string]$DatabaseName
   )
   
   try {
       # Verifica se il database esiste
       if (-not (Test-DatabaseExists -DatabaseName $DatabaseName)) {
           Write-Host "Il database $DatabaseName non esiste sul server" -ForegroundColor Yellow
           return
       }

       # Query SQL per l'update
       $updateQuery = @"
       -- Update MA_Jobs based on MM4_MappaJobsCodes.VecchioCodice
       UPDATE dbo.MA_Jobs 
       SET Disabled = '1'
       WHERE Job IN (
           SELECT VecchioCodice 
           FROM dbo.MM4_MappaJobsCodes 
           WHERE VecchioCodice IS NOT NULL
       );
       SELECT @@ROWCOUNT as JobsRowsAffected;
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
           Write-Host "Database ${DatabaseName}:" -ForegroundColor Green
           Write-Host "  - Jobs disabilitati: $jobsAffected" -ForegroundColor Green
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
Write-Host "Si procederà con la disabilitazione dei jobs nei seguenti database:" -ForegroundColor Cyan
foreach ($db in $databases) {
   Write-Host "- $db" -ForegroundColor Yellow
}

$confirm = Read-Host "`nVuoi procedere con l'aggiornamento? (S/N)"
if ($confirm -ne "S") {
   Write-Host "Operazione annullata" -ForegroundColor Yellow
   exit
}

# Esegui l'update per ogni database
Write-Host "`nInizio aggiornamento databases..." -ForegroundColor Yellow
foreach ($db in $databases) {
   Write-Host "`nProcessing database: $db" -ForegroundColor Cyan
   Update-DisabledJobs -DatabaseName $db
}

Write-Host "`nOperazione completata!" -ForegroundColor Green