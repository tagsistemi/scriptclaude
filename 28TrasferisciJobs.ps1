# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Database di origine
$databases = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Database di destinazione
$DestinationDatabase = "vedmaster"

# Tabelle da trasferire
$tables = @("MA_Jobs",  "MA_JobsBalances" )

# Log dell'operazione
$LogFile = "TransferJobs_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    $logMessage | Out-File -FilePath $LogFile -Append
}

Write-Log "Inizio trasferimento tabelle Jobs"

try {
    # Prima di tutto, svuotiamo le tabelle di destinazione
    Write-Log "--- PULIZIA TABELLE DI DESTINAZIONE ---"
    foreach ($table in $tables) {
        Write-Log "Eliminazione record da tabella: $DestinationDatabase.$table"
        
        try {
            $deleteQuery = "DELETE FROM $DestinationDatabase.dbo.$table"
            Invoke-Sqlcmd -ServerInstance $ServerInstance -Username $SqlUsername -Password $SqlPassword -Query $deleteQuery -QueryTimeout 0 -TrustServerCertificate -Encrypt Optional
            Write-Log "Record eliminati con successo da $table"
        }
        catch {
            Write-Log "ERRORE durante l'eliminazione dei record da $table : $($_.Exception.Message)"
            Write-Host "ERRORE durante l'eliminazione dei record da $table : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Log "--- INIZIO TRASFERIMENTO DATI ---"
    foreach ($sourceDb in $databases) {
        Write-Log "Processando database di origine: $sourceDb"
        
        foreach ($table in $tables) {
            Write-Log "Trasferimento tabella: $table da $sourceDb a $DestinationDatabase"
            
            # Query per il trasferimento
            if ($table -eq "MA_Jobs") {
                # Per MA_Jobs filtriamo solo i record con Disabled = '0' e gestiamo le date
                $query = @"
INSERT INTO $DestinationDatabase.dbo.$table
SELECT * FROM $sourceDb.dbo.$table 
WHERE Disabled = '0' 
  AND (CreationDate IS NULL OR ISDATE(CreationDate) = 1)
  AND (LastModified IS NULL OR ISDATE(LastModified) = 1)
"@
            }
            elseif ($table -eq "MA_JobsBalances") {
                # Per MA_JobsBalances trasferiamo solo quelli legati a Job attivi
                $query = @"
INSERT INTO $DestinationDatabase.dbo.$table
SELECT jb.* FROM $sourceDb.dbo.$table jb
INNER JOIN $sourceDb.dbo.MA_Jobs j ON jb.Job = j.Job
WHERE j.Disabled = '0'
  AND (jb.Date IS NULL OR ISDATE(jb.Date) = 1)
"@
            }
            
            try {
                Write-Log "DEBUG: Preparazione query per $table..."
                
                # Prima verifichiamo quali colonne hanno problemi di data
                if ($table -eq "MA_Jobs") {
                    Write-Log "DEBUG: Controllo struttura tabella MA_Jobs..."
                    try {
                        $schemaQuery = @"
SELECT COLUMN_NAME, DATA_TYPE 
FROM $sourceDb.INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'MA_Jobs' AND DATA_TYPE IN ('datetime', 'smalldatetime', 'date')
ORDER BY COLUMN_NAME
"@
                        $dateColumns = Invoke-Sqlcmd -ServerInstance $ServerInstance -Username $SqlUsername -Password $SqlPassword -Query $schemaQuery -TrustServerCertificate -Encrypt Optional
                        Write-Log "DEBUG: Colonne di tipo data trovate: $($dateColumns.COLUMN_NAME -join ', ')"
                    } catch {
                        Write-Log "DEBUG: Errore nel controllo schema: $($_.Exception.Message)"
                    }
                }
                
                # Eseguiamo la query con gestione delle date più robusta
                Write-Log "DEBUG: Esecuzione query per $table..."
                $fullQuery = @"
SET DATEFORMAT ymd;
SET ANSI_WARNINGS OFF;
$query;
SET ANSI_WARNINGS ON;
"@
                
                Invoke-Sqlcmd -ServerInstance $ServerInstance -Username $SqlUsername -Password $SqlPassword -Query $fullQuery -QueryTimeout 0 -TrustServerCertificate -Encrypt Optional
                
                Write-Log "Trasferimento completato per $table da $sourceDb"
                
                # Verifica del numero di record trasferiti
                if ($table -eq "MA_Jobs") {
                    $countQuery = "SELECT COUNT(*) as RecordCount FROM $sourceDb.dbo.$table WHERE Disabled = '0'"
                }
                elseif ($table -eq "MA_JobsBalances") {
                    $countQuery = @"
SELECT COUNT(*) as RecordCount FROM $sourceDb.dbo.$table jb
INNER JOIN $sourceDb.dbo.MA_Jobs j ON jb.Job = j.Job
WHERE j.Disabled = '0'
"@
                }
                $recordCount = Invoke-Sqlcmd -ServerInstance $ServerInstance -Username $SqlUsername -Password $SqlPassword -Query $countQuery -TrustServerCertificate -Encrypt Optional
                Write-Log "Numero di record trasferiti: $($recordCount.RecordCount)"
                
            }
            catch {
                Write-Log "ERRORE durante il trasferimento di $table da $sourceDb : $($_.Exception.Message)"
                Write-Host "ERRORE durante il trasferimento di $table da $sourceDb : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Log "Trasferimento completato per tutti i database"
    
    # Riepilogo finale
    Write-Log "--- RIEPILOGO FINALE ---"
    foreach ($table in $tables) {
        try {
            $finalCountQuery = "SELECT COUNT(*) as TotalRecords FROM $DestinationDatabase.dbo.$table"
            $finalCount = Invoke-Sqlcmd -ServerInstance $ServerInstance -Username $SqlUsername -Password $SqlPassword -Query $finalCountQuery -TrustServerCertificate -Encrypt Optional
            Write-Log "Totale record in $DestinationDatabase.$table : $($finalCount.TotalRecords)"
        }
        catch {
            Write-Log "ERRORE nel conteggio finale per $table : $($_.Exception.Message)"
        }
    }
    
}
catch {
    Write-Log "ERRORE GENERALE: $($_.Exception.Message)"
    Write-Host "ERRORE GENERALE: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Log "Script completato"
Write-Host "Log salvato in: $LogFile" -ForegroundColor Green