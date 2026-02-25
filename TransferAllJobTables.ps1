<#!
.SYNOPSIS
    Trasferisce SOLO i record relativi ai Jobs con Disabled='0' dai database sorgente a Vedmaster.
.DESCRIPTION
    Script per migrare le tabelle MA_Jobs e tutte le IM_Job* copiando esclusivamente:
      - Righe di MA_Jobs dove Disabled='0'
      - Righe delle altre tabelle con colonna Job il cui Job appartiene a MA_Jobs.Disabled='0'
    Le tabelle di destinazione vengono SEMPRE svuotate prima del trasferimento (TRUNCATE / DELETE).
    I record con chiavi primarie già presenti vengono SALTATI (no errore) e loggati in un file CSV.
.NOTES
    Compatibile con SQL Server 2008.
    Usare account con permessi adeguati.
!#>

param(
    [string]$ServerInstance = "192.168.0.3\SQL2008",
    [string]$SqlUsername    = "sa",
    [string]$SqlPassword    = "stream",
    [string[]]$SourceDBs    = @("gpxnetclone","vedbondifeclone","furmanetclone"),
    [string]$DestinationDB  = "Vedmaster",
    [string]$DuplicateLogFile = ".\DuplicatiSaltati.csv",
    [int]$ConnectionTimeout = 30,
    [int]$CommandTimeout    = 600
)

# -------------------- Funzioni di supporto --------------------
function New-SqlConnection {
    param([string]$Server,[string]$User,[string]$Pwd,[int]$Timeout=30)
    $cs = "Server=$Server;User Id=$User;Password=$Pwd;Connect Timeout=$Timeout;"  # niente Initial Catalog per usare sys.databases
    $c  = New-Object System.Data.SqlClient.SqlConnection($cs)
    $c.Open()
    return $c
}

function Invoke-Scalar {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Sql)
    $cmd = $Conn.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = $CommandTimeout
    return $cmd.ExecuteScalar()
}

function Invoke-NonQuery {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Sql,[System.Data.SqlClient.SqlTransaction]$Tran)
    $cmd = $Conn.CreateCommand()
    if($Tran){ $cmd.Transaction = $Tran }
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = $CommandTimeout
    [void]$cmd.ExecuteNonQuery()
}

function Get-DataTable {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Sql)
    $cmd = $Conn.CreateCommand(); $cmd.CommandText=$Sql; $cmd.CommandTimeout=$CommandTimeout
    $da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    [void]$da.Fill($dt)
    return $dt
}

function Test-DatabaseExists {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db)
    (Invoke-Scalar -Conn $Conn -Sql "SELECT COUNT(*) FROM sys.databases WHERE name='$Db'") -gt 0
}

function Test-TableExists {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db,[string]$Table)
    (Invoke-Scalar -Conn $Conn -Sql "SELECT COUNT(*) FROM [$Db].INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='$Table' AND TABLE_TYPE='BASE TABLE'") -gt 0
}

function Get-JobTables {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db)
    $sql = @"
SELECT name FROM [$Db].sys.tables WHERE name='MA_Jobs' OR name LIKE 'IM_Job%' ORDER BY name
"@
    $dt  = Get-DataTable -Conn $Conn -Sql $sql
    $names = $dt | ForEach-Object { $_.name }
    if($names -contains 'MA_Jobs'){
        # assicurare MA_Jobs primo
        $ordered = @('MA_Jobs') + ($names | Where-Object { $_ -ne 'MA_Jobs' })
        return $ordered
    }
    return $names
}

function Get-CommonColumns {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$SourceDb,[string]$DestDb,[string]$Table)
    $s = Get-DataTable -Conn $Conn -Sql "SELECT COLUMN_NAME FROM [$SourceDb].INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$Table'"
    $d = Get-DataTable -Conn $Conn -Sql "SELECT COLUMN_NAME FROM [$DestDb].INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$Table'"
    $sc = $s | ForEach-Object COLUMN_NAME
    $dc = $d | ForEach-Object COLUMN_NAME
    $common = @($sc | Where-Object { $dc -contains $_ })
    return $common
}

function Get-PrimaryKeyColumns {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db,[string]$Table)
    $sql = @"
SELECT COL_NAME(ic.object_id,ic.column_id) col
FROM [$Db].sys.indexes i
JOIN [$Db].sys.index_columns ic ON i.object_id=ic.object_id AND i.index_id=ic.index_id
WHERE i.is_primary_key=1 AND OBJECT_NAME(i.object_id)='$Table'
ORDER BY ic.key_ordinal
"@
    (Get-DataTable -Conn $Conn -Sql $sql | ForEach-Object col)
}

function Has-IdentityColumn {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db,[string]$Table)
    (Invoke-Scalar -Conn $Conn -Sql "SELECT COUNT(*) FROM [$Db].sys.identity_columns WHERE object_name(object_id)='$Table'") -gt 0
}

function Disable-AllFK {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db)
    Write-Host "Disabilito FK in $Db" -ForegroundColor Yellow
    $sql = @"
