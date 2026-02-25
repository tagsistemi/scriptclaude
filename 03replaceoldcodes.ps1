# Script per aggiornare i codici Job in tutte le tabelle correlate

# Parametri di connessione
$ServerInstance = "192.168.0.3\sql2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Database da processare 
$databases = @("vedbondifeclone", "furmanetclone")

# Lista delle tabelle da aggiornare con la loro colonna Job
$tables = @(
   "IM_JobsBalance",
   "IM_JobsComponents",
   "IM_JobsCostsRevenuesSummary",
   "IM_JobsDetailsVCL",
   "IM_JobsDocuments",
   "IM_JobsItems",
   "IM_JobsNotes",
   "IM_JobsSummaryByCompTypeByWorkingStep",
   "IM_JobsStatOfAccount"
   "IM_JobsWithholdingTax",
   "IM_JobsWorkingStep"
)

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
function Update-JobCodes {
   param (
       [string]$DatabaseName
   )

   try {
       # Verifica se il database esiste
       if (-not (Test-DatabaseExists -DatabaseName $DatabaseName)) {
           Write-Host "Il database $DatabaseName non esiste sul server" -ForegroundColor Yellow
           return
       }

       # Crea la connessione
       $connectionString = "Server=$ServerInstance;Database=$DatabaseName;User Id=$SqlUsername;Password=$SqlPassword;"
       $connection = New-Object System.Data.SqlClient.SqlConnection
       $connection.ConnectionString = $connectionString
       $connection.Open()

       foreach ($table in $tables) {
           try {
               # Step 1: Recupera le colonne PK diverse da Job
               $pkQuery = @"
               SELECT c.name AS ColumnName
               FROM sys.index_columns ic
               INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
               INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
               WHERE i.is_primary_key = 1
                 AND i.object_id = OBJECT_ID('dbo.$table')
                 AND c.name <> 'Job'
               ORDER BY ic.key_ordinal
"@
               $cmd = New-Object System.Data.SqlClient.SqlCommand($pkQuery, $connection)
               $reader = $cmd.ExecuteReader()
               $pkColumns = @()
               while ($reader.Read()) {
                   $pkColumns += $reader["ColumnName"].ToString()
               }
               $reader.Close()

               # Step 2: Elimina le righe con vecchio codice che andrebbero in conflitto PK
               $deletedRows = 0
               if ($pkColumns.Count -gt 0) {
                   $joinConditions = ($pkColumns | ForEach-Object { "old_row.[$_] = new_row.[$_]" }) -join " AND "
                   $deleteQuery = @"
                   DELETE old_row
                   FROM dbo.$table old_row
                   INNER JOIN dbo.MM4_MappaJobsCodes m ON old_row.Job = m.VecchioCodice
                   INNER JOIN dbo.$table new_row ON new_row.Job = m.NuovoCodice AND $joinConditions
                   WHERE m.VecchioCodice IS NOT NULL AND m.NuovoCodice IS NOT NULL;
                   SELECT @@ROWCOUNT as RowsAffected;
"@
               } else {
                   # PK composta solo da Job
                   $deleteQuery = @"
                   DELETE old_row
                   FROM dbo.$table old_row
                   INNER JOIN dbo.MM4_MappaJobsCodes m ON old_row.Job = m.VecchioCodice
                   WHERE EXISTS (SELECT 1 FROM dbo.$table WHERE Job = m.NuovoCodice)
                     AND m.VecchioCodice IS NOT NULL AND m.NuovoCodice IS NOT NULL;
                   SELECT @@ROWCOUNT as RowsAffected;
"@
               }

               $cmd = New-Object System.Data.SqlClient.SqlCommand($deleteQuery, $connection)
               $cmd.CommandTimeout = 120
               $reader = $cmd.ExecuteReader()
               if ($reader.Read()) {
                   $deletedRows = [int]$reader["RowsAffected"]
               }
               $reader.Close()

               # Step 3: Aggiorna le righe rimanenti
               $updateQuery = @"
               UPDATE dbo.$table
               SET Job = m.NuovoCodice
               FROM dbo.$table t
               INNER JOIN dbo.MM4_MappaJobsCodes m ON t.Job = m.VecchioCodice
               WHERE m.VecchioCodice IS NOT NULL AND m.NuovoCodice IS NOT NULL;
               SELECT @@ROWCOUNT as RowsAffected;
"@
               $cmd = New-Object System.Data.SqlClient.SqlCommand($updateQuery, $connection)
               $cmd.CommandTimeout = 120
               $reader = $cmd.ExecuteReader()
               $updatedRows = 0
               if ($reader.Read()) {
                   $updatedRows = [int]$reader["RowsAffected"]
               }
               $reader.Close()

               if ($deletedRows -gt 0) {
                   Write-Host "  - Tabella $table : Aggiornate $updatedRows righe (rimosse $deletedRows righe duplicate)" -ForegroundColor Green
               } else {
                   Write-Host "  - Tabella $table : Aggiornate $updatedRows righe" -ForegroundColor Green
               }
           }
           catch {
               Write-Host "  - Errore nell'aggiornamento della tabella $table" -ForegroundColor Red
               Write-Host "    " $_.Exception.Message -ForegroundColor Red
           }
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
Write-Host "Si procederà con l'aggiornamento dei JobId nei seguenti database:" -ForegroundColor Cyan
foreach ($db in $databases) {
   Write-Host "- $db" -ForegroundColor Yellow
   Write-Host "  Verranno aggiornate le seguenti tabelle:"
   $tables | ForEach-Object { Write-Host "  - $_" }
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
   Update-JobCodes -DatabaseName $db
}

Write-Host "`nOperazione completata!" -ForegroundColor Green