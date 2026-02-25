# Parametri di connessione
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Database da processare
$databases = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

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
foreach ($db in $databases) {
    Write-Host "`nProcessando il database: $db" -ForegroundColor Green
    
    # Query per aggiornare OriginDocID
    $queryOrigin = @"
    UPDATE a
    SET a.OriginDocID = b.NewDocId
    FROM $db.dbo.MA_CrossReferences a 
    INNER JOIN (
        SELECT 
            a.DocumentType, 
            a.OldId, 
            a.NewDocId,
            b.ReferenceCode
        FROM $db.dbo.TAG_CrMaps a
        INNER JOIN $db.dbo.TAG_DocumentTypesCr b 
            ON b.EnumValue = a.DocumentType
    ) b ON b.OldId = a.OriginDocID 
        AND b.ReferenceCode = a.OriginDocType
"@
    Write-Host "`nEsecuzione update OriginDocID..."
    $success = Execute-SqlQuery -database $db -query $queryOrigin
    
    # Query per aggiornare DerivedDocID
    $queryDerived = @"
    UPDATE a
    SET a.DerivedDocID = b.NewDocId
    FROM $db.dbo.MA_CrossReferences a 
    INNER JOIN (
        SELECT 
            a.DocumentType, 
            a.OldId, 
            a.NewDocId,
            b.ReferenceCode
        FROM $db.dbo.TAG_CrMaps a
        INNER JOIN $db.dbo.TAG_DocumentTypesCr b 
            ON b.EnumValue = a.DocumentType
    ) b ON b.OldId = a.DerivedDocID 
        AND b.ReferenceCode = a.DerivedDocType
"@
    Write-Host "`nEsecuzione update DerivedDocID..."
    $success = Execute-SqlQuery -database $db -query $queryDerived
    
    # Query per aggiornare OriginDocID in MA_CrossReferencesNotes
    $queryOriginNotes = @"
    UPDATE a
    SET a.OriginDocID = b.NewDocId
    FROM $db.dbo.MA_CrossReferencesNotes a
    INNER JOIN (
        SELECT
            a.DocumentType,
            a.OldId,
            a.NewDocId,
            b.ReferenceCode
        FROM $db.dbo.TAG_CrMaps a
        INNER JOIN $db.dbo.TAG_DocumentTypesCr b
            ON b.EnumValue = a.DocumentType
    ) b ON b.OldId = a.OriginDocID
        AND b.ReferenceCode = a.OriginDocType
"@
    Write-Host "`nEsecuzione update OriginDocID su MA_CrossReferencesNotes..."
    $success = Execute-SqlQuery -database $db -query $queryOriginNotes

    # Query per aggiornare DerivedDocID in MA_CrossReferencesNotes
    $queryDerivedNotes = @"
    UPDATE a
    SET a.DerivedDocID = b.NewDocId
    FROM $db.dbo.MA_CrossReferencesNotes a
    INNER JOIN (
        SELECT
            a.DocumentType,
            a.OldId,
            a.NewDocId,
            b.ReferenceCode
        FROM $db.dbo.TAG_CrMaps a
        INNER JOIN $db.dbo.TAG_DocumentTypesCr b
            ON b.EnumValue = a.DocumentType
    ) b ON b.OldId = a.DerivedDocID
        AND b.ReferenceCode = a.DerivedDocType
"@
    Write-Host "`nEsecuzione update DerivedDocID su MA_CrossReferencesNotes..."
    $success = Execute-SqlQuery -database $db -query $queryDerivedNotes

    if ($success) {
        Write-Host "Aggiornamenti completati con successo per $db" -ForegroundColor Green
    }
    else {
        Write-Host "Si sono verificati errori nell'aggiornamento di $db" -ForegroundColor Red
    }
}

Write-Host "`nOperazione completata!" -ForegroundColor Green