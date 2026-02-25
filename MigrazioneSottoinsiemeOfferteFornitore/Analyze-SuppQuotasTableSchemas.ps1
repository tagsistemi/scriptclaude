# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# File di log per il report
$LogFile = "e:\MigrazioneVed\Scripts\MigrazioneSottoinsiemeOfferteFornitore\Analyze-SuppQuotasTableSchemas_Report.txt"
# Inizializza/Pulisce il file di log all'inizio dell'esecuzione
"Report di analisi della struttura del database per MA_SuppQuotas generato il $(Get-Date)" | Set-Content -Path $LogFile

# Tabelle da analizzare
$TablesToAnalyze = @(
    "MA_SuppQuotas",
    "MA_SuppQuotasDetail",
    "MA_SuppQuotasNote",
    "MA_SuppQuotasReference",
    "MA_SuppQuotasShipping",
    "MA_SuppQuotasTaxSummary"
)

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

Write-Host "Avvio dell'analisi della struttura delle tabelle per MA_SuppQuotas..." -ForegroundColor Green

foreach ($table in $TablesToAnalyze) {
    Write-Host "------------------------------------------------------------"
    Write-Host "Analisi tabella: $table" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------"

    $allDBs = @($DestinationDB) + $SourceDBs
    $queryParts = @()

    foreach ($db in $allDBs) {
        $queryParts += @"
        SELECT 
            '$db' as SourceDB,
            TABLE_NAME, 
            COLUMN_NAME, 
            ORDINAL_POSITION,
            DATA_TYPE, 
            IS_NULLABLE,
            CHARACTER_MAXIMUM_LENGTH
        FROM $db.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = '$table'
"@
    }

    $fullQuery = $queryParts -join " UNION ALL "
    $fullQuery += " ORDER BY COLUMN_NAME, SourceDB"

    try {
        # Esegue la query per ottenere gli schemi
        $results = Invoke-Sqlcmd -Query $fullQuery -ConnectionString $ConnectionString -ErrorAction Stop
        
        if (-not $results -or $results.Count -eq 0) {
            $warningMsg = "Nessuna informazione di schema trovata per la tabella '$table' in nessuno dei database."
            Write-Warning $warningMsg
            $warningMsg | Add-Content -Path $LogFile
            continue
        }

        # Raggruppa i risultati per nome colonna
        $columnsGrouped = $results | Group-Object -Property COLUMN_NAME

        # Schema di riferimento (dal DB di destinazione)
        $destinationSchema = $results | Where-Object { $_.SourceDB -eq $DestinationDB }

        # Confronta le colonne dei sorgenti con quelle di destinazione
        foreach ($db in $SourceDBs) {
            $sourceSchema = $results | Where-Object { $_.SourceDB -eq $db }
            
            # 1. Colonne mancanti nel sorgente (presenti in destinazione ma non nel sorgente)
            $missingInSource = (Compare-Object -ReferenceObject $destinationSchema -DifferenceObject $sourceSchema -Property COLUMN_NAME -PassThru | Where-Object { $_.SideIndicator -eq "<=" }).COLUMN_NAME
            if ($missingInSource) {
                $errorMsg = "[ERRORE] Database '$db', Tabella '$table': Colonne mancanti rispetto a '$DestinationDB':"
                Write-Host $errorMsg -ForegroundColor Red
                $errorMsg | Add-Content -Path $LogFile
                $missingInSource | ForEach-Object { 
                    $colMsg = "  - $_"
                    Write-Host $colMsg
                    $colMsg | Add-Content -Path $LogFile
                }
            }

            # 2. Colonne extra nel sorgente (presenti nel sorgente ma non in destinazione)
            $extraInSource = (Compare-Object -ReferenceObject $destinationSchema -DifferenceObject $sourceSchema -Property COLUMN_NAME -PassThru | Where-Object { $_.SideIndicator -eq "=>" }).COLUMN_NAME
            if ($extraInSource) {
                $warningMsg = "[AVVISO] Database '$db', Tabella '$table': Colonne extra non presenti in '$DestinationDB':"
                Write-Host $warningMsg -ForegroundColor Magenta
                $warningMsg | Add-Content -Path $LogFile
                $extraInSource | ForEach-Object {
                    $colMsg = "  - $_"
                    Write-Host $colMsg
                    $colMsg | Add-Content -Path $LogFile
                }
            }
        }

        foreach ($group in $columnsGrouped) {
            $columnName = $group.Name
            $columnOccurrences = $group.Group

            # Schema di riferimento per questa colonna
            $refColumn = $columnOccurrences | Where-Object { $_.SourceDB -eq $DestinationDB } | Select-Object -First 1

            if (-not $refColumn) {
                # La colonna non esiste nel DB di destinazione, già segnalato come "extra"
                continue
            }

            foreach ($dbOccurrence in $columnOccurrences) {
                if ($dbOccurrence.SourceDB -eq $DestinationDB) { continue }

                # 3. Confronto Tipi di dato
                if ($refColumn.DATA_TYPE -ne $dbOccurrence.DATA_TYPE) {
                    $errorMsg = "[ERRORE] Tipo dato: Tabella '$table', Colonna '$columnName'"
                    Write-Host $errorMsg -ForegroundColor Red
                    $errorMsg | Add-Content -Path $LogFile
                    $detailMsg1 = "  - '$($DestinationDB)': $($refColumn.DATA_TYPE)"
                    $detailMsg2 = "  - '$($dbOccurrence.SourceDB)': $($dbOccurrence.DATA_TYPE)"
                    Write-Host $detailMsg1
                    Write-Host $detailMsg2
                    $detailMsg1 | Add-Content -Path $LogFile
                    $detailMsg2 | Add-Content -Path $LogFile
                }

                # 4. Confronto Lunghezza
                if ($refColumn.CHARACTER_MAXIMUM_LENGTH -ne $dbOccurrence.CHARACTER_MAXIMUM_LENGTH) {
                    $errorMsg = "[ERRORE] Lunghezza: Tabella '$table', Colonna '$columnName'"
                    Write-Host $errorMsg -ForegroundColor Red
                    $errorMsg | Add-Content -Path $LogFile
                    $detailMsg1 = "  - '$($DestinationDB)': $($refColumn.CHARACTER_MAXIMUM_LENGTH)"
                    $detailMsg2 = "  - '$($dbOccurrence.SourceDB)': $($dbOccurrence.CHARACTER_MAXIMUM_LENGTH)"
                    Write-Host $detailMsg1
                    Write-Host $detailMsg2
                    $detailMsg1 | Add-Content -Path $LogFile
                    $detailMsg2 | Add-Content -Path $LogFile
                }

                # 5. Confronto Nullability
                if ($refColumn.IS_NULLABLE -ne $dbOccurrence.IS_NULLABLE) {
                    $errorMsg = "[ERRORE] Nullability: Tabella '$table', Colonna '$columnName'"
                    Write-Host $errorMsg -ForegroundColor Red
                    $errorMsg | Add-Content -Path $LogFile
                    $detailMsg1 = "  - '$($DestinationDB)': $($refColumn.IS_NULLABLE)"
                    $detailMsg2 = "  - '$($dbOccurrence.SourceDB)': $($dbOccurrence.IS_NULLABLE)"
                    Write-Host $detailMsg1
                    Write-Host $detailMsg2
                    $detailMsg1 | Add-Content -Path $LogFile
                    $detailMsg2 | Add-Content -Path $LogFile
                }
                
                # 6. Confronto Ordine Colonne
                if ($refColumn.ORDINAL_POSITION -ne $dbOccurrence.ORDINAL_POSITION) {
                    $errorMsg = "[ERRORE] Ordine colonna: Tabella '$table', Colonna '$columnName'"
                    Write-Host $errorMsg -ForegroundColor Red
                    $errorMsg | Add-Content -Path $LogFile
                    $detailMsg1 = "  - '$($DestinationDB)': Posizione $($refColumn.ORDINAL_POSITION)"
                    $detailMsg2 = "  - '$($dbOccurrence.SourceDB)': Posizione $($dbOccurrence.ORDINAL_POSITION)"
                    Write-Host $detailMsg1
                    Write-Host $detailMsg2
                    $detailMsg1 | Add-Content -Path $LogFile
                    $detailMsg2 | Add-Content -Path $LogFile
                }
            }
        }

    }
    catch {
        $errorMsg = "Errore durante l'analisi della tabella '$table': $_"
        Write-Error $errorMsg
        $errorMsg | Add-Content -Path $LogFile
    }
}

Write-Host "------------------------------------------------------------"
Write-Host "Analisi completata. Report disponibile in: $LogFile" -ForegroundColor Green
