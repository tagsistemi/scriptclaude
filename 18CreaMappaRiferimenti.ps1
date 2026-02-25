# ============================================
# SCRIPT 18: Creazione Mappa DocumentTypes COMPLETA
# ============================================
# Versione: 2.0
# Descrizione: Crea la tabella TAG_DocumentTypesCr con TUTTI i tipi documento
#              Mappa EnumValue (TAG_CrMaps.DocumentType) -> ReferenceCode (MA_CrossReferences.DocType)
#
# NOTA: Per i documenti di ACQUISTO si usano EnumValue 98304xx
#       (valore effettivo della colonna MA_PurchaseDoc.DocumentType, salvato da script 05)
#       Per tutti gli altri si usa la Specie Archivio 3801xxx
# ============================================

# Parametri di connessione
$ServerInstance = "192.168.0.3\sql2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

# Database da processare
$databases = @("vedbondifeclone", "furmanetclone", "gpxnetclone")

function Execute-SqlQuery {
   param (
       [string]$server,
       [string]$database,
       [string]$query,
       [string]$username,
       [string]$password
   )

   $connectionString = "Server=$server;Database=$database;User ID=$username;Password=$password;"
   $connection = New-Object System.Data.SqlClient.SqlConnection
   $connection.ConnectionString = $connectionString

   $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
   $command.CommandTimeout = 300

   try {
       $connection.Open()
       $command.ExecuteNonQuery()
       Write-Host "Query executed successfully on database $database" -ForegroundColor Green
   }
   catch {
       Write-Error "Error executing query on database $database : $_"
       throw $_
   }
   finally {
       if ($connection.State -eq [System.Data.ConnectionState]::Open) {
           $connection.Close()
       }
   }
}

$createTableQuery = @"
-- Ricrea la tabella con PK per evitare duplicati
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAG_DocumentTypesCr]') AND type in (N'U'))
    DROP TABLE [dbo].[TAG_DocumentTypesCr];

CREATE TABLE [dbo].[TAG_DocumentTypesCr] (
    [Description] [nvarchar](100) NULL,
    [EnumValue] [int] NOT NULL,
    [ReferenceCode] [int] NOT NULL,
    PRIMARY KEY (EnumValue)
)

-- =====================================================================
-- DOCUMENTI DI ACQUISTO (EnumValue = MA_PurchaseDoc.DocumentType 98304xx)
-- Compatibile con script 05RinumeraIdAcquisti che salva il DocumentType
-- reale dalla colonna MA_PurchaseDoc.DocumentType in TAG_CrMaps
-- =====================================================================
INSERT INTO [dbo].[TAG_DocumentTypesCr] ([Description], [EnumValue], [ReferenceCode]) VALUES
    (N'Bolla di Carico', 9830400, 27066400),
    (N'Fattura di Acquisto', 9830401, 27066402),
    (N'Nota di Credito Ricevuta', 9830402, 27066404),
    (N'Fattura di Acquisto a Correzione', 9830403, 27066403),
    (N'Bolla di Carico per Lavorazione Esterna', 9830404, 27066401),
    (N'Fattura di Acquisto di Acconto', 9830405, 27066406),
    (N'Nota di Debito Acquisto', 9830406, 27066405),
    (N'Fattura di Acquisto di Annullamento', 9830407, 27066464);

