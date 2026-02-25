# Parametri di connessione
$ServerInstance = "192.168.0.3\sql2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Database da processare 
$databases = @("vedbondifeclone", "furmanetclone", "gpxnetclone")

# Database di destinazione
$destDB = "MM4HelperDb"

# Funzione per creare la tabella di destinazione
function Create-DestinationTable {
    param (
        $suffix
    )
    
    $createTableSQL = @"
    -- Drop della tabella se esiste
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MA_CrossReferences$suffix]') AND type in (N'U'))
    BEGIN
        DROP TABLE [dbo].[MA_CrossReferences$suffix]
    END

    -- Creazione della nuova tabella
    CREATE TABLE [dbo].[MA_CrossReferences$suffix](
        [OriginDocType] [int] NOT NULL,
        [OriginDocID] [int] NOT NULL,
        [OriginDocSubID] [int] NOT NULL,
        [DerivedDocType] [int] NOT NULL,
        [DerivedDocID] [int] NOT NULL,
        [DerivedDocSubID] [int] NOT NULL,
        [Manual] [char](1) NULL,
        [TBCreated] [datetime] NOT NULL,
        [TBModified] [datetime] NOT NULL,
        [TBCreatedID] [int] NOT NULL,
        [TBModifiedID] [int] NOT NULL,
        [OriginDocLine] [smallint] NOT NULL,
        [DerivedDocLine] [smallint] NOT NULL,
        CONSTRAINT [PK_CrossReferences$suffix] PRIMARY KEY NONCLUSTERED 
        (
            [OriginDocType] ASC,
            [OriginDocID] ASC,
            [OriginDocSubID] ASC,
            [OriginDocLine] ASC,
            [DerivedDocType] ASC,
            [DerivedDocID] ASC,
            [DerivedDocSubID] ASC,
            [DerivedDocLine] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    )
"@
    
    $createTableSQL = $createTableSQL.Replace('$suffix', $suffix)
    return $createTableSQL
}

# Per ogni database di origine
foreach ($sourceDB in $databases) {
    Write-Host "Processando il database: $sourceDB"
    
    # Determina il suffisso per la tabella di destinazione
    $suffix = switch ($sourceDB) {
        "vedbondifeclone" { "Bondife" }
        "furmanetclone" { "Furma" }
        "gpxnetclone" { "Gpx" }
    }
    
    try {
        # Crea la connessione SQL
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server=$ServerInstance;Database=$destDB;User Id=$SqlUsername;Password=$SqlPassword;"
        $conn.Open()
        
        # Drop e ricrea la tabella di destinazione
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.Connection = $conn
        $cmd.CommandText = Create-DestinationTable $suffix
        $cmd.ExecuteNonQuery()
        Write-Host "Tabella MA_CrossReferences$suffix eliminata e ricreata"
        
        # Copia i dati
        $copySQL = @"
        INSERT INTO [$destDB].[dbo].[MA_CrossReferences$suffix]
        SELECT * FROM [$sourceDB].[dbo].[MA_CrossReferences]
"@
        
        $cmd.CommandText = $copySQL
        $rowsCopied = $cmd.ExecuteNonQuery()
        Write-Host "Copiati $rowsCopied record nella tabella MA_CrossReferences$suffix"
        
    }
    catch {
        Write-Error "Errore durante l'elaborazione di $sourceDB : $_"
    }
    finally {
        if ($conn -and $conn.State -eq 'Open') {
            $conn.Close()
        }
    }
}

Write-Host "Operazione completata!"