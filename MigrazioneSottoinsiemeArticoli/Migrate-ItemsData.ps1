# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

# Tabelle da migrare in ordine logico (genitori prima dei figli quando possibile)
$TablesToMigrate = @(
    "MA_UnitsOfMeasure",
    "MA_UnitOfMeasureDetail",

    "MA_ProductCtg",
    "MA_ProductCtgSubCtg",
    "MA_ProductSubCtgDefaults",

    "MA_CommodityCtg",
    "MA_CommodityCtgBudget",
    "MA_CommodityCtgCustomers",
    "MA_CommodityCtgCustomersBudget",
    "MA_CommodityCtgCustomersCtg",
    "MA_CommodityCtgSuppliers",
    "MA_CommodityCtgSuppliersCtg",

    "MA_HomogeneousCtg",
    "MA_HomogeneousCtgBudget",

    "MA_ItemTypes",
    "MA_ItemTypeCustomers",
    "MA_ItemTypeCustomersBudget",
    "MA_ItemTypeSuppliers",
    "MA_ItemTypeBudget",

    "MA_Producers",
    "MA_ProducersCategories",

    "MA_Departments",
   
    "MA_Items",
    "MA_ItemsGoodsData",
    "MA_ItemsIntrastat",
    "MA_ItemsManufacturingData",
    "MA_ItemsComparableUoM",
    "MA_ItemsPurchaseBarCode",
    "MA_ItemsSubstitute",
    "MA_ItemsKit",

    "MA_ItemCustomers",
    "MA_ItemCustomersBudget",
    "MA_ItemSuppliers",
    "MA_ItemSuppliersOperations",

    "MA_ItemNotes"
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

Write-Host "AVVIO MIGRAZIONE TABELLE ARTICOLI" -ForegroundColor Cyan
$constraints = Get-AllForeignKeyConstraints -Database $DestinationDB -TableNames $TablesToMigrate -ConnString $ConnectionString
try {
    if ($constraints) { Set-ForeignKeyState -Database $DestinationDB -Constraints $constraints -State 'NOCHECK' -ConnString $ConnectionString }

    # Cancella in ordine inverso (rispetta dipendenze)
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
                Write-Host "  -> Migrazione da $src completata." -ForegroundColor Green
            } catch {
                Write-Error ("  -> ERRORE durante la migrazione da {0}: {1}" -f $src, $_)
            }
        }
    }
} finally {
    if ($constraints) { Set-ForeignKeyState -Database $DestinationDB -Constraints $constraints -State 'CHECK' -ConnString $ConnectionString }
}

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
