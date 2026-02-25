# ============================================
# CONFIGURAZIONE CENTRALIZZATA MIGRAZIONE VED
# ============================================
# Versione: 1.0
# Data: 2025-01-29
# Descrizione: Configurazione unificata per tutti gli script di correzione
# ============================================

# Parametri di connessione SQL Server
$Global:ServerInstance = "192.168.0.3\SQL2008"
$Global:SqlUsername = "sa"
$Global:SqlPassword = "stream"

# Database di destinazione
$Global:DestinationDB = "VEDMaster"

# Database sorgenti con OFFSET CONSISTENTI
# IMPORTANTE: Questi offset devono essere usati da TUTTI gli script
$Global:DatabaseOffsets = @{
    "vedcontab"       = 0        # Database base - nessun offset
    "gpxnetclone"     = 100000   # Offset per GPX
    "furmanetclone"   = 200000   # Offset per Furmanite
    "vedbondifeclone" = 300000   # Offset per VED Bondife
}

# Database clone da processare (esclude vedcontab che e' la base)
$Global:CloneDatabases = @("gpxnetclone", "furmanetclone", "vedbondifeclone")

# Tutti i database sorgente (incluso vedcontab)
$Global:AllSourceDatabases = @("vedcontab", "gpxnetclone", "furmanetclone", "vedbondifeclone")

# Stringa di connessione base
$Global:ConnectionString = "Server=$Global:ServerInstance;Database=master;User ID=$Global:SqlUsername;Password=$Global:SqlPassword;TrustServerCertificate=True;"

# ============================================
# MAPPA COMPLETA DEI DOCUMENT TYPES
# ============================================
# Formato: EnumValue (tipo tabella) -> ReferenceCode (tipo cross-reference)

