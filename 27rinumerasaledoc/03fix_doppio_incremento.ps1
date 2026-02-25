# ============================================
# FIX: Correzione doppio incremento SaleDocId
# ============================================
# Problema: script 27 eseguito 2 volte ha causato:
#   - MA_SaleDoc + prime 9 child tables: SaleDocId = originale + 2*incremento (DOPPIO)
#   - Restanti child tables: SaleDocId = originale (MAI incrementate)
#   - TAG_CrMaps: OldId = originale+incremento, NewDocId = originale+2*incremento (SBAGLIATO)
#
# Fix:
#   1. Annulla doppio incremento (riporta a singolo) usando TAG_CrMaps.NewDocId
#   2. Ricostruisce TAG_CrMaps correttamente
#   3. Incrementa le tabelle mai aggiornate
#   4. Dopo questo script, rieseguire la Fase 5 (scripts 18, 19, 19Bis, 20, 21)
# ============================================

$sqlServer = "192.168.0.3\sql2008"
$username = "sa"
$password = "stream"

# Database e incrementi (stessi del script 27 originale)
$databaseConfigs = @{
    "gpxnetclone"     = 400000
    "furmanetclone"   = 200000
    "vedbondifeclone"  = 300000
}

# Tabelle che sono state DOPPIAMENTE incrementate (aggiornate sia nella prima che nella seconda esecuzione)
$doubleIncrementedTables = @(
    "MA_SaleDoc",
    "MA_SaleDocDetail",
    "MA_SaleDocComponents",
    "MA_SaleDocManufReasons",
    "MA_SaleDocNotes",
    "MA_SaleDocPymtSched",
    "MA_SaleDocReferences",
    "MA_SaleDocShipping",
    "MA_SaleDocSummary",
    "MA_SaleDocTaxSummary"
)

# Tabelle che NON sono MAI state incrementate (prima esecuzione: errore prima di arrivarci, seconda: no match)
$neverIncrementedTables = @(
    "MA_SaleDocDetailAccDef",
    "MA_SaleDocDetailVar",
    "IM_SaleDocJobs",
    "MA_BRNotaFiscalForCustomer",
    "MA_BRNotaFiscalForCustDetail",
    "MA_BRNotaFiscalForCustSummary",
    "MA_BRNotaFiscalForCustRef",
    "MA_BRNotaFiscalForCustShipping",
    "MA_BRNotaFiscalForCustAdDat",
    "MA_CostAccEntries",
    "MA_PurchaseDocDetail",
    "IM_Schedules",
    "MA_WMPreShippingDetails"
)

# Specie Archivio per documenti di vendita (stesse del script 27)
$saleDocEnumValues = @(
    3801088, 3801089, 3801090, 3801091, 3801094, 3801095,
    3801096, 3801097, 3801101, 3801102, 3801103, 3801104,
    3801105, 3801106, 3801107, 3801108, 3801110
)
$saleDocEnumValuesSQL = $saleDocEnumValues -join ", "

function Execute-SqlQuery {
    param (
        [string]$server,
        [string]$database,
        [string]$query,
        [string]$username,
        [string]$password
    )
    $connectionString = "Server=$server;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $command.CommandTimeout = 300
    try {
        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
        $connection.Open()
        $rowsAffected = $command.ExecuteNonQuery()
        return $rowsAffected
    }
    catch {
        Write-Error $_.Exception.Message
        throw $_
    }
    finally {
        if ($connection.State -eq [System.Data.ConnectionState]::Open) {
            $connection.Close()
        }
    }
}

function Test-TableExists {
    param (
        [string]$database,
        [string]$table
    )
    $checkQuery = "SELECT COUNT(*) FROM [$database].sys.objects WHERE object_id = OBJECT_ID(N'[$database].[dbo].[$table]') AND type in (N'U')"
    $connectionString = "Server=$sqlServer;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
    $conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $cmd = New-Object System.Data.SqlClient.SqlCommand($checkQuery, $conn)
    $cmd.CommandTimeout = 300
    try {
        $conn.Open()
        $result = $cmd.ExecuteScalar()
        return ($result -gt 0)
    }
    finally {
        if ($conn.State -eq [System.Data.ConnectionState]::Open) { $conn.Close() }
    }
}

function Set-ForeignKeyConstraints {
    param (
        [string]$database,
        [string]$action
    )
    $getConstraintsQuery = @"
    USE [$database];
    SELECT
        'ALTER TABLE [' + OBJECT_NAME(fk.parent_object_id) + '] ' +
        (CASE WHEN '$action' = 'NOCHECK' THEN 'NOCHECK' ELSE 'WITH CHECK CHECK' END) +
        ' CONSTRAINT [' + fk.name + ']'
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE OBJECT_NAME(fk.referenced_object_id) = 'MA_SaleDoc'
      AND COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) = 'SaleDocId';
