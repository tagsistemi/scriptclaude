# Impostazioni di connessione al database
$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"
$DestinationDB = "VEDMaster"
$SourceDBs = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Costruisce la stringa di connessione
$ConnectionString = "Server=$ServerInstance;Database=master;User ID=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True;"

# Tabelle da migrare (in ordine logico, se ci sono dipendenze)
$TablesToMigrate = @(
    "MA_PurchaseDoc",
    "MA_PurchaseDocDetail",
    "MA_PurchaseDocNotes",
    "MA_PurchaseDocPymtSched",
    "MA_PurchaseDocReferences",
    "MA_PurchaseDocShipping",
    "MA_PurchaseDocSummary",
    "MA_PurchaseDocTaxSummary"
)

# --- FUNZIONI HELPER ---

# Funzione per ottenere l'elenco delle colonne per una data tabella in un dato DB
function Get-TableColumns {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    
    $query = "SELECT COLUMN_NAME FROM $($Database).INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TableName' ORDER BY ORDINAL_POSITION;"
    try {
        $columns = Invoke-Sqlcmd -Query $query -ConnectionString $ConnString -ErrorAction Stop
        return $columns.COLUMN_NAME
    }
    catch {
        Write-Error "Impossibile recuperare le colonne per la tabella '$TableName' dal database '$Database'. Errore: $_"
        return $null
    }
}

# Funzione per ottenere la chiave primaria di una tabella
function Get-TablePrimaryKey {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$ConnString
    )
    $pkQuery = @"
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
    try {
        $pkColumns = Invoke-Sqlcmd -Query $pkQuery -ConnectionString $ConnString -ErrorAction Stop
        return $pkColumns.COLUMN_NAME
    }
    catch {
        Write-Warning "Impossibile determinare la chiave primaria per '$TableName' in '$Database'. La migrazione per questa tabella potrebbe non prevenire i duplicati. Errore: $_"
        return $null
    }
}

# Funzione per ottenere tutte le foreign key per le tabelle specificate
function Get-AllForeignKeyConstraints {
    param(
        [string]$Database,
        [array]$TableNames,
        [string]$ConnString
    )
    $tableListForQuery = $TableNames | ForEach-Object { "'$_'" } | Join-String -Separator ", "
    $fkQuery = @"
SELECT 
    '[' + s.name + '].[' + t.name + ']' AS TableName,
    fk.name AS ConstraintName
FROM $($Database).sys.foreign_keys AS fk
INNER JOIN $($Database).sys.tables AS t ON fk.parent_object_id = t.object_id
INNER JOIN $($Database).sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.name IN ($tableListForQuery)
"@
    try {
        return Invoke-Sqlcmd -Query $fkQuery -ConnectionString $ConnString -ErrorAction Stop
    }
    catch {
        Write-Error "Impossibile recuperare le foreign key per il database '$Database'. Errore: $_"
        return $null
    }
}

# Funzione per abilitare o disabilitare le foreign key
function Set-ForeignKeyState {
    param(
        [string]$Database,
        [object[]]$Constraints,
        [ValidateSet('NOCHECK', 'CHECK')][string]$State,
        [string]$ConnString
    )
    Write-Host "Impostazione stato Foreign Keys a '$State' per $($Constraints.Count) vincoli..." -ForegroundColor Yellow
    foreach ($constraint in $Constraints) {
        $alterQuery = "ALTER TABLE $($Database).$($constraint.TableName) $State CONSTRAINT [$($constraint.ConstraintName)];"
        try {
            Invoke-Sqlcmd -Query $alterQuery -ConnectionString $ConnString -ErrorAction Stop
        }
        catch {
            Write-Error "Impossibile modificare lo stato del vincolo '$($constraint.ConstraintName)' sulla tabella '$($constraint.TableName)'. Errore: $_"
        }
    }
    Write-Host "Stato Foreign Keys impostato correttamente." -ForegroundColor Green
}


# --- INIZIO SCRIPT DI MIGRAZIONE ---

Write-Host "AVVIO PROCESSO DI MIGRAZIONE DATI" -ForegroundColor Cyan
Write-Host "======================================="

