# Requires -Modules SqlServer

$ErrorActionPreference = 'Stop'

# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

# Ordine logico tabelle (padri -> figli). Verrà usato anche l'inverso per i delete.
# Nota: Adeguare se la realtà differisce (FK specifiche installazione)
$TablesOrder = @(
    'MA_JobGroups',        # Gruppi commesse (padre di MA_Jobs?)
    'MA_JobsParameters',   # Parametri commesse
    'MA_Jobs',             # Commesse principali
    'MA_JobsBalances'      # Saldi commesse (dipende da MA_Jobs)
)

function Get-TableColumns($dbName, $tableName) {
    $safeTable = $tableName -replace "'", "''"
    $q = @"
    SELECT COLUMN_NAME
    FROM [$dbName].INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME=N'$safeTable'
    ORDER BY ORDINAL_POSITION
"@
    try {
        (Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $q -ErrorAction Stop).COLUMN_NAME
    } catch {
        $null
    }
}

function Get-TablePrimaryKey($dbName, $tableName) {
    $safeTable = $tableName -replace "'", "''"
    $q = @"
    SELECT kcu.COLUMN_NAME
    FROM [$dbName].INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN [$dbName].INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
      ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
     AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
     AND tc.TABLE_NAME = kcu.TABLE_NAME
    WHERE tc.TABLE_SCHEMA='dbo' AND tc.TABLE_NAME=N'$safeTable' AND tc.CONSTRAINT_TYPE='PRIMARY KEY'
    ORDER BY kcu.ORDINAL_POSITION
"@
    try {
        (Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $q -ErrorAction Stop).COLUMN_NAME
    } catch {
        $null
    }
}

function Set-ForeignKeyStatePerTable($dbName, $tableName, $enabled) {
    $cmd = if ($enabled) { 'CHECK CONSTRAINT ALL' } else { 'NOCHECK CONSTRAINT ALL' }
    $q = "ALTER TABLE [$dbName].dbo.[$tableName] $cmd"
    try { Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $q -ErrorAction Stop } catch { }
}

# Disabilita FKs (ignora assenti)
foreach ($t in $TablesOrder) { Set-ForeignKeyStatePerTable -dbName $DestinationDB -tableName $t -enabled:$false }

# Cancellazione dati destinazione in ordine inverso
$reverse = [System.Linq.Enumerable]::Reverse([string[]]$TablesOrder)
foreach ($t in $reverse) {
    try {
        Invoke-Sqlcmd -ConnectionString $ConnectionString -Query ("DELETE FROM [" + $DestinationDB + "].dbo.[" + $t + "]") -ErrorAction Stop
    } catch {
        Write-Host ("Tabella " + $t + " assente in " + $DestinationDB + ", skip DELETE")
    }
}

# Inserimenti per ogni sorgente
foreach ($srcDb in $SourceDBs) {
    foreach ($table in $TablesOrder) {
        Write-Host ("Migrazione tabella " + $table + " da " + $srcDb + "...")

        $destCols = Get-TableColumns -dbName $DestinationDB -tableName $table
        if (-not $destCols) { Write-Warning ("Destinazione " + $DestinationDB + " mancante schema per tabella " + $table + ", skip"); continue }
        $srcCols  = Get-TableColumns -dbName $srcDb -tableName $table
        if (-not $srcCols) { Write-Warning ("Sorgente " + $srcDb + " mancante tabella " + $table + ", skip"); continue }

        # Intersezione colonne case-insensitive
        $set = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::InvariantCultureIgnoreCase)
        [void]$set.UnionWith([string[]]$destCols)
        [void]$set.IntersectWith([string[]]$srcCols)
        $cols = $set | Sort-Object

        if ($cols.Count -eq 0) { Write-Warning ("Nessuna colonna comune per " + $table + "."); continue }

        $colList = ($cols | ForEach-Object { "[" + $_ + "]" }) -join ', '
        $pkCols = Get-TablePrimaryKey -dbName $DestinationDB -tableName $table
        $pkCols = if ($pkCols) { $pkCols } else { @() }

        $joinCond = if ($pkCols.Count -gt 0) {
            ($pkCols | ForEach-Object { "t.[" + $_ + "] = s.[" + $_ + "]" }) -join ' AND '
        } else {
            # Se non c'è PK, usa tutte le colonne comuni (rischio duplicati)
            ($cols | ForEach-Object { "t.[" + $_ + "] = s.[" + $_ + "]" }) -join ' AND '
        }

        $insert = @"
INSERT INTO [$DestinationDB].dbo.[$table] ($colList)
SELECT $colList
FROM [$srcDb].dbo.[$table] s
WHERE NOT EXISTS (
    SELECT 1 FROM [$DestinationDB].dbo.[$table] t WHERE $joinCond
)
"@
        try {
            Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $insert -ErrorAction Stop
        } catch {
            Write-Error ("  -> ERRORE durante la migrazione da {0} per tabella {1}: {2}" -f $srcDb, $table, $_)
        }
    }
}

# Riabilita FKs (ignora assenti)
foreach ($t in $TablesOrder) { Set-ForeignKeyStatePerTable -dbName $DestinationDB -tableName $t -enabled:$true }

# Verifica conteggi
$counts = New-Object System.Collections.Generic.List[pscustomobject]
foreach ($db in @($DestinationDB) + $SourceDBs) {
    foreach ($t in $TablesOrder) {
        $cnt = $null
        try {
            $q = "SELECT COUNT(*) AS Cnt FROM [" + $db + "].dbo.[" + $t + "]"
            $cnt = (Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $q -ErrorAction Stop).Cnt
        } catch { }
        $counts.Add([pscustomobject]@{ DB=$db; Table=$t; Count=$cnt })
    }
}
$counts | Format-Table -AutoSize