DECLARE @s nvarchar(128),@t nvarchar(128),@n nvarchar(128),@sql nvarchar(max);
DECLARE c CURSOR FOR
SELECT SCHEMA_NAME(f.schema_id),OBJECT_NAME(f.parent_object_id),f.name FROM [$Db].sys.foreign_keys f;
OPEN c;FETCH NEXT FROM c INTO @s,@t,@n;WHILE @@FETCH_STATUS=0 BEGIN
  SET @sql='ALTER TABLE ['+@s+'].['+@t+'] NOCHECK CONSTRAINT ['+@n+']';EXEC (@sql);
  FETCH NEXT FROM c INTO @s,@t,@n;END CLOSE c;DEALLOCATE c;
"@
    Invoke-NonQuery -Conn $Conn -Sql $sql
}

function Enable-AllFK {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db)
    Write-Host "Riabilito FK in $Db" -ForegroundColor Yellow
    $sql = @"
DECLARE @s nvarchar(128),@t nvarchar(128),@n nvarchar(128),@sql nvarchar(max);
DECLARE c CURSOR FOR
SELECT SCHEMA_NAME(f.schema_id),OBJECT_NAME(f.parent_object_id),f.name FROM [$Db].sys.foreign_keys f;
OPEN c;FETCH NEXT FROM c INTO @s,@t,@n;WHILE @@FETCH_STATUS=0 BEGIN
  SET @sql='ALTER TABLE ['+@s+'].['+@t+'] WITH CHECK CHECK CONSTRAINT ['+@n+']';EXEC (@sql);
  FETCH NEXT FROM c INTO @s,@t,@n;END CLOSE c;DEALLOCATE c;
"@
    Invoke-NonQuery -Conn $Conn -Sql $sql
}

function Truncate-OrDeleteTable {
    param([System.Data.SqlClient.SqlConnection]$Conn,[string]$Db,[string]$Table)
    try {
        Invoke-NonQuery -Conn $Conn -Sql "TRUNCATE TABLE [$Db].[dbo].[$Table]"; return
    } catch {
        Write-Host "TRUNCATE fallito per $Table -> uso DELETE" -ForegroundColor DarkYellow
        Invoke-NonQuery -Conn $Conn -Sql "DELETE FROM [$Db].[dbo].[$Table]"
    }
}

function Copy-Table {
    param(
        [System.Data.SqlClient.SqlConnection]$Conn,
        [string]$SourceDb,
        [string]$DestDb,
        [string]$Table
    )
    if(-not (Test-TableExists -Conn $Conn -Db $SourceDb -Table $Table)) { Write-Host "[SKIP] $Table non esiste in $SourceDb" -ForegroundColor DarkGray; return }
    if(-not (Test-TableExists -Conn $Conn -Db $DestDb   -Table $Table)) { Write-Host "[SKIP] $Table non esiste in $DestDb" -ForegroundColor DarkGray; return }

    $common = Get-CommonColumns -Conn $Conn -SourceDb $SourceDb -DestDb $DestDb -Table $Table
    if($common.Count -eq 0){ Write-Host "[SKIP] Nessuna colonna comune per $Table" -ForegroundColor DarkGray; return }

    # Costruzione filtro Disabled='0'
    $disabledFilter = $null
    if($Table -eq 'MA_Jobs' -and ($common -contains 'Disabled')){
        $disabledFilter = "s.[Disabled] = '0'"
    } elseif ($common -contains 'Job') {
        $disabledFilter = "s.[Job] IN (SELECT Job FROM [$SourceDb].[dbo].[MA_Jobs] WHERE Disabled='0')"
    } else {
        Write-Host "[SKIP] $Table non ha colonna Job e requisito filtro Disabled -> salto" -ForegroundColor DarkGray
        return
    }

    $pkCols = Get-PrimaryKeyColumns -Conn $Conn -Db $DestDb -Table $Table
    $hasIdentity = Has-IdentityColumn -Conn $Conn -Db $DestDb -Table $Table

    $destColumnList = '[' + ($common -join '],[') + ']'
    $selectList = ($common | ForEach-Object { "s.[$_]" }) -join ','

    $predicate = $null
    if($pkCols -and $pkCols.Count -gt 0){
        $predicate = ($pkCols | ForEach-Object { "d.[$_] = s.[$_]" }) -join ' AND '
    }

    Write-Host "Filtro applicato: $disabledFilter" -ForegroundColor DarkCyan

    if($pkCols -and $pkCols.Count -gt 0){
        # Query per duplicati (prima dell'inserimento) limitata ai Jobs Disabled='0'
        $dupColsSelect = ($pkCols | ForEach-Object { "s.[$_]" }) -join ','
        $dupConditions = @($disabledFilter, "EXISTS (SELECT 1 FROM [$DestDb].[dbo].[$Table] d WHERE $predicate)")
        $dupSelectSql = "SELECT $dupColsSelect FROM [$SourceDb].[dbo].[$Table] s WHERE " + ($dupConditions -join ' AND ')
        $dupDt = Get-DataTable -Conn $Conn -Sql $dupSelectSql

        if($dupDt.Rows.Count -gt 0){
            if(-not (Test-Path -LiteralPath $DuplicateLogFile)){
                "SourceDb;Table;PrimaryKeyColumns;PrimaryKeyValues" | Out-File -FilePath $DuplicateLogFile -Encoding UTF8
            }
            foreach($row in $dupDt.Rows){
                $pkVals = @(); foreach($c in $pkCols){ $pkVals += ($row.$c) }
                $line = "$SourceDb;$Table;" + ($pkCols -join '|') + ";" + ($pkVals -join '|')
                Add-Content -Path $DuplicateLogFile -Value $line
            }
            Write-Warning ("  Duplicati trovati (filtrati Disabled='0') in {0} da {1}: {2} (saltati)" -f $Table,$SourceDb,$dupDt.Rows.Count)
        }

        # Insert con filtro e skip duplicati
        $insertConditions = @($disabledFilter, "NOT EXISTS (SELECT 1 FROM [$DestDb].[dbo].[$Table] d WHERE $predicate)")
        $whereClause = "WHERE " + ($insertConditions -join ' AND ')
        $insertSql = @"
INSERT INTO [$DestDb].[dbo].[$Table] ($destColumnList)
SELECT $selectList FROM [$SourceDb].[dbo].[$Table] s
$whereClause
"@
    }
    else {
        # Nessuna PK: inserimento filtrato solo per Jobs Disabled='0'
        $insertSql = @"
INSERT INTO [$DestDb].[dbo].[$Table] ($destColumnList)
SELECT $selectList FROM [$SourceDb].[dbo].[$Table] s
WHERE $disabledFilter
"@
    }

    Write-Host "Trasferisco $Table da $SourceDb (solo Disabled='0')" -ForegroundColor Cyan
    $tran = $Conn.BeginTransaction()
    try {
        if($hasIdentity){ Invoke-NonQuery -Conn $Conn -Sql "SET IDENTITY_INSERT [$DestDb].[dbo].[$Table] ON" -Tran $tran }
        $cmd = $Conn.CreateCommand(); $cmd.Transaction=$tran; $cmd.CommandText=$insertSql; $cmd.CommandTimeout=$CommandTimeout
        $rows = $cmd.ExecuteNonQuery()
        if($hasIdentity){ Invoke-NonQuery -Conn $Conn -Sql "SET IDENTITY_INSERT [$DestDb].[dbo].[$Table] OFF" -Tran $tran }
        $tran.Commit()
        Write-Host "  Inserite $rows righe" -ForegroundColor Green
    } catch {
        Write-Warning "  ERRORE: $($_.Exception.Message)"
        try { $tran.Rollback() } catch {}
    }
}