# Ottieni tutte le FK prima di iniziare
$allConstraints = Get-AllForeignKeyConstraints -Database $DestinationDB -TableNames $TablesToMigrate -ConnString $ConnectionString

if (-not $allConstraints) {
    Write-Warning "Nessun vincolo di Foreign Key trovato o errore nel recupero. La procedura continuerà, ma lo svuotamento potrebbe fallire."
}

try {
    # 1. Disabilita le FK
    if ($allConstraints) {
        Set-ForeignKeyState -Database $DestinationDB -Constraints $allConstraints -State 'NOCHECK' -ConnString $ConnectionString
    }

    # 2. Svuota le tabelle di destinazione
    Write-Host "1. Svuotamento delle tabelle di destinazione in '$DestinationDB'..." -ForegroundColor Yellow
    # Si usa DELETE invece di TRUNCATE perché TRUNCATE può essere bloccato da FK anche se sono disabilitate.
    # L'ordine inverso è una best practice per rispettare le dipendenze logiche durante la cancellazione.
    foreach ($table in ($TablesToMigrate | Sort-Object -Descending)) {
        try {
            Write-Host "   - Svuotamento di '$table'..."
            $deleteQuery = "DELETE FROM $($DestinationDB).dbo.$($table);"
            Invoke-Sqlcmd -Query $deleteQuery -ConnectionString $ConnectionString -ErrorAction Stop
        }
        catch {
            Write-Error "ATTENZIONE: Impossibile svuotare la tabella '$table' in '$DestinationDB'. Errore: $_"
        }
    }
    Write-Host "Svuotamento completato." -ForegroundColor Green


    # 3. Cicla su ogni tabella da migrare
    foreach ($table in $TablesToMigrate) {
        Write-Host "------------------------------------------------------------"
        Write-Host "Inizio migrazione per la tabella: '$table'" -ForegroundColor Cyan
        
        # Ottieni lo schema della tabella di destinazione una sola volta
        $destinationColumns = Get-TableColumns -Database $DestinationDB -TableName $table -ConnString $ConnectionString
        if (-not $destinationColumns) {
            Write-Error "Impossibile procedere con la tabella '$table' perché non è stato possibile leggerne lo schema da '$DestinationDB'."
            continue
        }
        
        # Ottieni la chiave primaria della tabella di destinazione
        $primaryKeyColumns = Get-TablePrimaryKey -Database $DestinationDB -TableName $table -ConnString $ConnectionString

        # 4. Cicla su ogni database sorgente
        foreach ($sourceDb in $SourceDBs) {
            Write-Host "  -> Migrazione da '$sourceDb' a '$DestinationDB'..." -ForegroundColor White
            
            # Ottieni lo schema della tabella sorgente
            $sourceColumns = Get-TableColumns -Database $sourceDb -TableName $table -ConnString $ConnectionString
            if (-not $sourceColumns) {
                Write-Warning "La tabella '$table' non esiste nel database sorgente '$sourceDb'. Salto."
                continue
            }
            
            # Metodo più robusto per trovare le colonne comuni.
            # Converte esplicitamente in array di stringhe e usa un HashSet per l'intersezione.
            $destinationColumnsHashSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$destinationColumns, [System.StringComparer]::InvariantCultureIgnoreCase)
            $destinationColumnsHashSet.IntersectWith([string[]]$sourceColumns)
            
            # Correzione: Se il risultato è una collezione, la converte in array.
            # Se è già un singolo oggetto (stringa), lo mette dentro un array.
            # Questo gestisce il caso in cui rimane una sola colonna in comune.
            $commonColumns = @($destinationColumnsHashSet)

            if ($commonColumns.Count -eq 0) {
                Write-Warning "Nessuna colonna in comune trovata tra '$sourceDb' e '$DestinationDB' per la tabella '$table'. Salto."
                continue
            }
            
            # Costruisce dinamicamente la lista di colonne per la query
            $columnListForSelect = $commonColumns | ForEach-Object { "S.[$_]" } | Join-String -Separator ", "
            $columnListForInsert = $commonColumns | ForEach-Object { "[$_]" } | Join-String -Separator ", "
            
            # Costruisce la query di INSERT
            $migrationQuery = "INSERT INTO $($DestinationDB).dbo.$($table) ($columnListForInsert) SELECT $columnListForSelect FROM $($sourceDb).dbo.$($table) AS S"
            
            # Aggiungi la clausola NOT EXISTS se abbiamo trovato una chiave primaria
            if ($primaryKeyColumns) {
                $joinConditions = $primaryKeyColumns | ForEach-Object { "D.[$_] = S.[$_]" } | Join-String -Separator " AND "
                if ($joinConditions) {
                    $migrationQuery += " WHERE NOT EXISTS (SELECT 1 FROM $($DestinationDB).dbo.$($table) AS D WHERE $joinConditions)"
                }
            }
            
            $migrationQuery += ";"

            # Esegui la migrazione per la tabella e il DB corrente
            try {
                Write-Host "     Esecuzione della query di migrazione per '$table' da '$sourceDb'..."
                Invoke-Sqlcmd -Query $migrationQuery -ConnectionString $ConnectionString -ErrorAction Stop
                Write-Host "     Migrazione completata con successo." -ForegroundColor Green
            }
            catch {
                Write-Error "ERRORE CRITICO durante la migrazione della tabella '$table' da '$sourceDb'. Dettagli: $_"
                # Potresti voler interrompere lo script qui a seconda della gravità
                # exit 1
            }
        }
    }
}
finally {
    # 5. Riabilita le FK in ogni caso (anche se lo script fallisce)
    if ($allConstraints) {
        Write-Host "======================================="
        Write-Host "Riabilitazione delle Foreign Keys..." -ForegroundColor Yellow
        Set-ForeignKeyState -Database $DestinationDB -Constraints $allConstraints -State 'CHECK' -ConnString $ConnectionString
    }
}

