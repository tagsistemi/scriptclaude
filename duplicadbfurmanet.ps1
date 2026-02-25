# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$SourceDB = "furmanet"
$TargetDB = "furmanetclone"

# Funzione per eseguire una query SQL
function Execute-SqlQuery {
    param (
        [string]$query,
        [string]$database = "master"
    )
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server=$ServerInstance;Database=$database;User Id=$SqlUsername;Password=$SqlPassword;"
        $conn.Open()
        
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 0  # No timeout
        
        $result = $cmd.ExecuteNonQuery()
        return $true
    }
    catch {
        Write-Error "Errore nell'esecuzione della query: $_"
        return $false
    }
    finally {
        if ($conn -and $conn.State -eq 'Open') {
            $conn.Close()
        }
    }
}

# Funzione per ottenere il path dei file del database
function Get-DatabaseFiles {
    param (
        [string]$databaseName
    )
    
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=master;User Id=$SqlUsername;Password=$SqlPassword;"
    $conn.Open()
    
    $query = @"
    SELECT 
        name as LogicalName,
        physical_name as PhysicalName,
        type_desc as FileType
    FROM sys.master_files 
    WHERE database_id = DB_ID('$databaseName')
"@
    
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
    $reader = $cmd.ExecuteReader()
    
    $files = @()
    while ($reader.Read()) {
        $files += @{
            LogicalName = $reader["LogicalName"]
            PhysicalName = $reader["PhysicalName"]
            FileType = $reader["FileType"]
        }
    }
    
    $conn.Close()
    return $files
}

Write-Host "Inizio processo di clonazione del database..." -ForegroundColor Yellow

# 1. Verifica se il database di destinazione esiste già
$checkDbQuery = "SELECT COUNT(*) FROM sys.databases WHERE name = '$TargetDB'"
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=$ServerInstance;Database=master;User Id=$SqlUsername;Password=$SqlPassword;"
$conn.Open()
$cmd = New-Object System.Data.SqlClient.SqlCommand($checkDbQuery, $conn)
$dbExists = [int]$cmd.ExecuteScalar() -gt 0
$conn.Close()

if ($dbExists) {
    # Se il database esiste, eliminalo
    Write-Host "Il database $TargetDB esiste già. Eliminazione in corso..." -ForegroundColor Yellow
    $dropQuery = "ALTER DATABASE [$TargetDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$TargetDB]"
    Execute-SqlQuery -query $dropQuery
}

# 2. Ottieni i percorsi dei file del database sorgente
$sourceFiles = Get-DatabaseFiles -databaseName $SourceDB
$dataFile = ($sourceFiles | Where-Object { $_.FileType -eq "ROWS" }).PhysicalName
$logFile = ($sourceFiles | Where-Object { $_.FileType -eq "LOG" }).PhysicalName

# 3. Costruisci i nuovi percorsi per i file
$targetDataFile = $dataFile -replace $SourceDB, $TargetDB
$targetLogFile = $logFile -replace $SourceDB, $TargetDB

# 4. Backup del database sorgente
$backupPath = $dataFile -replace "\.mdf$", "_backup.bak"
Write-Host "Backup del database $SourceDB in corso..." -ForegroundColor Yellow
$backupQuery = "BACKUP DATABASE [$SourceDB] TO DISK = N'$backupPath' WITH INIT"
Execute-SqlQuery -query $backupQuery

# 5. Restore del database con il nuovo nome
Write-Host "Restore del database come $TargetDB in corso..." -ForegroundColor Yellow
$restoreQuery = @"
RESTORE DATABASE [$TargetDB] 
FROM DISK = N'$backupPath' 
WITH 
    MOVE '$(($sourceFiles | Where-Object { $_.FileType -eq "ROWS" }).LogicalName)' TO N'$targetDataFile',
    MOVE '$(($sourceFiles | Where-Object { $_.FileType -eq "LOG" }).LogicalName)' TO N'$targetLogFile',
    REPLACE
"@
Execute-SqlQuery -query $restoreQuery

# 6. Elimina il file di backup
if (Test-Path $backupPath) {
    Write-Host "Rimozione file di backup..." -ForegroundColor Yellow
    Remove-Item $backupPath -Force
}

Write-Host "Operazione completata!" -ForegroundColor Green
Write-Host "Il database $SourceDB è stato clonato come $TargetDB" -ForegroundColor Green