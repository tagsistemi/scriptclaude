# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Funzione per eseguire una query SQL
function Execute-SqlQuery {
    param (
        [string]$database,
        [string]$query
    )
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server=$ServerInstance;Database=$database;User Id=$SqlUsername;Password=$SqlPassword;"
        $conn.Open()
        
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 0
        
        $rowsAffected = $cmd.ExecuteNonQuery()
        Write-Host "Query eseguita con successo su $database. Righe modificate: $rowsAffected"
        return $true
    }
    catch {
        Write-Error "Errore nell'esecuzione della query su $database : $_"
        return $false
    }
    finally {
        if ($conn -and $conn.State -eq 'Open') {
            $conn.Close()
        }
    }
}

# DocType per Commesse (Job e Commessa correlata)
$jobDocTypes = @(27066672, 27066673)
$jobDocTypesSQL = $jobDocTypes -join ", "

# Database da processare
$databases = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

foreach ($db in $databases) {
    Write-Host "`nProcessando il database: $db" -ForegroundColor Green

    # Verifica che MM4_MappaJobsCodes esista nel database
    $checkQuery = @"
    SELECT COUNT(*) AS C FROM $db.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'MM4_MappaJobsCodes' AND TABLE_SCHEMA = 'dbo'
"@
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server=$ServerInstance;Database=$db;User Id=$SqlUsername;Password=$SqlPassword;"
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($checkQuery, $conn)
        $result = $cmd.ExecuteScalar()
        $conn.Close()

        if ($result -eq 0) {
            Write-Host "  MM4_MappaJobsCodes non presente in $db, salto" -ForegroundColor DarkGray
            continue
        }
    }
    catch {
        Write-Host "  Errore verifica MM4_MappaJobsCodes in $db : $_" -ForegroundColor Red
        continue
    }

    # --- OriginDocID ---
    # Step 1: Elimina righe con vecchio OriginDocID che andrebbero in conflitto PK
    $deleteOrigin = @"
    DELETE d
    FROM $db.dbo.MM4_MappaJobsCodes a
    INNER JOIN MA_Jobs b ON b.Job = a.vecchiocodice
    INNER JOIN MA_Jobs c ON c.Job = a.nuovocodice
    INNER JOIN MA_CrossReferences d ON d.OriginDocID = b.IM_JobId
        AND d.OriginDocType IN ($jobDocTypesSQL)
    WHERE d.OriginDocID <> c.IM_JobId
      AND EXISTS (
        SELECT 1 FROM MA_CrossReferences x
        WHERE x.OriginDocType = d.OriginDocType
          AND x.OriginDocID = c.IM_JobId
          AND x.OriginDocSubID = d.OriginDocSubID
          AND x.OriginDocLine = d.OriginDocLine
          AND x.DerivedDocType = d.DerivedDocType
          AND x.DerivedDocID = d.DerivedDocID
          AND x.DerivedDocSubID = d.DerivedDocSubID
          AND x.DerivedDocLine = d.DerivedDocLine
      )
"@
    Write-Host "  Rimozione duplicati OriginDocID..."
    Execute-SqlQuery -database $db -query $deleteOrigin

    # Step 2: Aggiorna OriginDocID
    $queryOrigin = @"
    UPDATE d
    SET d.OriginDocID = c.IM_JobId
    FROM $db.dbo.MM4_MappaJobsCodes a
    INNER JOIN MA_Jobs b ON b.Job = a.vecchiocodice
    INNER JOIN MA_Jobs c ON c.Job = a.nuovocodice
    INNER JOIN MA_CrossReferences d ON d.OriginDocID = b.IM_JobId
        AND d.OriginDocType IN ($jobDocTypesSQL)
    WHERE d.OriginDocID <> c.IM_JobId
"@
    Write-Host "  Esecuzione update OriginDocID..."
    Execute-SqlQuery -database $db -query $queryOrigin

    # --- DerivedDocID ---
    # Step 1: Elimina righe con vecchio DerivedDocID che andrebbero in conflitto PK
    $deleteDerived = @"
    DELETE d
    FROM $db.dbo.MM4_MappaJobsCodes a
    INNER JOIN MA_Jobs b ON b.Job = a.vecchiocodice
    INNER JOIN MA_Jobs c ON c.Job = a.nuovocodice
    INNER JOIN MA_CrossReferences d ON d.DerivedDocID = b.IM_JobId
        AND d.DerivedDocType IN ($jobDocTypesSQL)
    WHERE d.DerivedDocID <> c.IM_JobId
      AND EXISTS (
        SELECT 1 FROM MA_CrossReferences x
        WHERE x.OriginDocType = d.OriginDocType
          AND x.OriginDocID = d.OriginDocID
          AND x.OriginDocSubID = d.OriginDocSubID
          AND x.OriginDocLine = d.OriginDocLine
          AND x.DerivedDocType = d.DerivedDocType
          AND x.DerivedDocID = c.IM_JobId
          AND x.DerivedDocSubID = d.DerivedDocSubID
          AND x.DerivedDocLine = d.DerivedDocLine
      )
"@
    Write-Host "  Rimozione duplicati DerivedDocID..."
    Execute-SqlQuery -database $db -query $deleteDerived

    # Step 2: Aggiorna DerivedDocID
    $queryDerived = @"
    UPDATE d
    SET d.DerivedDocID = c.IM_JobId
    FROM $db.dbo.MM4_MappaJobsCodes a
    INNER JOIN MA_Jobs b ON b.Job = a.vecchiocodice
    INNER JOIN MA_Jobs c ON c.Job = a.nuovocodice
    INNER JOIN MA_CrossReferences d ON d.DerivedDocID = b.IM_JobId
        AND d.DerivedDocType IN ($jobDocTypesSQL)
    WHERE d.DerivedDocID <> c.IM_JobId
"@
    Write-Host "  Esecuzione update DerivedDocID..."
    Execute-SqlQuery -database $db -query $queryDerived

    Write-Host "  Aggiornamento completato per $db" -ForegroundColor Green
}

Write-Host "`nOperazione completata!" -ForegroundColor Green