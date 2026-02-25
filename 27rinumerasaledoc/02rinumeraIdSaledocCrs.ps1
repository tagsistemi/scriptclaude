# Script per incrementare SaleDocId in diversi database
# VERSIONE CORRETTA: gestisce TUTTI i tipi documento di vendita (non solo DDT)
# Mapping DocumentType MA_SaleDoc -> Specie Archivio per TAG_CrMaps
$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Definizione delle tabelle da aggiornare (ordine importante: prima child tables, poi parent table)
$tables = @(
    # Child tables con foreign key verso MA_SaleDoc
    "MA_SaleDocDetail",
    "MA_SaleDocComponents",
    "MA_SaleDocManufReasons",
    "MA_SaleDocNotes",
    "MA_SaleDocPymtSched",
    "MA_SaleDocReferences",
    "MA_SaleDocShipping",
    "MA_SaleDocSummary",
    "MA_SaleDocTaxSummary",
    "MA_SaleDocDetailAccDef",              # AGGIUNTA: FK verso MA_SaleDoc
    "MA_SaleDocDetailVar",                 # AGGIUNTA: FK verso MA_SaleDoc
    "IM_SaleDocJobs",
    "MA_BRNotaFiscalForCustomer",
    "MA_BRNotaFiscalForCustDetail",
    "MA_BRNotaFiscalForCustSummary",
    "MA_BRNotaFiscalForCustRef",
    "MA_BRNotaFiscalForCustShipping",
    "MA_BRNotaFiscalForCustAdDat",         # AGGIUNTA: FK verso MA_SaleDoc
    # Tabelle Retail Management (commentare se non presenti nel DB)
    # "MA_RMSaleDoc",
    # "MA_RMSaleDocDetailDiscProm",
    # "MA_RMSaleDocDiscProm",
    # Tabelle senza foreign key diretta
    "MA_CostAccEntries",
    "MA_PurchaseDocDetail",
    "IM_Schedules",
    "MA_WMPreShippingDetails",
    # Parent table - deve essere aggiornata per ULTIMA
    "MA_SaleDoc"
)

# Definizione dei database e relativi incrementi
 $databaseConfigs = @{
  "gpxnetclone" = 400000
  "furmanetclone" = 200000
  "vedbondifeclone" = 300000
}

# Tutte le Specie Archivio (EnumValue) relative a documenti di vendita
# Usate per filtrare TAG_CrMaps e per il matching con TAG_DocumentTypesCr nello script 19
$saleDocEnumValues = @(
    3801088,  # DDT
    3801089,  # Reso da Cliente
    3801090,  # DDT per Lavorazione Esterna
    3801091,  # Fattura Accompagnatoria
    3801094,  # Fattura Accompagnatoria a Correzione
    3801095,  # Fattura Immediata
    3801096,  # Fattura a Correzione
    3801097,  # Nota di Credito
    3801101,  # Nota di Debito
    3801102,  # Fattura di Acconto
    3801103,  # Fattura ProForma
    3801104,  # Ricevuta Fiscale
    3801105,  # Ricevuta Fiscale a Correzione
    3801106,  # Ricevuta Fiscale Non Incassata
    3801107,  # Paragon
    3801108,  # Paragon a Correzione
    3801110   # Trasferimento tra Depositi
)
$saleDocEnumValuesSQL = $saleDocEnumValues -join ", "


function Execute-SqlQuery {
   param (
       [string]$server,
       [string]$database,
       [string]$query,
       [string]$username,
       [string]$password
   )

   $connectionString = "Server=$server;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
   $connection = New-Object System.Data.SqlClient.SqlConnection
   $connection.ConnectionString = $connectionString

   $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
   $command.CommandTimeout = 300

   try {
       [System.Data.SqlClient.SqlConnection]::ClearAllPools()
       $connection.Open()
       $command.ExecuteNonQuery()
   }
   catch {
       Write-Error $_.Exception.Message
       throw $_
   }
   finally {
       if ($connection.State -eq [System.Data.ConnectionState]::Open) {
           $connection.Close()
       }
   }
}

# Funzione per abilitare/disabilitare i vincoli
function Set-ForeignKeyConstraints {
    param (
        [string]$database,
        [string]$action # "NOCHECK" per disabilitare, "CHECK" per abilitare
    )

    $getConstraintsQuery = @"
    USE [$database];
    SELECT
        'ALTER TABLE [' + OBJECT_NAME(fk.parent_object_id) + '] ' +
        (CASE WHEN '$action' = 'NOCHECK' THEN 'NOCHECK' ELSE 'WITH CHECK CHECK' END) +
        ' CONSTRAINT [' + fk.name + ']'
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE OBJECT_NAME(fk.referenced_object_id) = 'MA_SaleDoc'
      AND COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) = 'SaleDocId';