$Global:DocumentTypeMap = @{
    # Magazzino
    3801092 = 27066369   # Missione di Magazzino
    3801093 = 27066370   # Movimento Magazzino

    # Offerte e Ordini
    3801099 = 27066371   # Offerta Cliente
    3801098 = 27066372   # Ordine Cliente
    3801109 = 27066373   # Offerta Fornitore
    3801100 = 27066374   # Ordine Fornitore

    # WMS PreShipping
    3801081 = 27066375   # PreShipping per Consegna
    3801082 = 27066376   # PreShipping per Resi
    3801083 = 27066377   # PreShipping per Trasferimento tra Depositi
    3801084 = 27066378   # Ricevimento Merci per Consegna
    3801085 = 27066379   # Ricevimento Merci per Resi
    3801086 = 27066380   # Ricevimento Merci per Trasferimento tra Depositi

    # Resi
    3801087 = 27066381   # Reso a fornitore
    3801089 = 27066382   # Reso da Cliente

    # DDT e Documenti di Trasporto
    3801088 = 27066383   # Documento di Trasporto (DDT)
    3801090 = 27066384   # DDT al Fornitore per Lavorazione Esterna

    # Fatture Vendita
    3801091 = 27066385   # Fattura Accompagnatoria
    3801094 = 27066386   # Fattura Accompagnatoria a Correzione
    3801095 = 27066387   # Fattura Immediata
    3801096 = 27066388   # Fattura a Correzione
    3801097 = 27066389   # Nota di Credito
    3801101 = 27066390   # Nota di Debito
    3801102 = 27066396   # Fattura di Acconto
    3801103 = 27066397   # Fattura ProForma

    # Ricevute Fiscali e Retail
    3801104 = 27066391   # Ricevuta Fiscale
    3801105 = 27066392   # Ricevuta Fiscale a Correzione
    3801106 = 27066393   # Ricevuta Fiscale Non Incassata
    3801107 = 27066394   # Paragon
    3801108 = 27066395   # Paragon a Correzione

    # Trasferimenti e Picking
    3801110 = 27066398   # Documento Trasferimento tra Depositi
    3801111 = 27066399   # Picking List

    # Documenti Acquisto
    3801112 = 27066400   # Bolla di Carico
    3801113 = 27066401   # Bolle di Carico da Fornitore per Lavorazione Esterna
    3801114 = 27066402   # Fattura di Acquisto
    3801115 = 27066403   # Fattura di Acquisto a Correzione
    3801116 = 27066404   # Nota di Credito ricevuta
    3801117 = 27066405   # Nota di Debito Acquisto
    3801118 = 27066406   # Fattura di Acquisto di Acconto

    # WMS e Inventario
    3801119 = 27066407   # Inventario di WMS
    3801120 = 27066408   # Ubicazione

    # Produzione e Collaudo
    3801121 = 27066409   # Ordine di Collaudo
    3801122 = 27066410   # Bolla di Collaudo
    3801123 = 27066411   # Ordine di Produzione

    # Altri documenti magazzino
    3801124 = 27066412   # Richiesta di Trasferimento
    3801125 = 27066413   # Movimento Magazzino Scarti
    3801126 = 27066414   # Movimento Magazzino Merci da ricevere
    3801127 = 27066415   # RdA (Richiesta di Acquisto)
    3801128 = 27066416   # Bolla lavorazione

    # Contabilita
    3801129 = 27066417   # Oneri Accessori
    3801130 = 27066418   # Documento Contabile Puro
    3801131 = 27066419   # Documento Contabile Emesso
    3801132 = 27066420   # Documento Contabile Ricevuto
    3801133 = 27066421   # PreShipping per Lavorazioni Esterne
    3801134 = 27066422   # Partita Fornitore
    3801135 = 27066423   # Partita Cliente
    3801136 = 27066424   # Movimento Analitico
    3801137 = 27066425   # Parcella

    # Intrastat
    3801138 = 27066426   # Intracomunitario Acquisti
    3801139 = 27066427   # Intracomunitario Cessioni

    # Cespiti e Previsionali
    3801140 = 27066428   # Movimento Cespiti
    3801141 = 27066429   # Documento Contabile Puro Previsionale
    3801142 = 27066430   # Documento Contabile da Emettere
    3801143 = 27066431   # Documento Contabile da Ricevere

    # Retail e WMS avanzato
    3801144 = 27066432   # Documento Rivalutazione Retail
    3801145 = 27066433   # Ricevimento Merci per Movimentazione tra Depositi
    3801146 = 27066434   # PreShipping da Deposito c/Terzi
    3801147 = 27066435   # Ricevimento Merci in Deposito c/Terzi

    # Agenti e Distinta Base
    3801148 = 27066436   # Movimenti Agenti
    3801149 = 27066437   # Movimentazione Distinta Base
    3801150 = 27066438   # Ordine al Fornitore per Lavorazione Esterna
    3801151 = 27066439   # Ricevuta Fiscale Retail

    # WMS Inventario avanzato
    3801152 = 27066444   # Inventario WMS con assegnazione Ubicazioni

    # Tax e AutoFattura
    3801153 = 27066449   # Tax Settlement Sendings
    3801154 = 27066450   # Tax Documents Sendings
    3801155 = 27066468   # AutoFattura
    3801156 = 27066469   # AutoNota di Credito

    # Richiesta Offerta e Commesse (IM)
    3801310 = 27066668   # Richiesta Offerta
    3801189 = 27066671   # Analisi (JobQuotation)
    3801290 = 27066676   # Libretto delle Misure
    3801291 = 27066677   # SAL
    3801188 = 27066678   # Rapportino

    # Commesse (Jobs)
    3801190 = 27066672   # Commessa (Job)
    3801191 = 27066673   # Commessa correlata
}

# DocTypes per fatture (tutti i tipi)
$Global:InvoiceDocTypes = @(
    27066385,  # Fattura Accompagnatoria
    27066386,  # Fattura Accompagnatoria a Correzione
    27066387,  # Fattura Immediata
    27066388,  # Fattura a Correzione
    27066389,  # Nota di Credito
    27066390,  # Nota di Debito
    27066396,  # Fattura di Acconto
    27066402,  # Fattura di Acquisto
    27066403,  # Fattura di Acquisto a Correzione
    27066404,  # Nota di Credito ricevuta
    27066405,  # Nota di Debito Acquisto
    27066406   # Fattura di Acquisto di Acconto
)