-- =====================================================================
-- TUTTI GLI ALTRI TIPI DOCUMENTO (EnumValue = Specie Archivio 3801xxx)
-- Compatibile con gli script rinumera 06-15, 27 che salvano la Specie
-- Archivio come DocumentType in TAG_CrMaps
-- =====================================================================
INSERT INTO [dbo].[TAG_DocumentTypesCr] ([Description], [EnumValue], [ReferenceCode]) VALUES
    -- Magazzino
    (N'Missione di Magazzino', 3801092, 27066369),
    (N'Movimento Magazzino', 3801093, 27066370),

    -- Offerte e Ordini
    (N'Offerta Cliente', 3801099, 27066371),
    (N'Ordine Cliente', 3801098, 27066372),
    (N'Offerta Fornitore', 3801109, 27066373),
    (N'Ordine Fornitore', 3801100, 27066374),

    -- WMS PreShipping
    (N'PreShipping per Consegna', 3801081, 27066375),
    (N'PreShipping per Resi', 3801082, 27066376),
    (N'PreShipping per Trasferimento tra Depositi', 3801083, 27066377),
    (N'Ricevimento Merci per Consegna', 3801084, 27066378),
    (N'Ricevimento Merci per Resi', 3801085, 27066379),
    (N'Ricevimento Merci per Trasferimento tra Depositi', 3801086, 27066380),

    -- Resi
    (N'Reso a fornitore', 3801087, 27066381),
    (N'Reso da Cliente', 3801089, 27066382),

    -- DDT e Documenti di Trasporto
    (N'Documento di Trasporto', 3801088, 27066383),
    (N'DDT al Fornitore per Lavorazione Esterna', 3801090, 27066384),

    -- Fatture Vendita
    (N'Fattura Accompagnatoria', 3801091, 27066385),
    (N'Fattura Accompagnatoria a Correzione', 3801094, 27066386),
    (N'Fattura Immediata', 3801095, 27066387),
    (N'Fattura a Correzione', 3801096, 27066388),
    (N'Nota di Credito', 3801097, 27066389),
    (N'Nota di Debito', 3801101, 27066390),
    (N'Fattura di Acconto', 3801102, 27066396),
    (N'Fattura ProForma', 3801103, 27066397),

    -- Ricevute Fiscali
    (N'Ricevuta Fiscale', 3801104, 27066391),
    (N'Ricevuta Fiscale a Correzione', 3801105, 27066392),
    (N'Ricevuta Fiscale Non Incassata', 3801106, 27066393),
    (N'Paragon', 3801107, 27066394),
    (N'Paragon a Correzione', 3801108, 27066395),

    -- Trasferimenti e Picking
    (N'Documento Trasferimento tra Depositi', 3801110, 27066398),
    (N'Picking List', 3801111, 27066399),

    -- Documenti Acquisto (Specie Archivio - non usati da script 05 ma utili per completezza)
    (N'Bolla di Carico (SA)', 3801112, 27066400),
    (N'Bolle di Carico da Fornitore per Lavorazione Esterna', 3801113, 27066401),
    (N'Fattura di Acquisto (SA)', 3801114, 27066402),
    (N'Fattura di Acquisto a Correzione (SA)', 3801115, 27066403),
    (N'Nota di Credito ricevuta (SA)', 3801116, 27066404),
    (N'Nota di Debito Acquisto (SA)', 3801117, 27066405),
    (N'Fattura di Acquisto di Acconto (SA)', 3801118, 27066406),

    -- WMS e Inventario
    (N'Inventario di WMS', 3801119, 27066407),
    (N'Ubicazione', 3801120, 27066408),

    -- Produzione e Collaudo
    (N'Ordine di Collaudo', 3801121, 27066409),
    (N'Bolla di Collaudo', 3801122, 27066410),
    (N'Ordine di Produzione', 3801123, 27066411),

    -- Altri documenti magazzino
    (N'Richiesta di Trasferimento', 3801124, 27066412),
    (N'Movimento Magazzino Scarti', 3801125, 27066413),
    (N'Movimento Magazzino Merci da ricevere', 3801126, 27066414),
    (N'RdA', 3801127, 27066415),
    (N'Bolla lavorazione', 3801128, 27066416),

    -- Contabilita
    (N'Oneri Accessori', 3801129, 27066417),
    (N'Documento Contabile Puro', 3801130, 27066418),
    (N'Documento Contabile Emesso', 3801131, 27066419),
    (N'Documento Contabile Ricevuto', 3801132, 27066420),
    (N'PreShipping per Lavorazioni Esterne', 3801133, 27066421),
    (N'Partita Fornitore', 3801134, 27066422),
    (N'Partita Cliente', 3801135, 27066423),
    (N'Movimento Analitico', 3801136, 27066424),
    (N'Parcella', 3801137, 27066425),

    -- Intrastat
    (N'Intracomunitario Acquisti', 3801138, 27066426),
    (N'Intracomunitario Cessioni', 3801139, 27066427),

    -- Cespiti e Previsionali
    (N'Movimento Cespiti', 3801140, 27066428),
    (N'Documento Contabile Puro Previsionale', 3801141, 27066429),
    (N'Documento Contabile da Emettere', 3801142, 27066430),
    (N'Documento Contabile da Ricevere', 3801143, 27066431),

    -- Retail e WMS avanzato
    (N'Documento Rivalutazione Retail', 3801144, 27066432),
    (N'Ricevimento Merci per Movimentazione tra Depositi', 3801145, 27066433),
    (N'PreShipping da Deposito c/Terzi', 3801146, 27066434),
    (N'Ricevimento Merci in Deposito c/Terzi', 3801147, 27066435),

    -- Agenti e Distinta Base
    (N'Movimenti Agenti', 3801148, 27066436),
    (N'Movimentazione Distinta Base', 3801149, 27066437),
    (N'Ordine al Fornitore per Lavorazione Esterna', 3801150, 27066438),
    (N'Ricevuta Fiscale Retail', 3801151, 27066439),

    -- WMS Inventario avanzato
    (N'Inventario WMS con assegnazione Ubicazioni', 3801152, 27066444),

    -- Tax e AutoFattura
    (N'Tax Settlement Sendings', 3801153, 27066449),
    (N'Tax Documents Sendings', 3801154, 27066450),
    (N'AutoFattura', 3801155, 27066468),
    (N'AutoNota di Credito', 3801156, 27066469),
    (N'Fattura di Acquisto di Annullamento (SA)', 3801157, 27066464),

    -- Richiesta Offerta e Commesse (IM)
    (N'Richiesta Offerta', 3801310, 27066668),
    (N'Analisi', 3801189, 27066671),
    (N'Commessa', 3801190, 27066672),
    (N'Commessa correlata', 3801191, 27066673),
    (N'Libretto delle Misure', 3801290, 27066676),
    (N'SAL', 3801291, 27066677),
    (N'Rapportino', 3801188, 27066678);