"@
    $connectionString = "Server=$sqlServer;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $command = New-Object System.Data.SqlClient.SqlCommand($getConstraintsQuery, $connection)
    $command.CommandTimeout = 300
    try {
        $connection.Open()
        $reader = $command.ExecuteReader()
        $queries = @()
        while ($reader.Read()) { $queries += $reader.GetString(0) }
        $reader.Close()
        foreach ($query in $queries) {
            Write-Host "    $query"
            Execute-SqlQuery -server $sqlServer -database $database -query $query -username $username -password $password | Out-Null
        }
        Write-Host "  FK constraints set to $action" -ForegroundColor Green
    }
    catch {
        Write-Host "  Error setting FK constraints to $action : $_" -ForegroundColor Red
        throw
    }
    finally {
        if ($connection.State -eq 'Open') { $connection.Close() }
    }
}

# ============================================
# MAIN
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  FIX DOPPIO INCREMENTO SaleDocId" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

foreach ($dbConfig in $databaseConfigs.GetEnumerator()) {
    $database = $dbConfig.Key
    $increment = $dbConfig.Value

    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Database: $database (incremento: $increment)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    # ---- VERIFICA PRELIMINARE ----
    # Controlla che TAG_CrMaps esista e abbia i dati attesi (OldId = originale+incremento)
    $verifyQuery = @"
    USE [$database]
    SELECT TOP 5 OldId, NewDocId, NewDocId - OldId as Diff
    FROM TAG_CrMaps
    WHERE DocumentType IN ($saleDocEnumValuesSQL)
    ORDER BY OldId
"@
    $connectionString = "Server=$sqlServer;Database=$database;User ID=$username;Password=$password;Connection Timeout=300"
    $verifyConn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $verifyCmd = New-Object System.Data.SqlClient.SqlCommand($verifyQuery, $verifyConn)
    $verifyCmd.CommandTimeout = 300
    try {
        $verifyConn.Open()
        $reader = $verifyCmd.ExecuteReader()
        Write-Host "`n  Verifica TAG_CrMaps (primi 5 record SaleDoc):" -ForegroundColor Cyan
        $recordCount = 0
        while ($reader.Read()) {
            $recordCount++
            Write-Host "    OldId=$($reader['OldId']), NewDocId=$($reader['NewDocId']), Diff=$($reader['Diff'])"
        }
        $reader.Close()
        if ($recordCount -eq 0) {
            Write-Host "  ATTENZIONE: Nessun record SaleDoc in TAG_CrMaps per $database!" -ForegroundColor Red
            Write-Host "  Salto questo database." -ForegroundColor Red
            continue
        }
        Write-Host "  Diff attesa: $increment (se diverso, il fix potrebbe non funzionare)" -ForegroundColor Yellow
    }
    finally {
        if ($verifyConn.State -eq 'Open') { $verifyConn.Close() }
    }

    try {
        # ---- STEP 0: Disabilita FK ----
        Write-Host "`n  STEP 0: Disabilita FK constraints..." -ForegroundColor Cyan
        Set-ForeignKeyConstraints -database $database -action "NOCHECK"

        # ---- STEP 1: Annulla doppio incremento ----
        # TAG_CrMaps attuale: OldId = originale+incremento, NewDocId = originale+2*incremento
        # Le tabelle doppiamente incrementate hanno SaleDocId = NewDocId
        # Le riportiamo a SaleDocId = OldId (cioe' originale+incremento = singolo incremento corretto)
        Write-Host "`n  STEP 1: Annulla doppio incremento (SaleDocId - $increment)..." -ForegroundColor Cyan

        foreach ($table in $doubleIncrementedTables) {
            if (-not (Test-TableExists -database $database -table $table)) {
                Write-Host "    $table non esiste - skip" -ForegroundColor DarkGray
                continue
            }
            $undoQuery = @"
            USE [$database]
            UPDATE $table WITH (ROWLOCK)
            SET SaleDocId = SaleDocId - $increment
            WHERE SaleDocId IN (SELECT NewDocId FROM TAG_CrMaps WHERE DocumentType IN ($saleDocEnumValuesSQL))
"@
            try {
                $rows = Execute-SqlQuery -server $sqlServer -database $database -query $undoQuery -username $username -password $password
                Write-Host "    $table : $rows righe corrette (doppio -> singolo)" -ForegroundColor Green
            }
            catch {
                Write-Host "    ERRORE su $table : $_" -ForegroundColor Red
                throw
            }
        }

        # ---- STEP 2: Ricostruisci TAG_CrMaps ----
        # Ora MA_SaleDoc ha SaleDocId = originale + incremento (singolo, corretto)
        # Ricostruiamo TAG_CrMaps con: OldId = originale, NewDocId = originale+incremento
        Write-Host "`n  STEP 2: Ricostruzione TAG_CrMaps..." -ForegroundColor Cyan

        $rebuildQuery = @"
        USE [$database]
        BEGIN TRY
            BEGIN TRANSACTION;

            DELETE FROM TAG_CrMaps WHERE DocumentType IN ($saleDocEnumValuesSQL);

            INSERT INTO TAG_CrMaps (OldId, DocumentType, NewDocId)
            SELECT
                SaleDocId - $increment as OldId,
                CASE DocumentType
                    WHEN 3407873 THEN 3801088
                    WHEN 3407874 THEN 3801095
                    WHEN 3407875 THEN 3801091
                    WHEN 3407876 THEN 3801097
                    WHEN 3407877 THEN 3801101
                    WHEN 3407878 THEN 3801104
                    WHEN 3407879 THEN 3801105
                    WHEN 3407880 THEN 3801106
                    WHEN 3407881 THEN 3801107
                    WHEN 3407882 THEN 3801108
                    WHEN 3407883 THEN 3801102
                    WHEN 3407884 THEN 3801103
                    WHEN 3407885 THEN 3801094
                    WHEN 3407886 THEN 3801096
                    WHEN 3407887 THEN 3801089
                    WHEN 3407888 THEN 3801090
                    WHEN 3407889 THEN 3801110
                END as DocumentType,
                SaleDocId as NewDocId
            FROM MA_SaleDoc
            WHERE SaleDocId IS NOT NULL
              AND DocumentType BETWEEN 3407873 AND 3407889;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
            RAISERROR (@Err, 16, 1);
        END CATCH
"@
        try {
            Execute-SqlQuery -server $sqlServer -database "master" -query $rebuildQuery -username $username -password $password | Out-Null
            Write-Host "    TAG_CrMaps ricostruita (OldId=originale, NewDocId=originale+$increment)" -ForegroundColor Green
        }
        catch {
            Write-Host "    ERRORE ricostruzione TAG_CrMaps: $_" -ForegroundColor Red
            throw
        }

        # Verifica nuovi valori
        $verifyConn2 = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $verifyCmd2 = New-Object System.Data.SqlClient.SqlCommand("USE [$database]; SELECT TOP 3 OldId, NewDocId, NewDocId-OldId as Diff FROM TAG_CrMaps WHERE DocumentType IN ($saleDocEnumValuesSQL) ORDER BY OldId", $verifyConn2)
        $verifyCmd2.CommandTimeout = 300
        try {
            $verifyConn2.Open()
            $reader2 = $verifyCmd2.ExecuteReader()
            Write-Host "    Verifica (primi 3):" -ForegroundColor Cyan
            while ($reader2.Read()) {
                Write-Host "      OldId=$($reader2['OldId']), NewDocId=$($reader2['NewDocId']), Diff=$($reader2['Diff'])"
            }
            $reader2.Close()
        }
        finally { if ($verifyConn2.State -eq 'Open') { $verifyConn2.Close() } }

        # ---- STEP 3: Incrementa tabelle mai aggiornate ----
        # TAG_CrMaps ora ha OldId = originale. Le tabelle mai incrementate hanno SaleDocId = originale.
        # Il WHERE matchera' correttamente e le portera' a originale+incremento.
        Write-Host "`n  STEP 3: Incrementa tabelle mai aggiornate (SaleDocId + $increment)..." -ForegroundColor Cyan

        foreach ($table in $neverIncrementedTables) {
            if (-not (Test-TableExists -database $database -table $table)) {
                Write-Host "    $table non esiste - skip" -ForegroundColor DarkGray
                continue
            }
            $incrementQuery = @"
            USE [$database]
            UPDATE $table WITH (ROWLOCK)
            SET SaleDocId = SaleDocId + $increment
            WHERE SaleDocId IN (SELECT OldId FROM TAG_CrMaps WHERE DocumentType IN ($saleDocEnumValuesSQL))
"@
            try {
                $rows = Execute-SqlQuery -server $sqlServer -database $database -query $incrementQuery -username $username -password $password
                Write-Host "    $table : $rows righe incrementate" -ForegroundColor Green
            }
            catch {
                Write-Host "    ERRORE su $table : $_" -ForegroundColor Red
                throw
            }
        }
    }
    catch {
        Write-Host "`n  ERRORE DURANTE IL FIX di $database! Verificare lo stato manualmente." -ForegroundColor Red
        Write-Host "  Dettaglio: $_" -ForegroundColor Red
    }
    finally {
        # ---- STEP 4: Riabilita FK ----
        Write-Host "`n  STEP 4: Riabilita FK constraints..." -ForegroundColor Cyan
        try {
            Set-ForeignKeyConstraints -database $database -action "CHECK"
        }
        catch {
            Write-Host "  ATTENZIONE: Errore riabilitazione FK su $database" -ForegroundColor Red
        }
    }

    Write-Host "`n  $database completato." -ForegroundColor Green
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  FIX COMPLETATO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prossimi passi:" -ForegroundColor Yellow
Write-Host "  1. Rieseguire Fase 5 completa (scripts 18, 19, 19Bis, 20, 21, 22)" -ForegroundColor Yellow
Write-Host "  2. Lo script 27 originale NON va rieseguito (i SaleDocId sono gia' corretti)" -ForegroundColor Yellow
