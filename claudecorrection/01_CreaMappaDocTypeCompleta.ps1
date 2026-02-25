# ============================================
# SCRIPT: Creazione Mappa DocumentTypes Completa
# ============================================
# Versione: 1.0
# Data: 2025-01-29
# Descrizione: Crea la tabella TAG_DocumentTypesCr con TUTTI i tipi documento
#              Risolve l'anomalia della mappa incompleta nello script 18 originale
# ============================================

# Carica la configurazione
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\00_Config.ps1"

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  CREAZIONE MAPPA DOCUMENT TYPES COMPLETA" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Query per creare e popolare la tabella TAG_DocumentTypesCr
$createTableQuery = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAG_DocumentTypesCr]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[TAG_DocumentTypesCr] (
        [Description] [nvarchar](100) NULL,
        [EnumValue] [int] NOT NULL,
        [ReferenceCode] [int] NOT NULL,
        PRIMARY KEY (EnumValue)
    )
END
ELSE
BEGIN
    -- Svuota la tabella se esiste
    TRUNCATE TABLE [dbo].[TAG_DocumentTypesCr]
END

-- Inserimento di TUTTI i tipi documento
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

    -- Documenti Acquisto
    (N'Bolla di Carico', 3801112, 27066400),
    (N'Bolle di Carico da Fornitore per Lavorazione Esterna', 3801113, 27066401),
    (N'Fattura di Acquisto', 3801114, 27066402),
    (N'Fattura di Acquisto a Correzione', 3801115, 27066403),
    (N'Nota di Credito ricevuta', 3801116, 27066404),
    (N'Nota di Debito Acquisto', 3801117, 27066405),
    (N'Fattura di Acquisto di Acconto', 3801118, 27066406),

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
    (N'Fattura di Acquisto di Annullamento', 3801157, 27066464),
    (N'AutoFattura', 3801155, 27066468),
    (N'AutoNota di Credito', 3801156, 27066469),

    -- Richiesta Offerta e Commesse (IM)
    (N'Richiesta Offerta', 3801310, 27066668),
    (N'Analisi', 3801189, 27066671),
    (N'Commessa', 3801190, 27066672),
    (N'Commessa correlata', 3801191, 27066673),
    (N'Libretto delle Misure', 3801290, 27066676),
    (N'SAL', 3801291, 27066677),
    (N'Rapportino', 3801188, 27066678);
"@

# Esegui su ogni database clone
foreach ($db in $Global:CloneDatabases) {
    Write-ColorOutput "Processando database: $db" "Yellow"

    $result = Execute-SqlQuery -Query $createTableQuery -Database $db

    if ($result.Success) {
        # Verifica conteggio
        $count = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $db.dbo.TAG_DocumentTypesCr" -Database $db
        Write-ColorOutput "  TAG_DocumentTypesCr creata/aggiornata con $count tipi documento" "Green"
    }
    else {
        Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
    }
}

# Crea anche su VEDMaster per riferimento
Write-ColorOutput "Processando database: $Global:DestinationDB" "Yellow"
$result = Execute-SqlQuery -Query $createTableQuery -Database $Global:DestinationDB

if ($result.Success) {
    $count = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $Global:DestinationDB.dbo.TAG_DocumentTypesCr" -Database $Global:DestinationDB
    Write-ColorOutput "  TAG_DocumentTypesCr creata/aggiornata con $count tipi documento" "Green"
}
else {
    Write-ColorOutput "  ERRORE: $($result.Error)" "Red"
}

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  OPERAZIONE COMPLETATA" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Mostra riepilogo
Write-ColorOutput "RIEPILOGO TIPI DOCUMENTO INSERITI:" "White"
Write-ColorOutput "  - Magazzino: 2 tipi" "Gray"
Write-ColorOutput "  - Offerte/Ordini: 4 tipi" "Gray"
Write-ColorOutput "  - WMS PreShipping: 6 tipi" "Gray"
Write-ColorOutput "  - Resi: 2 tipi" "Gray"
Write-ColorOutput "  - DDT: 2 tipi" "Gray"
Write-ColorOutput "  - Fatture Vendita: 8 tipi" "Gray"
Write-ColorOutput "  - Ricevute Fiscali: 5 tipi" "Gray"
Write-ColorOutput "  - Trasferimenti/Picking: 2 tipi" "Gray"
Write-ColorOutput "  - Documenti Acquisto: 7 tipi" "Gray"
Write-ColorOutput "  - WMS/Inventario: 2 tipi" "Gray"
Write-ColorOutput "  - Produzione/Collaudo: 3 tipi" "Gray"
Write-ColorOutput "  - Altri Magazzino: 5 tipi" "Gray"
Write-ColorOutput "  - Contabilita: 9 tipi" "Gray"
Write-ColorOutput "  - Intrastat: 2 tipi" "Gray"
Write-ColorOutput "  - Cespiti/Previsionali: 4 tipi" "Gray"
Write-ColorOutput "  - Retail/WMS avanzato: 4 tipi" "Gray"
Write-ColorOutput "  - Agenti/DB: 4 tipi" "Gray"
Write-ColorOutput "  - Tax/AutoFattura: 5 tipi" "Gray"
Write-ColorOutput "  - Commesse (IM): 7 tipi" "Gray"
Write-Host ""
Write-ColorOutput "TOTALE: ~77 tipi documento (vs 17 dello script originale)" "Green"
