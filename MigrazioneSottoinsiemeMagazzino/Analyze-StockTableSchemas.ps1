# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# File di log per il report
$LogFile = "e:\MigrazioneVed\Scripts\MigrazioneSottoinsiemeMagazzino\Analyze-StockTableSchemas_Report.txt"
"Report di analisi della struttura del database per il sottoinsieme MAGAZZINO generato il $(Get-Date)" | Set-Content -Path $LogFile

# Tabelle da analizzare
$TablesToAnalyze = @(
    "MA_CostAccEntries",
    "MA_CostAccEntriesDetail",
    "MA_FixAssetEntries",
    "MA_FixAssetEntriesDetail",
    "MA_ItemsFiscalData",
    "MA_ItemsMonthlyBalances",
    "MA_InventoryEntries",
    "MA_InventoryEntriesDetail",
    "MA_ReceiptsBatch",
    "MA_InventoryReasons"
)

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

Write-Host "Avvio analisi struttura tabelle MAGAZZINO..." -ForegroundColor Green

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
            CHARACTER_MAXIMUM_LENGTH,
            NUMERIC_PRECISION,
            NUMERIC_SCALE,
            COLLATION_NAME
        FROM $db.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = '$table'
"@
    }

    $fullQuery = $queryParts -join " UNION ALL "
    $fullQuery += " ORDER BY COLUMN_NAME, SourceDB"

    try {
        $results = Invoke-Sqlcmd -Query $fullQuery -ConnectionString $ConnectionString -ErrorAction Stop
        if (-not $results -or $results.Count -eq 0) {
            $warningMsg = "Nessuna informazione di schema trovata per la tabella '$table'."
            Write-Warning $warningMsg; $warningMsg | Add-Content -Path $LogFile; continue
        }

        $columnsGrouped = $results | Group-Object -Property COLUMN_NAME
        $destinationSchema = $results | Where-Object { $_.SourceDB -eq $DestinationDB }
        if (-not $destinationSchema -or $destinationSchema.Count -eq 0) {
            $msg = "[ERRORE] Tabella '$table' assente nel database di destinazione '$DestinationDB'."
            Write-Host $msg -ForegroundColor Red; $msg | Add-Content -Path $LogFile
            continue
        }

        foreach ($db in $SourceDBs) {
            $sourceSchema = $results | Where-Object { $_.SourceDB -eq $db }
            if (-not $sourceSchema -or $sourceSchema.Count -eq 0) {
                $msg = "[AVVISO] Database '$db', Tabella '$table': tabella assente."
                Write-Host $msg -ForegroundColor Magenta; $msg | Add-Content -Path $LogFile
                continue
            }
            $missingInSource = (Compare-Object -ReferenceObject $destinationSchema -DifferenceObject $sourceSchema -Property COLUMN_NAME -PassThru | Where-Object { $_.SideIndicator -eq "<=" }).COLUMN_NAME
            if ($missingInSource) {
                $msg = "[ERRORE] Database '$db', Tabella '$table': Colonne mancanti rispetto a '$DestinationDB':";
                Write-Host $msg -ForegroundColor Red; $msg | Add-Content -Path $LogFile
                $missingInSource | ForEach-Object { "  - $_" | Tee-Object -Variable _ | Add-Content -Path $LogFile }
            }
            $extraInSource = (Compare-Object -ReferenceObject $destinationSchema -DifferenceObject $sourceSchema -Property COLUMN_NAME -PassThru | Where-Object { $_.SideIndicator -eq "=>" }).COLUMN_NAME
            if ($extraInSource) {
                $msg = "[AVVISO] Database '$db', Tabella '$table': Colonne extra non presenti in '$DestinationDB':";
                Write-Host $msg -ForegroundColor Magenta; $msg | Add-Content -Path $LogFile
                $extraInSource | ForEach-Object { "  - $_" | Tee-Object -Variable _ | Add-Content -Path $LogFile }
            }
        }

        foreach ($group in $columnsGrouped) {
            $columnName = $group.Name
            $columnOccurrences = $group.Group
            $refColumn = $columnOccurrences | Where-Object { $_.SourceDB -eq $DestinationDB } | Select-Object -First 1
            if (-not $refColumn) { continue }

            foreach ($dbOccurrence in $columnOccurrences) {
                if ($dbOccurrence.SourceDB -eq $DestinationDB) { continue }
                if ($refColumn.DATA_TYPE -ne $dbOccurrence.DATA_TYPE) {
                    $msg = "[ERRORE] Tipo dato: Tabella '$table', Colonna '$columnName'";
                    Write-Host $msg -ForegroundColor Red; $msg | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $DestinationDB, $refColumn.DATA_TYPE) | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $dbOccurrence.SourceDB, $dbOccurrence.DATA_TYPE) | Add-Content -Path $LogFile
                }
                if ($refColumn.CHARACTER_MAXIMUM_LENGTH -ne $dbOccurrence.CHARACTER_MAXIMUM_LENGTH) {
                    $msg = "[ERRORE] Lunghezza: Tabella '$table', Colonna '$columnName'";
                    Write-Host $msg -ForegroundColor Red; $msg | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $DestinationDB, $refColumn.CHARACTER_MAXIMUM_LENGTH) | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $dbOccurrence.SourceDB, $dbOccurrence.CHARACTER_MAXIMUM_LENGTH) | Add-Content -Path $LogFile
                }
                if ($refColumn.COLLATION_NAME -ne $dbOccurrence.COLLATION_NAME) {
                    $msg = "[AVVISO] Collation: Tabella '$table', Colonna '$columnName'";
                    Write-Host $msg -ForegroundColor DarkYellow; $msg | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $DestinationDB, ($refColumn.COLLATION_NAME ?? 'NULL')) | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $dbOccurrence.SourceDB, ($dbOccurrence.COLLATION_NAME ?? 'NULL')) | Add-Content -Path $LogFile
                }
                if ($refColumn.IS_NULLABLE -ne $dbOccurrence.IS_NULLABLE) {
                    $msg = "[ERRORE] Nullability: Tabella '$table', Colonna '$columnName'";
                    Write-Host $msg -ForegroundColor Red; $msg | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $DestinationDB, $refColumn.IS_NULLABLE) | Add-Content -Path $LogFile
                    ("  - '{0}': {1}" -f $dbOccurrence.SourceDB, $dbOccurrence.IS_NULLABLE) | Add-Content -Path $LogFile
                }
                if ($refColumn.ORDINAL_POSITION -ne $dbOccurrence.ORDINAL_POSITION) {
                    $msg = "[ERRORE] Ordine colonna: Tabella '$table', Colonna '$columnName'";
                    Write-Host $msg -ForegroundColor Red; $msg | Add-Content -Path $LogFile
                    ("  - '{0}': Posizione {1}" -f $DestinationDB, $refColumn.ORDINAL_POSITION) | Add-Content -Path $LogFile
                    ("  - '{0}': Posizione {1}" -f $dbOccurrence.SourceDB, $dbOccurrence.ORDINAL_POSITION) | Add-Content -Path $LogFile
                }
                $isNumericDest = $refColumn.DATA_TYPE -in @('decimal','numeric')
                $isNumericSrc = $dbOccurrence.DATA_TYPE -in @('decimal','numeric')
                if ($isNumericDest -and $isNumericSrc) {
                    if ($refColumn.NUMERIC_PRECISION -ne $dbOccurrence.NUMERIC_PRECISION -or $refColumn.NUMERIC_SCALE -ne $dbOccurrence.NUMERIC_SCALE) {
                        $msg = "[ERRORE] Precisione/Scala: Tabella '$table', Colonna '$columnName'";
                        Write-Host $msg -ForegroundColor Red; $msg | Add-Content -Path $LogFile
                        ("  - '{0}': ({1},{2})" -f $DestinationDB, $refColumn.NUMERIC_PRECISION, $refColumn.NUMERIC_SCALE) | Add-Content -Path $LogFile
                        ("  - '{0}': ({1},{2})" -f $dbOccurrence.SourceDB, $dbOccurrence.NUMERIC_PRECISION, $dbOccurrence.NUMERIC_SCALE) | Add-Content -Path $LogFile
                    }
                }
            }
        }

    } catch {
        $err = "Errore durante l'analisi della tabella '$table': $_"; Write-Error $err; $err | Add-Content -Path $LogFile
    }
}

Write-Host "Analisi completata. Report in: $LogFile" -ForegroundColor Green