# DocTypes per DDT
$Global:DDTDocTypes = @(
    27066383,  # Documento di Trasporto (DDT)
    27066384,  # DDT al Fornitore per Lavorazione Esterna
    27066400,  # Bolla di Carico
    27066401,  # Bolle di Carico da Fornitore per Lavorazione Esterna
    27066416   # Bolla lavorazione
)

# DocTypes per Ordini
$Global:OrderDocTypes = @(
    27066371,  # Offerta Cliente
    27066372,  # Ordine Cliente
    27066373,  # Offerta Fornitore
    27066374,  # Ordine Fornitore
    27066415,  # RdA
    27066438   # Ordine al Fornitore per Lavorazione Esterna
)

# DocTypes per Commesse
$Global:JobDocTypes = @(
    27066672,  # Commessa (Job)
    27066673,  # Commessa correlata
    27066671,  # Analisi
    27066676,  # Libretto delle Misure
    27066677,  # SAL
    27066678   # Rapportino
)

# ============================================
# FUNZIONI HELPER COMUNI
# ============================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Execute-SqlQuery {
    param (
        [string]$Query,
        [string]$Database = "master",
        [int]$Timeout = 300
    )

    $connString = "Server=$Global:ServerInstance;Database=$Database;User ID=$Global:SqlUsername;Password=$Global:SqlPassword;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connString)
    $command = New-Object System.Data.SqlClient.SqlCommand($Query, $connection)
    $command.CommandTimeout = $Timeout

    try {
        $connection.Open()
        $result = $command.ExecuteNonQuery()
        return @{ Success = $true; RowsAffected = $result }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

function Execute-SqlScalar {
    param (
        [string]$Query,
        [string]$Database = "master"
    )

    $connString = "Server=$Global:ServerInstance;Database=$Database;User ID=$Global:SqlUsername;Password=$Global:SqlPassword;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connString)
    $command = New-Object System.Data.SqlClient.SqlCommand($Query, $connection)
    $command.CommandTimeout = 300

    try {
        $connection.Open()
        $result = $command.ExecuteScalar()
        return $result
    }
    catch {
        Write-ColorOutput "Errore query: $($_.Exception.Message)" "Red"
        return $null
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

function Execute-SqlReader {
    param (
        [string]$Query,
        [string]$Database = "master"
    )

    $connString = "Server=$Global:ServerInstance;Database=$Database;User ID=$Global:SqlUsername;Password=$Global:SqlPassword;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connString)
    $command = New-Object System.Data.SqlClient.SqlCommand($Query, $connection)
    $command.CommandTimeout = 300

    try {
        $connection.Open()
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataTable = New-Object System.Data.DataTable
        $adapter.Fill($dataTable) | Out-Null
        return $dataTable
    }
    catch {
        Write-ColorOutput "Errore query: $($_.Exception.Message)" "Red"
        return $null
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

function Test-TableExists {
    param(
        [string]$Database,
        [string]$TableName
    )

    $query = "SELECT COUNT(*) FROM $Database.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$TableName' AND TABLE_SCHEMA = 'dbo';"
    $result = Execute-SqlScalar -Query $query
    return ($result -gt 0)
}

function Get-DatabaseOffset {
    param([string]$DatabaseName)

    if ($Global:DatabaseOffsets.ContainsKey($DatabaseName)) {
        return $Global:DatabaseOffsets[$DatabaseName]
    }
    return 0
}

Write-ColorOutput "Configurazione caricata correttamente." "Green"
Write-ColorOutput "Server: $Global:ServerInstance" "Gray"
Write-ColorOutput "Destinazione: $Global:DestinationDB" "Gray"
Write-ColorOutput "Database sorgenti: $($Global:AllSourceDatabases -join ', ')" "Gray"
