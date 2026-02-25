# Requires -Modules SqlServer

# Analisi strutture tabelle per il sottoinsieme "Commesse"
# Tabelle: MA_JobGroups, MA_Jobs, MA_JobsBalances, MA_JobsParameters
# Confronta: tipo, lunghezza, nullability, posizione, precisione/scala, collation.
# Segnala colonne mancanti/in più e tabelle assenti nei sorgenti.

$ErrorActionPreference = 'Stop'

# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Costruisce la stringa di connessione (abilita Encrypt per evitare negoziazioni legacy quando possibile)
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;Encrypt=True;TrustServerCertificate=True;"

$Tables = @(
    'MA_JobGroups',
    'MA_Jobs',
    'MA_JobsBalances',
    'MA_JobsParameters'
)

# Output report
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$reportPath = Join-Path $PSScriptRoot ("ANALISI_STRUTTURA_TABELLE_COMMESSE_" + $timestamp + ".txt")
("Analisi strutture (Commesse) eseguita: " + (Get-Date)) | Out-File -FilePath $reportPath -Encoding UTF8

function Get-Columns($dbName, $table) {
    $tableLit = ($table -replace "'", "''")
    $q = @"
    SELECT
        TABLE_NAME,
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE,
        ORDINAL_POSITION,
        NUMERIC_PRECISION,
        NUMERIC_SCALE,
        COLLATION_NAME
    FROM [$dbName].INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = N'$tableLit'
    ORDER BY ORDINAL_POSITION
"@
    Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $q
}

function Test-TableExists($dbName, $table) {
    $tableLit = ($table -replace "'", "''")
    $q = "SELECT 1 FROM [$dbName].INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME=N'$tableLit'"
    $r = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $q
    return ($r -and $r.Count -gt 0)
}

foreach ($table in ($Tables | Sort-Object)) {
    Add-Content -Path $reportPath -Value ("`n== Tabella: " + $table + " ==")

    # Verifica presenza tabella per ogni DB (VEDMaster prima, poi sorgenti ordinati)
    $dbsToCheck = @($DestinationDB) + ($SourceDBs | Sort-Object)
    foreach ($db in $dbsToCheck) {
        if (-not (Test-TableExists -dbName $db -table $table)) {
            Add-Content -Path $reportPath -Value ("[ASSENTE] Tabella " + $table + " assente in " + $db)
        }
    }

    # Carica colonne per ciascun db
    $destCols = Get-Columns -dbName $DestinationDB -table $table
    foreach ($srcDb in ($SourceDBs | Sort-Object)) {
        $srcCols = Get-Columns -dbName $srcDb -table $table

        if (-not $destCols -and -not $srcCols) {
            Add-Content -Path $reportPath -Value ("[INFO] Nessuna informazione colonne in " + $DestinationDB + " e " + $srcDb)
            continue
        }

        # Indici per confronto by column name
        $destByName = @{}
        foreach ($c in $destCols) { $destByName[$c.COLUMN_NAME] = $c }
        $srcByName = @{}
        foreach ($c in $srcCols) { $srcByName[$c.COLUMN_NAME] = $c }

        $allNames = New-Object System.Collections.Generic.HashSet[string]
        [void]$allNames.UnionWith([string[]]$destByName.Keys)
        [void]$allNames.UnionWith([string[]]$srcByName.Keys)

        foreach ($colName in ($allNames | Sort-Object)) {
            $d = $destByName[$colName]
            $s = $srcByName[$colName]

            if ($null -eq $d) {
                Add-Content -Path $reportPath -Value ("[ERRORE] Colonna mancante in " + $DestinationDB + " : " + $colName + " (presente in " + $srcDb + ")")
                continue
            }
            if ($null -eq $s) {
                Add-Content -Path $reportPath -Value ("[ERRORE] Colonna extra in " + $DestinationDB + " : " + $colName + " (assente in " + $srcDb + ")")
                continue
            }

            # Tipo
            if ($d.DATA_TYPE -ne $s.DATA_TYPE) {
                Add-Content -Path $reportPath -Value ("[ERRORE] Tipo dato diverso (" + $colName + "): Dest=" + $d.DATA_TYPE + " vs " + $srcDb + "=" + $s.DATA_TYPE)
            }
            # Lunghezza (solo se applicabile)
            if ($d.CHARACTER_MAXIMUM_LENGTH -ne $s.CHARACTER_MAXIMUM_LENGTH) {
                Add-Content -Path $reportPath -Value ("[ERRORE] Lunghezza diversa (" + $colName + "): Dest=" + $d.CHARACTER_MAXIMUM_LENGTH + " vs " + $srcDb + "=" + $s.CHARACTER_MAXIMUM_LENGTH)
            }
            # Nullability
            if ($d.IS_NULLABLE -ne $s.IS_NULLABLE) {
                Add-Content -Path $reportPath -Value ("[ERRORE] Nullability diversa (" + $colName + "): Dest=" + $d.IS_NULLABLE + " vs " + $srcDb + "=" + $s.IS_NULLABLE)
            }
            # Ordine colonna
            if ($d.ORDINAL_POSITION -ne $s.ORDINAL_POSITION) {
                Add-Content -Path $reportPath -Value ("[AVVISO] Ordine colonna diverso (" + $colName + "): Dest=" + $d.ORDINAL_POSITION + " vs " + $srcDb + "=" + $s.ORDINAL_POSITION)
            }
            # Precisione/Scala (per tipi numerici)
            if ($d.NUMERIC_PRECISION -ne $s.NUMERIC_PRECISION -or $d.NUMERIC_SCALE -ne $s.NUMERIC_SCALE) {
                Add-Content -Path $reportPath -Value ("[ERRORE] Precisione/Scala diversa (" + $colName + "): Dest=" + $d.NUMERIC_PRECISION + "/" + $d.NUMERIC_SCALE + " vs " + $srcDb + "=" + $s.NUMERIC_PRECISION + "/" + $s.NUMERIC_SCALE)
            }
            # Collation (solo tipi testo) - logga se entrambe definite e diverse
            if ($d.COLLATION_NAME -and $s.COLLATION_NAME -and ($d.COLLATION_NAME -ne $s.COLLATION_NAME)) {
                Add-Content -Path $reportPath -Value ("[AVVISO] Collation diversa (" + $colName + "): Dest=" + $d.COLLATION_NAME + " vs " + $srcDb + "=" + $s.COLLATION_NAME)
            }
        }
    }
}

Write-Host ("Analisi completata. Report: " + $reportPath)