"@

    $connectionString = "Server=$sqlServer;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $command = New-Object System.Data.SqlClient.SqlCommand($getConstraintsQuery, $connection)
    $command.CommandTimeout = 300

    try {
        $connection.Open()
        $reader = $command.ExecuteReader()
        $queries = @()
        while ($reader.Read()) {
            $queries += $reader.GetString(0)
        }
        $reader.Close()

        foreach ($query in $queries) {
            Write-Host "Executing: $query"
            Execute-SqlQuery -server $sqlServer -database $database -query $query -username $username -password $password
        }
        Write-Host "Successfully set foreign key constraints to $action in $database" -ForegroundColor Green
    }
    catch {
        Write-Host "Error setting foreign key constraints in $database : $_" -ForegroundColor Red
        throw
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# Funzione principale per rinumerare SaleDocId
function Update-SaleDocId {
   param (
       $database,
       $increment
   )
   Write-Host "Processing database: $database with increment: $increment"

   # Crea la tabella TAG_CrMaps se non esiste
   $createTableQuery = @"
   USE [$database]
   IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAG_CrMaps]') AND type in (N'U'))
   BEGIN
       CREATE TABLE [dbo].[TAG_CrMaps](
           [OldId] [int] NOT NULL,
           [DocumentType] [int] NOT NULL,
           [NewDocId] [int] NOT NULL
       )
   END
"@

   try {
       Execute-SqlQuery -server $sqlServer -database "master" -query $createTableQuery -username $username -password $password
       Write-Host "Successfully created or verified TAG_CrMaps table in $database" -ForegroundColor Green
   }
   catch {
       Write-Host "Error creating TAG_CrMaps table in $database : $_" -ForegroundColor Red
       return
   }

   # Inserisci i mapping prima dell'update
   # CASE mappa MA_SaleDoc.DocumentType (34xxxxx) -> Specie Archivio (38xxxxx)
   # La Specie Archivio corrisponde a TAG_DocumentTypesCr.EnumValue
   # necessaria per aggiornare correttamente i CrossReferences (script 19)
   $insertMappingQuery = @"
   USE [$database]
   BEGIN TRY
       BEGIN TRANSACTION;

       -- Elimina i record esistenti per TUTTI i tipi documento di vendita
       DELETE FROM TAG_CrMaps
       WHERE DocumentType IN ($saleDocEnumValuesSQL);

       -- Inserisci i mapping per TUTTI i tipi documento di vendita
       -- CASE: MA_SaleDoc.DocumentType -> Specie Archivio (EnumValue TAG_DocumentTypesCr)
       INSERT INTO TAG_CrMaps (OldId, DocumentType, NewDocId)
       SELECT
           SaleDocId as OldId,
           CASE DocumentType
               WHEN 3407873 THEN 3801088  -- DDT (Documento di Trasporto)
               WHEN 3407874 THEN 3801095  -- Fattura Accompagnatoria (RefCode 27066387)
               WHEN 3407875 THEN 3801091  -- Fattura Immediata (RefCode 27066385)
               WHEN 3407876 THEN 3801097  -- Nota di Credito
               WHEN 3407877 THEN 3801101  -- Nota di Debito
               WHEN 3407878 THEN 3801104  -- Ricevuta Fiscale
               WHEN 3407879 THEN 3801105  -- Ricevuta Fiscale a Correzione
               WHEN 3407880 THEN 3801106  -- Ricevuta Fiscale Non Incassata
               WHEN 3407881 THEN 3801107  -- Paragon
               WHEN 3407882 THEN 3801108  -- Paragon a Correzione
               WHEN 3407883 THEN 3801102  -- Fattura di Acconto
               WHEN 3407884 THEN 3801103  -- Fattura ProForma
               WHEN 3407885 THEN 3801094  -- Fattura Accompagnatoria a Correzione
               WHEN 3407886 THEN 3801096  -- Fattura a Correzione
               WHEN 3407887 THEN 3801089  -- Reso da Cliente
               WHEN 3407888 THEN 3801090  -- DDT per Lavorazione Esterna
               WHEN 3407889 THEN 3801110  -- Trasferimento tra Depositi
           END as DocumentType,
           SaleDocId + $increment as NewDocId
       FROM MA_SaleDoc
       WHERE SaleDocId IS NOT NULL
         AND DocumentType BETWEEN 3407873 AND 3407889;

       -- Verifica: segnala eventuali DocumentType non mappati
       IF EXISTS (
           SELECT 1 FROM MA_SaleDoc
           WHERE SaleDocId IS NOT NULL
             AND DocumentType NOT BETWEEN 3407873 AND 3407889
             AND DocumentType > 0
       )
       BEGIN
           PRINT 'ATTENZIONE: Esistono record in MA_SaleDoc con DocumentType fuori dal range 3407873-3407889!'
           PRINT 'Verificare se necessitano di rinumerazione.'
       END

       COMMIT TRANSACTION;
   END TRY
   BEGIN CATCH
       IF @@TRANCOUNT > 0
           ROLLBACK TRANSACTION;

       DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
       DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
       DECLARE @ErrorState INT = ERROR_STATE();

       RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
   END CATCH
"@

   try {
       Execute-SqlQuery -server $sqlServer -database "master" -query $insertMappingQuery -username $username -password $password
       Write-Host "Successfully inserted mappings in $database" -ForegroundColor Green
   }
   catch {
       Write-Host "Error inserting mappings in $database : $_" -ForegroundColor Red
       return
   }

   # --- INIZIO AGGIORNAMENTO ---
   try {
       # 1. Disabilita i vincoli
       Write-Host "Disabling foreign key constraints in $database..."
       Set-ForeignKeyConstraints -database $database -action "NOCHECK"

       # 2. Aggiorna prima la tabella parent (MA_SaleDoc)
       $updateParentQuery = @"
       USE [$database]
       UPDATE MA_SaleDoc WITH (ROWLOCK)
       SET SaleDocId = SaleDocId + $increment
       WHERE SaleDocId IN (SELECT OldId FROM TAG_CrMaps WHERE DocumentType IN ($saleDocEnumValuesSQL))
"@
       try {
           Execute-SqlQuery -server $sqlServer -database $database -query $updateParentQuery -username $username -password $password
           Write-Host "Successfully updated table MA_SaleDoc in $database" -ForegroundColor Green
       }
       catch {
           Write-Host "Error updating parent table MA_SaleDoc in $database : $_" -ForegroundColor Red
           throw
       }

       # 3. Aggiorna le tabelle child
       $childTables = $tables | Where-Object { $_ -ne "MA_SaleDoc" }
       foreach ($table in $childTables) {
           # Controlla se la tabella esiste nel database
           $checkTableQuery = @"
           USE [$database]
           SELECT COUNT(*) FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[$table]') AND type in (N'U')
"@
           $connectionString = "Server=$sqlServer;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
           $checkConn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
           $checkCmd = New-Object System.Data.SqlClient.SqlCommand($checkTableQuery, $checkConn)
           $checkCmd.CommandTimeout = 300
           try {
               $checkConn.Open()
               $tableExists = $checkCmd.ExecuteScalar()
           }
           finally {
               if ($checkConn.State -eq [System.Data.ConnectionState]::Open) { $checkConn.Close() }
           }

           if ($tableExists -eq 0) {
               Write-Host "Table $table does not exist in $database - skipping" -ForegroundColor Yellow
               continue
           }

           $updateQuery = @"
           USE [$database]
           UPDATE $table WITH (ROWLOCK)
           SET SaleDocId = SaleDocId + $increment
           WHERE SaleDocId IN (SELECT OldId FROM TAG_CrMaps WHERE DocumentType IN ($saleDocEnumValuesSQL))
"@
           try {
               Execute-SqlQuery -server $sqlServer -database $database -query $updateQuery -username $username -password $password
               Write-Host "Successfully updated table $table in $database" -ForegroundColor Green
           }
           catch {
               Write-Host "Error updating table $table in $database : $_" -ForegroundColor Red
               throw # Rilancia l'eccezione per fermare l'esecuzione e andare al blocco finally
           }
       }
   }
   catch {
        Write-Host "An error occurred during the update process. Constraints might be disabled." -ForegroundColor Yellow
   }
   finally {
       # 4. Riabilita i vincoli, anche in caso di errore
       Write-Host "Re-enabling foreign key constraints in $database..."
       Set-ForeignKeyConstraints -database $database -action "CHECK"
   }
   # --- FINE AGGIORNAMENTO ---
}

# Main execution
Write-Host "Starting database updates..."
[System.Data.SqlClient.SqlConnection]::ClearAllPools()
foreach ($dbConfig in $databaseConfigs.GetEnumerator()) {
   Update-SaleDocId -database $dbConfig.Key -increment $dbConfig.Value
}
Write-Host "All database updates completed."
