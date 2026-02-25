<#
.SYNOPSIS
    Esegue una query per confrontare i valori massimi degli ID con i valori LastId in MA_IDNumbers
    e salva i risultati in una tabella MM4_mappaIds nel database VEDMaster.
.DESCRIPTION
    Questo script confronta i valori massimi degli ID presenti nelle tabelle con i valori LastId
    registrati in MA_IDNumbers e crea una tabella MM4_mappaIds con i risultati dell'analisi.
.NOTES
    Author: System Administrator
    Date: June 11, 2025
#>

# Parametri di connessione SQL Server
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DatabaseName = "VEDMaster"
$connectionTimeout = 30
$queryTimeout = 300  # Timeout esteso per query complesse

# Prepara stringa di connessione con autenticazione SQL
$connectionString = "Server=$ServerInstance;Database=$DatabaseName;User Id=$SqlUsername;Password=$SqlPassword;Connect Timeout=$connectionTimeout"

# Query per creare la tabella MM4_mappaIds se non esiste
$createTableQuery = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_mappaIds]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[MM4_mappaIds](
        [TipoDocumento] [nvarchar](100) NOT NULL,
        [CodeType] [int] NOT NULL,
        [MaxIdAttuale] [int] NULL,
        [LastIdInMAIdNumbers] [int] NULL,
        [Stato] [nvarchar](50) NULL,
        [DataAnalisi] [datetime] NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_MM4_mappaIds] PRIMARY KEY CLUSTERED ([CodeType] ASC)
    )
END
ELSE
BEGIN
    TRUNCATE TABLE [dbo].[MM4_mappaIds]
END
"@

# Query per confrontare gli ID e inserire i risultati nella tabella
$confrontaIdQuery = @"
-- Inserisce i risultati nella tabella MM4_mappaIds
INSERT INTO [dbo].[MM4_mappaIds] ([TipoDocumento], [CodeType], [MaxIdAttuale], [LastIdInMAIdNumbers], [Stato])

-- Documenti di vendita (3801088)
SELECT 
    'Documenti di vendita' AS [TipoDocumento],
    3801088 AS CodeType,
    ISNULL((SELECT MAX(saledocid) FROM VEDMaster.dbo.ma_saledoc), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(saledocid) FROM VEDMaster.dbo.ma_saledoc), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(saledocid) FROM VEDMaster.dbo.ma_saledoc) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801088

UNION ALL

-- Intrastat (3801091)
SELECT 
    'Intrastat' AS [TipoDocumento],
    3801091 AS CodeType,
    ISNULL((SELECT MAX(IntrastatId) FROM VEDMaster.dbo.MA_Intra), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(IntrastatId) FROM VEDMaster.dbo.MA_Intra), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(IntrastatId) FROM VEDMaster.dbo.MA_Intra) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801091

UNION ALL

-- Movimenti di magazzino (3801093)
SELECT 
    'Movimenti di magazzino' AS [TipoDocumento],
    3801093 AS CodeType,
    ISNULL((SELECT MAX(EntryId) FROM VEDMaster.dbo.MA_InventoryEntries), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(EntryId) FROM VEDMaster.dbo.MA_InventoryEntries), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(EntryId) FROM VEDMaster.dbo.MA_InventoryEntries) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801093

UNION ALL

-- Ordini clienti (3801098)
SELECT 
    'Ordini clienti' AS [TipoDocumento],
    3801098 AS CodeType,
    ISNULL((SELECT MAX(SaleOrdId) FROM VEDMaster.dbo.MA_SaleOrd), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(SaleOrdId) FROM VEDMaster.dbo.MA_SaleOrd), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(SaleOrdId) FROM VEDMaster.dbo.MA_SaleOrd) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801098

UNION ALL

