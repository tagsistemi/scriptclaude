# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Definizione dei database e dei loro incrementi
$databaseIncrements = @{
    "gpxnetclone" = 100000
    "furmanetclone" = 200000
    "vedbondifeclone" = 300000
}

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
        $cmd.CommandTimeout = 0  # Nessun timeout
        
        $rowsAffected = $cmd.ExecuteNonQuery()
        Write-Host "Query eseguita con successo. Righe modificate: $rowsAffected"
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

# Elaborazione per ogni database
foreach ($db in $databaseIncrements.Keys) {
    Write-Host "`nProcessando il database: $db" -ForegroundColor Green
    $increment = $databaseIncrements[$db]
    Write-Host "Incremento da applicare: $increment"
    
    # DocType 27066672
    # Query per incrementare OriginDocID
    $queryOrigin672 = @"
    UPDATE $db.dbo.MA_CrossReferences 
    SET OriginDocID = OriginDocID + $increment
    WHERE OriginDocType = 27066672 AND OriginDocID <= $increment
"@
    Write-Host "`nEsecuzione update OriginDocID per DocType 27066672..."
    $success = Execute-SqlQuery -database $db -query $queryOrigin672
    
    # Query per incrementare DerivedDocID
    $queryDerived672 = @"
    UPDATE $db.dbo.MA_CrossReferences 
    SET DerivedDocID = DerivedDocID + $increment
    WHERE DerivedDocType = 27066672 AND DerivedDocID <= $increment
"@
    Write-Host "`nEsecuzione update DerivedDocID per DocType 27066672..."
    $success = Execute-SqlQuery -database $db -query $queryDerived672
    
    # DocType 27066673
    # Query per incrementare OriginDocID
    $queryOrigin673 = @"
    UPDATE $db.dbo.MA_CrossReferences 
    SET OriginDocID = OriginDocID + $increment
    WHERE OriginDocType = 27066673 AND OriginDocID <= $increment
"@
    Write-Host "`nEsecuzione update OriginDocID per DocType 27066673..."
    $success = Execute-SqlQuery -database $db -query $queryOrigin673
    
    # Query per incrementare DerivedDocID
    $queryDerived673 = @"
    UPDATE $db.dbo.MA_CrossReferences 
    SET DerivedDocID = DerivedDocID + $increment
    WHERE DerivedDocType = 27066673 AND DerivedDocID <= $increment
"@
    Write-Host "`nEsecuzione update DerivedDocID per DocType 27066673..."
    $success = Execute-SqlQuery -database $db -query $queryDerived673
    
    if ($success) {
        Write-Host "Aggiornamenti completati con successo per $db" -ForegroundColor Green
    }
    else {
        Write-Host "Si sono verificati errori nell'aggiornamento di $db" -ForegroundColor Red
    }
}

Write-Host "`nOperazione completata!" -ForegroundColor Green