# -------------------- Corpo principale --------------------
Write-Host "Connessione a $ServerInstance" -ForegroundColor Cyan
$connection = New-SqlConnection -Server $ServerInstance -User $SqlUsername -Pwd $SqlPassword -Timeout $ConnectionTimeout

if(-not (Test-DatabaseExists -Conn $connection -Db $DestinationDB)) { throw "Database destinazione $DestinationDB non esiste." }

Write-Host "Raccolgo lista tabelle Jobs dal DB di destinazione (fallback: primo sorgente)." -ForegroundColor Cyan
$tables = Get-JobTables -Conn $connection -Db $DestinationDB
if(!$tables -or $tables.Count -eq 0){
    foreach($s in $SourceDBs){ if(Test-DatabaseExists -Conn $connection -Db $s){ $tables = Get-JobTables -Conn $connection -Db $s; if($tables.Count -gt 0){ break } } }
}
if(!$tables -or $tables.Count -eq 0){ throw "Nessuna tabella Jobs trovata." }
Write-Host "Tabelle individuate: $($tables -join ', ')" -ForegroundColor Yellow

Disable-AllFK -Conn $connection -Db $DestinationDB

# Svuota sempre le tabelle di destinazione prima del trasferimento
Write-Host "Svuoto le tabelle di destinazione..." -ForegroundColor Yellow
if(Test-Path -LiteralPath $DuplicateLogFile){ Remove-Item -LiteralPath $DuplicateLogFile -ErrorAction SilentlyContinue }
foreach($t in $tables){ if(Test-TableExists -Conn $connection -Db $DestinationDB -Table $t){ Truncate-OrDeleteTable -Conn $connection -Db $DestinationDB -Table $t } }

# MA_Jobs prima (se presente)
if($tables -contains 'MA_Jobs'){
    foreach($src in $SourceDBs){ if(Test-DatabaseExists -Conn $connection -Db $src){ Copy-Table -Conn $connection -SourceDb $src -DestDb $DestinationDB -Table 'MA_Jobs' } }
}

# Altre tabelle
foreach($src in $SourceDBs){
    if(-not (Test-DatabaseExists -Conn $connection -Db $src)){ Write-Host "DB sorgente $src non esiste -> skip" -ForegroundColor DarkGray; continue }
    foreach($t in $tables){ if($t -ne 'MA_Jobs'){ Copy-Table -Conn $connection -SourceDb $src -DestDb $DestinationDB -Table $t } }
}

# Riabilita FK
Enable-AllFK -Conn $connection -Db $DestinationDB

$connection.Close()
Write-Host "Completato." -ForegroundColor Green