-- Offerte clienti (3801099)
SELECT 
    'Offerte clienti' AS [TipoDocumento],
    3801099 AS CodeType,
    ISNULL((SELECT MAX(CustQuotaId) FROM VEDMaster.dbo.MA_CustQuotas), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(CustQuotaId) FROM VEDMaster.dbo.MA_CustQuotas), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(CustQuotaId) FROM VEDMaster.dbo.MA_CustQuotas) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801099

UNION ALL

-- Ordini fornitori (3801100)
SELECT 
    'Ordini fornitori' AS [TipoDocumento],
    3801100 AS CodeType,
    ISNULL((SELECT MAX(PurchaseOrdId) FROM VEDMaster.dbo.MA_PurchaseOrd), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(PurchaseOrdId) FROM VEDMaster.dbo.MA_PurchaseOrd), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(PurchaseOrdId) FROM VEDMaster.dbo.MA_PurchaseOrd) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801100

UNION ALL

-- Acquisti (3801108)
SELECT 
    'Acquisti' AS [TipoDocumento],
    3801108 AS CodeType,
    ISNULL((SELECT MAX(PurchaseDocId) FROM VEDMaster.dbo.MA_PurchaseDoc), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(PurchaseDocId) FROM VEDMaster.dbo.MA_PurchaseDoc), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(PurchaseDocId) FROM VEDMaster.dbo.MA_PurchaseDoc) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801108

UNION ALL

-- Offerte fornitore (3801109)
SELECT 
    'Offerte fornitore' AS [TipoDocumento],
    3801109 AS CodeType,
    ISNULL((SELECT MAX(SuppQuotaId) FROM VEDMaster.dbo.MA_SuppQuotas), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(SuppQuotaId) FROM VEDMaster.dbo.MA_SuppQuotas), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(SuppQuotaId) FROM VEDMaster.dbo.MA_SuppQuotas) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801109

UNION ALL

-- LIFO/FIFO (3801115)
SELECT 
    'LIFO/FIFO' AS [TipoDocumento],
    3801115 AS CodeType,
    ISNULL((SELECT MAX(ReceiptBatchId) FROM VEDMaster.dbo.MA_ReceiptsBatch), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(ReceiptBatchId) FROM VEDMaster.dbo.MA_ReceiptsBatch), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(ReceiptBatchId) FROM VEDMaster.dbo.MA_ReceiptsBatch) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801115

UNION ALL

-- RDA (3801104)
SELECT 
    'RDA' AS [TipoDocumento],
    3801104 AS CodeType,
    ISNULL((SELECT MAX(PurchaseRequestId) FROM VEDMaster.dbo.IM_PurchaseRequest), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(PurchaseRequestId) FROM VEDMaster.dbo.IM_PurchaseRequest), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(PurchaseRequestId) FROM VEDMaster.dbo.IM_PurchaseRequest) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801104

UNION ALL

-- Rapportini (3801188)
SELECT 
    'Rapportini' AS [TipoDocumento],
    3801188 AS CodeType,
    ISNULL((SELECT MAX(WorkingReportId) FROM VEDMaster.dbo.IM_WorkingReports), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(WorkingReportId) FROM VEDMaster.dbo.IM_WorkingReports), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(WorkingReportId) FROM VEDMaster.dbo.IM_WorkingReports) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801188

UNION ALL

-- Libretti misure (3801290)
SELECT 
    'Libretti misure' AS [TipoDocumento],
    3801290 AS CodeType,
    ISNULL((SELECT MAX(MeasuresBookId) FROM VEDMaster.dbo.IM_MeasuresBooks), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(MeasuresBookId) FROM VEDMaster.dbo.IM_MeasuresBooks), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(MeasuresBookId) FROM VEDMaster.dbo.IM_MeasuresBooks) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801290

UNION ALL

-- SAL (3801291)
SELECT 
    'SAL' AS [TipoDocumento],
    3801291 AS CodeType,
    ISNULL((SELECT MAX(WPRId) FROM VEDMaster.dbo.IM_WorksProgressReport), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(WPRId) FROM VEDMaster.dbo.IM_WorksProgressReport), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(WPRId) FROM VEDMaster.dbo.IM_WorksProgressReport) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801291