"@

# Main execution
Write-Host "Starting database processing..."

foreach ($database in $databases) {
   Write-Host "Processing database: $database" -ForegroundColor Yellow

   try {
       Execute-SqlQuery -server $ServerInstance -database $database -query $createTableQuery -username $SqlUsername -password $SqlPassword

       Write-Host "Successfully processed $database" -ForegroundColor Green
   }
   catch {
       Write-Host "Error processing $database : $_" -ForegroundColor Red
   }

   Write-Host "----------------------------------------"
}

# Crea anche su VEDMaster per riferimento
Write-Host "Processing database: VEDMaster" -ForegroundColor Yellow
try {
    Execute-SqlQuery -server $ServerInstance -database "VEDMaster" -query $createTableQuery -username $SqlUsername -password $SqlPassword
    Write-Host "Successfully processed VEDMaster" -ForegroundColor Green
}
catch {
    Write-Host "Error processing VEDMaster : $_" -ForegroundColor Red
}

Write-Host "----------------------------------------"
Write-Host "All databases processed."
Write-Host ""
Write-Host "Riepilogo: ~85 tipi documento (vs 19 della versione originale)" -ForegroundColor Cyan
Write-Host "  - 8 tipi Acquisto con EnumValue 98304xx (compatibilita script 05)" -ForegroundColor Gray
Write-Host "  - 7 tipi Acquisto con Specie Archivio 3801xxx (completezza)" -ForegroundColor Gray
Write-Host "  - ~70 tipi Vendita/Ordini/Commesse/Contabilita/WMS con 3801xxx" -ForegroundColor Gray
