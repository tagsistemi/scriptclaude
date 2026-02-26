# ============================================
# SCRIPT: Importa MA_CustSuppBranches dai DB clone su VEDMaster
# ============================================
# Versione: 1.0
# Data: 2026-02-25
#
# Importa i record di MA_CustSuppBranches dai 3 DB clone su VEDMaster.
# NON cancella i dati esistenti (vedcontab).
# Salta i record con chiave duplicata (segnala e continua).
# ============================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

$table = "MA_CustSuppBranches"

function Get-TableColumns {
    param([string]$Database, [string]$TableName, [string]$ConnString)
    $q = "SELECT COLUMN_NAME FROM $($Database).INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TableName' ORDER BY ORDINAL_POSITION;"
    try { (Invoke-Sqlcmd -Query $q -ConnectionString $ConnString -ErrorAction Stop).COLUMN_NAME } catch { $null }
}

function Get-TablePrimaryKey {
    param([string]$Database, [string]$TableName, [string]$ConnString)
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

# ============================================
# INIZIO
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  IMPORTA $table DAI DB CLONE" -ForegroundColor Cyan
Write-Host "  Destinazione: $DestinationDB" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# Conteggio iniziale
$destCountBefore = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $DestinationDB.dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C
Write-Host "  Record su $DestinationDB PRIMA: $destCountBefore" -ForegroundColor White
Write-Host ""

# Schema e PK
$destCols = Get-TableColumns -Database $DestinationDB -TableName $table -ConnString $ConnectionString
if (-not $destCols) {
    Write-Host "  ERRORE: tabella $table non trovata su $DestinationDB" -ForegroundColor Red
    exit
}

$pkCols = Get-TablePrimaryKey -Database $DestinationDB -TableName $table -ConnString $ConnectionString
Write-Host "  Colonne PK: $($pkCols -join ', ')" -ForegroundColor Gray
Write-Host ""

$totalInserted = 0
$totalSkipped = 0
$totalFkSkipped = 0
$totalErrors = 0

foreach ($src in $SourceDBs) {
    Write-Host "--- Sorgente: $src ---" -ForegroundColor Yellow

    # Verifica che la tabella esista nel clone
    $srcExists = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$table';" -ConnectionString $ConnectionString -ErrorAction Stop).C
    if ($srcExists -eq 0) {
        Write-Host "  Tabella assente in $src, salto." -ForegroundColor Gray
        continue
    }

    $srcCols = Get-TableColumns -Database $src -TableName $table -ConnString $ConnectionString

    # Colonne in comune
    $set = [System.Collections.Generic.HashSet[string]]::new([string[]]$destCols, [System.StringComparer]::InvariantCultureIgnoreCase)
    $set.IntersectWith([string[]]$srcCols)
    $common = @($set)
    if ($common.Count -eq 0) {
        Write-Host "  Nessuna colonna in comune, salto." -ForegroundColor Red
        continue
    }

    # Conteggio record sorgente
    $srcCount = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C
    Write-Host "  Record in $src`: $srcCount" -ForegroundColor White

    # Conteggio duplicati PK (gia presenti su VEDMaster)
    $dupCount = 0
    if ($pkCols) {
        $joinConds = ($pkCols | ForEach-Object { "D.[$_] = S.[$_]" }) -join " AND "
        $dupCount = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.dbo.$table AS S WHERE EXISTS (SELECT 1 FROM $DestinationDB.dbo.$table AS D WHERE $joinConds);" -ConnectionString $ConnectionString -ErrorAction Stop).C

        if ($dupCount -gt 0) {
            Write-Host "  Duplicati PK (gia presenti, saranno saltati): $dupCount" -ForegroundColor Yellow
        }
    }

    # Conteggio record con CustSupp mancante su VEDMaster (violazione FK)
    $fkMissing = (Invoke-Sqlcmd -Query @"
SELECT COUNT(*) AS C FROM $src.dbo.$table AS S
WHERE NOT EXISTS (SELECT 1 FROM $DestinationDB.dbo.MA_CustSupp AS CS WHERE CS.CustSuppType = S.CustSuppType AND CS.CustSupp = S.CustSupp)
"@ -ConnectionString $ConnectionString -ErrorAction Stop).C

    if ($fkMissing -gt 0) {
        Write-Host "  CustSupp assenti su VEDMaster (saltati per FK): $fkMissing" -ForegroundColor Yellow

        # Campione dei CustSupp mancanti
        $fkSample = Invoke-Sqlcmd -Query @"
SELECT TOP 10 S.CustSupp, COUNT(*) AS Righe
FROM $src.dbo.$table AS S
WHERE NOT EXISTS (SELECT 1 FROM $DestinationDB.dbo.MA_CustSupp AS CS WHERE CS.CustSuppType = S.CustSuppType AND CS.CustSupp = S.CustSupp)
GROUP BY S.CustSupp ORDER BY COUNT(*) DESC
"@ -ConnectionString $ConnectionString -ErrorAction SilentlyContinue

        foreach ($row in $fkSample) {
            Write-Host "    CustSupp=$($row.CustSupp) ($($row.Righe) righe)" -ForegroundColor Gray
        }
    }

    $newCount = $srcCount - $dupCount - $fkMissing
    if ($newCount -lt 0) { $newCount = 0 }
    Write-Host "  Nuovi da inserire (no duplicati, no FK mancanti): $newCount" -ForegroundColor White

    # INSERT con NOT EXISTS su PK + EXISTS su FK (CustSupp)
    $colsInsert = $common | ForEach-Object { "[$_]" } | Join-String -Separator ", "
    $colsSelect = $common | ForEach-Object { "S.[$_]" } | Join-String -Separator ", "

    $whereClauses = @()

    # Filtro PK duplicati
    if ($pkCols) {
        $notExistsConds = ($pkCols | ForEach-Object { "D.[$_] = S.[$_]" }) -join " AND "
        $whereClauses += "NOT EXISTS (SELECT 1 FROM $DestinationDB.dbo.$table AS D WHERE $notExistsConds)"
    }

    # Filtro FK: solo CustSupp che esistono su VEDMaster
    $whereClauses += "EXISTS (SELECT 1 FROM $DestinationDB.dbo.MA_CustSupp AS CS WHERE CS.CustSuppType = S.CustSuppType AND CS.CustSupp = S.CustSupp)"

    $sql = "INSERT INTO $DestinationDB.dbo.$table ($colsInsert) SELECT $colsSelect FROM $src.dbo.$table AS S WHERE $($whereClauses -join ' AND ');"

    try {
        Invoke-Sqlcmd -Query $sql -ConnectionString $ConnectionString -ErrorAction Stop
        # Conta quanti effettivamente inseriti
        $destCountAfterSrc = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $DestinationDB.dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C
        $inserted = $destCountAfterSrc - $destCountBefore - $totalInserted
        $totalInserted += $inserted
        $totalSkipped += $dupCount
        $totalFkSkipped += $fkMissing
        Write-Host "  Inseriti: $inserted" -ForegroundColor Green
    } catch {
        $totalErrors++
        Write-Host "  ERRORE: $_" -ForegroundColor Red
        Write-Host "  Continuo con il prossimo database..." -ForegroundColor Yellow
    }

    Write-Host ""
}

# ============================================
# Dettaglio duplicati saltati (campione)
# ============================================
if ($totalSkipped -gt 0) {
    Write-Host "--- Campione duplicati saltati (primi 10) ---" -ForegroundColor Yellow

    # Mostra i primi duplicati tra tutti i clone
    foreach ($src in $SourceDBs) {
        $srcExists = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$table';" -ConnectionString $ConnectionString -ErrorAction Stop).C
        if ($srcExists -eq 0) { continue }

        $pkSelect = ($pkCols | ForEach-Object { "S.[$_]" }) -join ", "
        $joinConds = ($pkCols | ForEach-Object { "D.[$_] = S.[$_]" }) -join " AND "

        $sampleSql = "SELECT TOP 10 $pkSelect FROM $src.dbo.$table AS S WHERE EXISTS (SELECT 1 FROM $DestinationDB.dbo.$table AS D WHERE $joinConds);"
        $samples = Invoke-Sqlcmd -Query $sampleSql -ConnectionString $ConnectionString -ErrorAction SilentlyContinue

        if ($samples) {
            Write-Host "  Da $src`:" -ForegroundColor Gray
            foreach ($row in $samples) {
                $vals = $pkCols | ForEach-Object { "$_=$($row.$_)" }
                Write-Host "    $($vals -join ', ')" -ForegroundColor Gray
            }
            break  # Basta un campione
        }
    }
    Write-Host ""
}

# ============================================
# VERIFICA FINALE
# ============================================
Write-Host "--- Verifica finale ---" -ForegroundColor Cyan
Write-Host ""

$destCountAfter = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $DestinationDB.dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C

$srcTotalAll = 0
foreach ($src in $SourceDBs) {
    $exists = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$table';" -ConnectionString $ConnectionString -ErrorAction Stop).C
    if ($exists -gt 0) {
        $c = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS C FROM $src.dbo.$table;" -ConnectionString $ConnectionString -ErrorAction Stop).C
        $srcTotalAll += $c
    }
}

# ============================================
# RIEPILOGO
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RIEPILOGO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "  Durata: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host "  Record sorgenti (3 clone):   $srcTotalAll" -ForegroundColor White
Write-Host "  Record VEDMaster PRIMA:      $destCountBefore" -ForegroundColor White
Write-Host "  Record VEDMaster DOPO:       $destCountAfter" -ForegroundColor White
Write-Host "  Inseriti:                    $($destCountAfter - $destCountBefore)" -ForegroundColor Green
Write-Host "  Duplicati PK saltati:        $totalSkipped" -ForegroundColor $(if ($totalSkipped -eq 0) { "Green" } else { "Yellow" })
Write-Host "  FK mancanti saltati:         $totalFkSkipped" -ForegroundColor $(if ($totalFkSkipped -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Errori:                      $totalErrors" -ForegroundColor $(if ($totalErrors -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Operazione completata!" -ForegroundColor Green
