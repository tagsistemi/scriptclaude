# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

# Tabelle da migrare (in ordine logico se ci sono dipendenze)
$TablesToMigrate = @(
    "MA_SuppQuotas",
    "MA_SuppQuotasDetail",
    "MA_SuppQuotasNote",
    "MA_SuppQuotasReference",
    "MA_SuppQuotasShipping",
    "MA_SuppQuotasTaxSummary"
)

# --- FUNZIONI HELPER ---

function Get-TableColumns {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    $query = "SELECT COLUMN_NAME FROM $($Database).INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TableName' ORDER BY ORDINAL_POSITION;"
    try { (Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop).COLUMN_NAME } catch { $null }
}

function Get-TablePrimaryKey {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    $pkQuery = @"
SELECT kcu.COLUMN_NAME
FROM $($Database).INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
JOIN $($Database).INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
    AND tc.TABLE_NAME = kcu.TABLE_NAME
WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
  AND tc.TABLE_NAME = '$TableName'
ORDER BY kcu.ORDINAL_POSITION;
"@
    try { (Invoke-Sqlcmd -Query $pkQuery -ConnectionString $ConnString -ErrorAction Stop).COLUMN_NAME } catch { $null }
}

function Get-AllForeignKeyConstraints {
    param(
        [string]$Database,
        [array]$TableNames,
        [string]$ConnString
    )
    $tableListForQuery = $TableNames | ForEach-Object { "'$_'" } | Join-String -Separator ", "
    $fkQuery = @"
SELECT 
    '[' + s.name + '].[' + t.name + ']' AS TableName,
    fk.name AS ConstraintName
FROM $($Database).sys.foreign_keys AS fk
INNER JOIN $($Database).sys.tables AS t ON fk.parent_object_id = t.object_id
INNER JOIN $($Database).sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.name IN ($tableListForQuery)
"@
    try { Invoke-Sqlcmd -Query $fkQuery -ConnectionString $ConnString -ErrorAction Stop } catch { $null }
}

function Set-ForeignKeyState {
    param(
        [string]$Database,
        [object[]]$Constraints,
        [ValidateSet('NOCHECK','CHECK')][string]$State,
        [string]$ConnString
    )
    if (-not $Constraints) { return }
    foreach ($c in $Constraints) {
        $alterQuery = "ALTER TABLE $($Database).$($c.TableName) $State CONSTRAINT [$($c.ConstraintName)];"
        try { Invoke-Sqlcmd -Query $alterQuery -ConnectionString $ConnString -ErrorAction Stop } catch {}
    }
}

# --- INIZIO SCRIPT ---
Write-Host "AVVIO MIGRAZIONE MA_SuppQuotas*" -ForegroundColor Cyan

$allConstraints = Get-AllForeignKeyConstraints -Database $DestinationDB -TableNames $TablesToMigrate -ConnString $ConnectionString
try {
    if ($allConstraints) { Set-ForeignKeyState -Database $DestinationDB -Constraints $allConstraints -State 'NOCHECK' -ConnString $ConnectionString }

    # Svuota le tabelle in ordine inverso per rispettare dipendenze
    foreach ($t in ($TablesToMigrate | Sort-Object -Descending)) {
        try { Invoke-Sqlcmd -Query "DELETE FROM $($DestinationDB).dbo.$t;" -ConnectionString $ConnectionString -ErrorAction Stop } catch {}
    }

    foreach ($table in $TablesToMigrate) {
        Write-Host "--- Migrazione tabella: $table" -ForegroundColor Yellow
        $destCols = Get-TableColumns -Database $DestinationDB -TableName $table -ConnString $ConnectionString
        if (-not $destCols) { Write-Warning "Schema destinazione non disponibile per $table"; continue }
        $pkCols = Get-TablePrimaryKey -Database $DestinationDB -TableName $table -ConnString $ConnectionString

        foreach ($src in $SourceDBs) {
            $srcCols = Get-TableColumns -Database $src -TableName $table -ConnString $ConnectionString
            if (-not $srcCols) { Write-Host "  -> Tabella assente in $src, salto."; continue }

            $destSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$destCols, [System.StringComparer]::InvariantCultureIgnoreCase)
            $destSet.IntersectWith([string[]]$srcCols)
            $common = @($destSet)
            if ($common.Count -eq 0) { Write-Warning "  -> Nessuna colonna in comune per $table tra $src e $DestinationDB"; continue }

            $colsInsert = $common | ForEach-Object { "[$_]" } | Join-String -Separator ", "
            $colsSelect = $common | ForEach-Object { "S.[$_]" } | Join-String -Separator ", "

            $sql = "INSERT INTO $($DestinationDB).dbo.$table ($colsInsert) SELECT $colsSelect FROM $src.dbo.$table AS S"
            if ($pkCols) {
                $conds = $pkCols | ForEach-Object { "D.[$_] = S.[$_]" } | Join-String -Separator " AND "
                if ($conds) { $sql += " WHERE NOT EXISTS (SELECT 1 FROM $($DestinationDB).dbo.$table AS D WHERE $conds)" }
            }
            $sql += ";"

            try {
                Invoke-Sqlcmd -Query $sql -ConnectionString $ConnectionString -ErrorAction Stop
                Write-Host "  -> Migrazione da $src completata." -ForegroundColor Green
            } catch {
                Write-Error ("  -> ERRORE durante la migrazione da {0}: {1}" -f $src, $_)
            }
        }
    }
} finally {
    if ($allConstraints) { Set-ForeignKeyState -Database $DestinationDB -Constraints $allConstraints -State 'CHECK' -ConnString $ConnectionString }
}

# Verifica numerica finale
Write-Host "VERIFICA CONTEGGI" -ForegroundColor Cyan
foreach ($table in $TablesToMigrate) {
    $destCount = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $($DestinationDB).dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C
    $srcTotal = 0
    foreach ($src in $SourceDBs) {
        $exists = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$table';" -ConnectionString $ConnectionString -ErrorAction Stop).C
        if ($exists -gt 0) { $srcTotal += (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C }
    }
    Write-Host "Tabella $table -> Sorgenti: $srcTotal, Destinazione: $destCount" -ForegroundColor White
}

Write-Host "PROCESSO COMPLETATO." -ForegroundColor Cyan
