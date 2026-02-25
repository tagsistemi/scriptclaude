# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("vedcontab", "gpxnetclone", "furmanetclone", "vedbondifeclone")

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

# Tabelle da migrare
$TablesToMigrate = @(
    "MA_CrossReferences"
)

function Get-TableColumns {
    param([string]$Database,[string]$TableName,[string]$ConnString)
    $q = "SELECT COLUMN_NAME FROM $($Database).INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TableName' ORDER BY ORDINAL_POSITION;"
    try { (Invoke-Sqlcmd -Query $q -ConnectionString $ConnString -ErrorAction Stop).COLUMN_NAME } catch { $null }
}

function Get-TablePrimaryKey {
    param([string]$Database,[string]$TableName,[string]$ConnString)
    $q = @"
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
    try { (Invoke-Sqlcmd -Query $q -ConnectionString $ConnString -ErrorAction Stop).COLUMN_NAME } catch { $null }
}

function Get-AllForeignKeyConstraints {
    param([string]$Database,[array]$TableNames,[string]$ConnString)
    $list = $TableNames | ForEach-Object { "'$_'" } | Join-String -Separator ", "
    $q = @"
SELECT '['+s.name+'].['+t.name+']' AS TableName, fk.name AS ConstraintName
FROM $($Database).sys.foreign_keys fk
JOIN $($Database).sys.tables t ON fk.parent_object_id = t.object_id
JOIN $($Database).sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name IN ($list)
"@
    try { Invoke-Sqlcmd -Query $q -ConnectionString $ConnString -ErrorAction Stop } catch { $null }
}

function Set-ForeignKeyState {
    param([string]$Database,[object[]]$Constraints,[ValidateSet('NOCHECK','CHECK')][string]$State,[string]$ConnString)
    if (-not $Constraints) { return }
    foreach ($c in $Constraints) {
        $q = "ALTER TABLE $($Database).$($c.TableName) $State CONSTRAINT [$($c.ConstraintName)];"
        try { Invoke-Sqlcmd -Query $q -ConnectionString $ConnString -ErrorAction Stop } catch {}
    }
}

Write-Host "AVVIO MIGRAZIONE MA_CrossReferences" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$constraints = Get-AllForeignKeyConstraints -Database $DestinationDB -TableNames $TablesToMigrate -ConnString $ConnectionString

# Variabile per tracciare i conteggi
$migrationStats = @{}

try {
    if ($constraints) { 
        Write-Host "Disabilitazione vincoli foreign key..." -ForegroundColor Gray
        Set-ForeignKeyState -Database $DestinationDB -Constraints $constraints -State 'NOCHECK' -ConnString $ConnectionString 
    }

    # Cancella destinazione
    Write-Host "Cancellazione dati esistenti in destinazione..." -ForegroundColor Gray
    foreach ($t in ($TablesToMigrate | Sort-Object -Descending)) {
        try { Invoke-Sqlcmd -Query "DELETE FROM $($DestinationDB).dbo.$t;" -ConnectionString $ConnectionString -ErrorAction Stop } catch {}
    }
    Write-Host ""

    foreach ($table in $TablesToMigrate) {
        Write-Host "--- Migrazione tabella: $table" -ForegroundColor Yellow
        
        # Inizializza statistiche per la tabella
        $migrationStats[$table] = @{
            Sources = @{}
            TotalSource = 0
            TotalInserted = 0
        }
        
        $destCols = Get-TableColumns -Database $DestinationDB -TableName $table -ConnString $ConnectionString
        if (-not $destCols) { Write-Warning "Schema destinazione non disponibile per $table"; continue }
        $pkCols = Get-TablePrimaryKey -Database $DestinationDB -TableName $table -ConnString $ConnectionString

        foreach ($src in $SourceDBs) {
            $srcCols = Get-TableColumns -Database $src -TableName $table -ConnString $ConnectionString
            if (-not $srcCols) { 
                Write-Host "  -> Tabella assente in $src, salto." -ForegroundColor DarkGray
                $migrationStats[$table].Sources[$src] = 0
                continue 
            }

            # Conta record sorgente prima dell'inserimento
            $sourceCount = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C
            $migrationStats[$table].Sources[$src] = $sourceCount
            $migrationStats[$table].TotalSource += $sourceCount

            $set = [System.Collections.Generic.HashSet[string]]::new([string[]]$destCols, [System.StringComparer]::InvariantCultureIgnoreCase)
            $set.IntersectWith([string[]]$srcCols)
            $common = @($set)
            if ($common.Count -eq 0) { Write-Warning "  -> Nessuna colonna in comune per $table tra $src e $DestinationDB"; continue }

            $colsInsert = $common | ForEach-Object { "[$_]" } | Join-String -Separator ", "
            $colsSelect = $common | ForEach-Object { "S.[$_]" } | Join-String -Separator ", "
            $sql = "INSERT INTO $($DestinationDB).dbo.$table ($colsInsert) SELECT $colsSelect FROM $src.dbo.$table AS S"
            if ($pkCols) { $conds = $pkCols | ForEach-Object { "D.[$_] = S.[$_]" } | Join-String -Separator " AND "; if ($conds) { $sql += " WHERE NOT EXISTS (SELECT 1 FROM $($DestinationDB).dbo.$table AS D WHERE $conds)" } }
            $sql += ";"

            try {
                Invoke-Sqlcmd -Query $sql -ConnectionString $ConnectionString -ErrorAction Stop
                Write-Host "  -> Migrazione da $src completata ($sourceCount record)" -ForegroundColor Green
            } catch {
                Write-Error ("  -> ERRORE durante la migrazione da {0}: {1}" -f $src, $_)
            }
        }
        
        # Conta record effettivamente inseriti
        $destCount = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $($DestinationDB).dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C
        $migrationStats[$table].TotalInserted = $destCount
        Write-Host ""
    }
} finally {
    if ($constraints) { 
        Write-Host "Riabilitazione vincoli foreign key..." -ForegroundColor Gray
        Set-ForeignKeyState -Database $DestinationDB -Constraints $constraints -State 'CHECK' -ConnString $ConnectionString 
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "VERIFICA CONTEGGI E ANALISI DUPLICATI" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

foreach ($table in $TablesToMigrate) {
    if (-not $migrationStats.ContainsKey($table)) { continue }
    
    $stats = $migrationStats[$table]
    $duplicates = $stats.TotalSource - $stats.TotalInserted
    
    Write-Host "Tabella: $table" -ForegroundColor White
    Write-Host "  Database sorgenti:" -ForegroundColor Gray
    
    foreach ($src in $SourceDBs) {
        if ($stats.Sources.ContainsKey($src)) {
            $count = $stats.Sources[$src]
            Write-Host "    - ${src}: $count record" -ForegroundColor Gray
        }
    }
    
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Totale sorgenti:  $($stats.TotalSource) record" -ForegroundColor White
    Write-Host "  Inseriti in dest: $($stats.TotalInserted) record" -ForegroundColor Green
    
    if ($duplicates -gt 0) {
        $percentuale = [math]::Round(($duplicates / $stats.TotalSource) * 100, 2)
        Write-Host "  Duplicati scartati: $duplicates record ($percentuale%)" -ForegroundColor Yellow
        Write-Host "  ⚠️  Alcuni record con chiave primaria duplicata sono stati ignorati" -ForegroundColor Yellow
    } elseif ($duplicates -eq 0) {
        Write-Host "  ✓ Nessun duplicato trovato - tutti i record migrati" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  ANOMALIA: Inseriti più record del totale sorgente!" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PROCESSO COMPLETATO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan