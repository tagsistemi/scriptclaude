# ============================================
# SCRIPT 29a: Backup MA_EIEventViewer
# ============================================
# Versione: 1.0
#
# SCOPO:
#   Crea la tabella MA_EIEventViewerBackup su VEDMaster
#   e copia tutti i dati da MA_EIEventViewer.
#   Se la tabella backup esiste gia', la svuota prima dell'insert.
#
# QUANDO ESEGUIRE:
#   - PRIMA dello script 29 (Fix DocId in MA_EIEventViewer)
# ============================================

# Parametri di connessione
$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"
$destinationDB = "VEDMaster"

# ============================================
# FUNZIONI HELPER
# ============================================

function Execute-SqlNonQuery {
    param (
        [string]$query,
        [string]$connString,
        [string]$msgOk,
        [string]$msgErr,
        [int]$timeout = 600
    )
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = $timeout
        $rows = $cmd.ExecuteNonQuery()
        $conn.Close()
        if ($msgOk) { Write-Host "$msgOk (righe: $rows)" -ForegroundColor Green }
        return $rows
    }
    catch {
        if ($msgErr) { Write-Host "$msgErr`: $_" -ForegroundColor Red }
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return -1
    }
}

function Execute-SqlScalar {
    param (
        [string]$query,
        [string]$connString
    )
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 300
        $result = $cmd.ExecuteScalar()
        $conn.Close()
        return $result
    }
    catch {
        Write-Host "Errore query scalare: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return $null
    }
}

# Stringa di connessione
$connString = "Server=$serverName;Database=$destinationDB;User ID=$userName;Password=$password;"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SCRIPT 29a: Backup MA_EIEventViewer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
Write-Host "Ora inizio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

# ============================================
# FASE 1: Creazione/verifica tabella backup
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 1: Creazione tabella backup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$backupExists = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.sys.objects
WHERE object_id = OBJECT_ID(N'$destinationDB.dbo.MA_EIEventViewerBackup') AND type = 'U'
"@ -connString $connString

if ($backupExists -gt 0) {
    Write-Host "  Tabella MA_EIEventViewerBackup gia' esistente." -ForegroundColor Yellow

    # Svuota la tabella
    $truncResult = Execute-SqlNonQuery -query "TRUNCATE TABLE $destinationDB.dbo.MA_EIEventViewerBackup" `
        -connString $connString `
        -msgOk "  Tabella svuotata" `
        -msgErr "  ERRORE svuotamento tabella"

    if ($truncResult -eq -1) {
        Write-Host "  ERRORE CRITICO. Interruzione." -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "  Creazione tabella MA_EIEventViewerBackup..." -ForegroundColor Yellow

    # DDL (CREATE TABLE) restituisce -1 da ExecuteNonQuery, non e' un errore
    $createResult = Execute-SqlNonQuery -query @"
    CREATE TABLE $destinationDB.dbo.MA_EIEventViewerBackup(
        [DocCRType] [int] NOT NULL,
        [DocID] [int] NOT NULL,
        [Line] [smallint] NOT NULL,
        [EventDate] [datetime] NULL,
        [Event_Type] [int] NULL,
        [Event_Description] [varchar](255) NULL,
        [Event_XML] [ntext] NULL,
        [Event_String1] [varchar](15) NULL,
        [Event_String2] [varchar](3) NULL,
        [TBCreated] [datetime] NOT NULL,
        [TBModified] [datetime] NOT NULL,
        [TBCreatedID] [int] NOT NULL,
        [TBModifiedID] [int] NOT NULL,
        CONSTRAINT [PK_EIEventViewerBackup] PRIMARY KEY NONCLUSTERED
        (
            [DocCRType] ASC,
            [DocID] ASC,
            [Line] ASC
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
"@ -connString $connString `
        -msgOk "  Tabella creata" `
        -msgErr "  ERRORE creazione tabella"

    # Verifica che la tabella esista effettivamente dopo la creazione
    $verifyExists = Execute-SqlScalar -query @"
SELECT COUNT(*) FROM $destinationDB.sys.objects
WHERE object_id = OBJECT_ID(N'$destinationDB.dbo.MA_EIEventViewerBackup') AND type = 'U'
"@ -connString $connString

    if ($verifyExists -eq 0) {
        Write-Host "  ERRORE CRITICO: tabella non creata. Interruzione." -ForegroundColor Red
        exit
    }
}

Write-Host ""

# ============================================
# FASE 2: Copia dati da origine a backup
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 2: Copia dati in backup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Conta righe origine
$sourceCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.MA_EIEventViewer" -connString $connString
Write-Host "  Righe in MA_EIEventViewer (origine): $sourceCount" -ForegroundColor White

if ($sourceCount -eq 0) {
    Write-Host "  Tabella origine vuota. Nulla da copiare." -ForegroundColor Yellow
    exit
}

# Insert
$insertResult = Execute-SqlNonQuery -query @"
INSERT INTO $destinationDB.dbo.MA_EIEventViewerBackup
    (DocCRType, DocID, Line, EventDate, Event_Type, Event_Description,
     Event_XML, Event_String1, Event_String2,
     TBCreated, TBModified, TBCreatedID, TBModifiedID)
SELECT
    DocCRType, DocID, Line, EventDate, Event_Type, Event_Description,
    Event_XML, Event_String1, Event_String2,
    TBCreated, TBModified, TBCreatedID, TBModifiedID
FROM $destinationDB.dbo.MA_EIEventViewer
"@ -connString $connString `
    -msgOk "  Dati copiati in MA_EIEventViewerBackup" `
    -msgErr "  ERRORE copia dati"

if ($insertResult -eq -1) {
    Write-Host "  ERRORE CRITICO. Interruzione." -ForegroundColor Red
    exit
}

Write-Host ""

# ============================================
# FASE 3: Verifica
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FASE 3: Verifica" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$backupCount = Execute-SqlScalar -query "SELECT COUNT(*) FROM $destinationDB.dbo.MA_EIEventViewerBackup" -connString $connString
Write-Host "  Righe in origine:  $sourceCount" -ForegroundColor White
Write-Host "  Righe in backup:   $backupCount" -ForegroundColor White

if ($sourceCount -eq $backupCount) {
    Write-Host "  OK: conteggio corrispondente" -ForegroundColor Green
}
else {
    Write-Host "  ATTENZIONE: conteggio non corrispondente!" -ForegroundColor Red
}

# ============================================
# RIEPILOGO
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RIEPILOGO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "  Ora inizio:        $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Ora fine:          $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Durata:            $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host ""
Write-Host "  Righe copiate:     $backupCount" -ForegroundColor White
Write-Host ""
Write-Host "  Backup completato. Ora e' possibile eseguire lo script 29." -ForegroundColor Green