UNION ALL

-- Estratto conto (3801292)
SELECT 
    'Estratto conto' AS [TipoDocumento],
    3801292 AS CodeType,
    ISNULL((SELECT MAX(StatOfAccountId) FROM VEDMaster.dbo.IM_StatOfAccount), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(StatOfAccountId) FROM VEDMaster.dbo.IM_StatOfAccount), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(StatOfAccountId) FROM VEDMaster.dbo.IM_StatOfAccount) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801292

UNION ALL

-- Richieste offerta cliente (3801318)
SELECT 
    'Richieste offerta cliente' AS [TipoDocumento],
    3801318 AS CodeType,
    ISNULL((SELECT MAX(QuotationRequestId) FROM VEDMaster.dbo.IM_QuotationRequests), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(QuotationRequestId) FROM VEDMaster.dbo.IM_QuotationRequests), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(QuotationRequestId) FROM VEDMaster.dbo.IM_QuotationRequests) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801318

UNION ALL

-- Jobs (3801316)
SELECT 
    'Jobs' AS [TipoDocumento],
    3801316 AS CodeType,
    ISNULL((SELECT MAX(IM_JobId) FROM VEDMaster.dbo.MA_Jobs), 0) AS [MaxIdAttuale],
    ISNULL(LastId, 0) AS [LastIdInMAIdNumbers],
    CASE 
        WHEN ISNULL((SELECT MAX(IM_JobId) FROM VEDMaster.dbo.MA_Jobs), 0) > ISNULL(LastId, 0) THEN 'Discrepanza!'
        WHEN LastId IS NULL THEN 'LastId è NULL!'
        WHEN (SELECT MAX(IM_JobId) FROM VEDMaster.dbo.MA_Jobs) IS NULL THEN 'Max ID è NULL!'
        ELSE 'OK'
    END AS [Stato]
FROM VEDMaster.dbo.MA_IDNumbers WHERE CodeType = 3801316
"@

# Funzione per eseguire query SQL
function Execute-SqlQuery {
    param (
        [string]$query,
        [string]$connectionString,
        [string]$messageSuccess,
        [string]$messageError
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()
        
        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = $query
        $command.CommandTimeout = $queryTimeout
        $command.ExecuteNonQuery() | Out-Null
        
        $connection.Close()
        Write-Host $messageSuccess -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "$messageError`: $_" -ForegroundColor Red
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        return $false
    }
}

# Funzione per ottenere i risultati della tabella
function Get-SqlData {
    param (
        [string]$query,
        [string]$connectionString
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()
        
        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = $query
        $command.CommandTimeout = $queryTimeout
        
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataSet = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null
        
        $connection.Close()
        return $dataSet.Tables[0]
    }
    catch {
        Write-Host "Errore nel recupero dei dati: $_" -ForegroundColor Red
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        return $null
    }
}

# Esecuzione delle operazioni
Write-Host "Inizio elaborazione analisi ID..." -ForegroundColor Yellow

# Crea o svuota la tabella MM4_mappaIds
$result = Execute-SqlQuery -query $createTableQuery -connectionString $connectionString `
    -messageSuccess "Tabella MM4_mappaIds creata/svuotata correttamente." `
    -messageError "Errore nella creazione della tabella MM4_mappaIds"