# --- INIZIO SEZIONE DI VERIFICA ---
Write-Host "======================================="
Write-Host "AVVIO VERIFICA FINALE CONTEGGIO RECORD" -ForegroundColor Cyan
Write-Host "======================================="

foreach ($table in $TablesToMigrate) {
    try {
        # Conteggio record nella destinazione
        $destCountQuery = "SELECT COUNT(*) AS RecordCount FROM $($DestinationDB).dbo.$($table);"
        $destResult = Invoke-Sqlcmd -Query $destCountQuery -ConnectionString $ConnectionString -ErrorAction Stop
        $destCount = $destResult.RecordCount

        # Conteggio record nei sorgenti
        $totalSourceCount = 0
        foreach ($sourceDb in $SourceDBs) {
            # Verifica se la tabella esiste nel sorgente prima di contare
            $checkTableExistsQuery = "SELECT COUNT(*) FROM $($sourceDb).INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$table';"
            $tableExistsResult = Invoke-Sqlcmd -Query $checkTableExistsQuery -ConnectionString $ConnectionString
            if ($tableExistsResult.Item(0) -gt 0) {
                $sourceCountQuery = "SELECT COUNT(*) AS RecordCount FROM $($sourceDb).dbo.$($table);"
                $sourceResult = Invoke-Sqlcmd -Query $sourceCountQuery -ConnectionString $ConnectionString -ErrorAction Stop
                $totalSourceCount += $sourceResult.RecordCount
            }
        }

        # Confronto e output
        Write-Host "Verifica per la tabella '$table':" -ForegroundColor White
        Write-Host "  - Record totali nei sorgenti: $totalSourceCount"
        Write-Host "  - Record migrati in '$DestinationDB': $destCount"
        
        if ($destCount -lt $totalSourceCount -and $destCount -eq 0 -and $totalSourceCount -gt 0) {
             Write-Host "  -> ESITO: ERRORE! Nessun record migrato nonostante ci siano dati sorgente." -ForegroundColor Red
        }
        elseif ($destCount -lt $totalSourceCount) {
            Write-Host "  -> ESITO: AVVISO. Il numero di record migrati è inferiore a quello dei sorgenti (possibile rimozione duplicati)." -ForegroundColor Yellow
        }
        else {
            Write-Host "  -> ESITO: SUCCESSO. Il conteggio dei record è consistente." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Errore durante la fase di verifica per la tabella '$table'. Dettagli: $_"
    }
}


Write-Host "======================================="
Write-Host "PROCESSO DI MIGRAZIONE COMPLETATO." -ForegroundColor Cyan