if ($result) {
    # Esegui la query di confronto e inserisci i risultati
    $result = Execute-SqlQuery -query $confrontaIdQuery -connectionString $connectionString `
        -messageSuccess "Dati di confronto ID inseriti nella tabella MM4_mappaIds." `
        -messageError "Errore nell'inserimento dei dati di confronto"

    if ($result) {
        # Recupera e visualizza un riassunto dei risultati
        $resultsQuery = "SELECT TipoDocumento, CodeType, MaxIdAttuale, LastIdInMAIdNumbers, Stato FROM MM4_mappaIds ORDER BY CodeType"
        $results = Get-SqlData -query $resultsQuery -connectionString $connectionString
        
        if ($results) {
            Write-Host "`nRiepilogo dei risultati:" -ForegroundColor Cyan
            $results | Format-Table -AutoSize
            
            # Mostra un conteggio degli stati
            $discrepanze = ($results | Where-Object { $_.Stato -eq 'Discrepanza!' }).Count
            $nullLastId = ($results | Where-Object { $_.Stato -eq 'LastId è NULL!' }).Count
            $nullMaxId = ($results | Where-Object { $_.Stato -eq 'Max ID è NULL!' }).Count
            $ok = ($results | Where-Object { $_.Stato -eq 'OK' }).Count
            
            Write-Host "`nStatistiche:" -ForegroundColor Cyan
            Write-Host "- Discrepanze trovate: $discrepanze" -ForegroundColor $(if ($discrepanze -gt 0) { 'Red' } else { 'Green' })
            Write-Host "- LastId NULL: $nullLastId" -ForegroundColor $(if ($nullLastId -gt 0) { 'Yellow' } else { 'Green' })
            Write-Host "- Max ID NULL: $nullMaxId" -ForegroundColor $(if ($nullMaxId -gt 0) { 'Yellow' } else { 'Green' })
            Write-Host "- OK: $ok" -ForegroundColor Green


            # Chiedi all'utente se vuole aggiornare MA_IDNumbers
            $aggiorna = Read-Host "`nVuoi aggiornare la tabella MA_IDNumbers con i valori massimi rilevati? (S/N)"
    
            if ($aggiorna -eq "S" -or $aggiorna -eq "s") {
                # Query per aggiornare MA_IDNumbers
                $updateIdNumbersQuery = @"
        -- Aggiorna MA_IDNumbers con i valori massimi rilevati
        UPDATE MA_IDNumbers
        SET LastId = mappa.MaxIdAttuale
        FROM MA_IDNumbers ids
        INNER JOIN MM4_mappaIds mappa ON ids.CodeType = mappa.CodeType
        WHERE mappa.MaxIdAttuale > ids.LastId OR ids.LastId IS NULL;
"@
        
                # Esegui la query di aggiornamento
                $resultUpdate = Execute-SqlQuery -query $updateIdNumbersQuery -connectionString $connectionString `
                    -messageSuccess "Tabella MA_IDNumbers aggiornata correttamente." `
                    -messageError "Errore nell'aggiornamento della tabella MA_IDNumbers"
        
                if ($resultUpdate) {
                    # Recupera e visualizza le righe aggiornate
                    $updatedQuery = @"
            SELECT 
                m.TipoDocumento,
                m.CodeType,
                m.MaxIdAttuale AS [Nuovo LastId],
                m.LastIdInMAIdNumbers AS [Vecchio LastId]
            FROM MM4_mappaIds m
            INNER JOIN MA_IDNumbers i ON m.CodeType = i.CodeType
            WHERE m.MaxIdAttuale <> m.LastIdInMAIdNumbers OR m.LastIdInMAIdNumbers IS NULL
            ORDER BY m.CodeType
"@
            
                    $updatedRows = Get-SqlData -query $updatedQuery -connectionString $connectionString
            
                    if ($updatedRows -and $updatedRows.Rows.Count -gt 0) {
                        Write-Host "`nRighe aggiornate in MA_IDNumbers:" -ForegroundColor Yellow
                        $updatedRows | Format-Table -AutoSize
                
                        Write-Host "Totale record aggiornati: $($updatedRows.Rows.Count)" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Nessun record necessitava di aggiornamento." -ForegroundColor Cyan
                    }
                }
            }
            else {
                Write-Host "Aggiornamento annullato." -ForegroundColor Yellow
            }

        }
    }
}

Write-Host "`nOperazione completata." -ForegroundColor Yellow