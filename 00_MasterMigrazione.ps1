# ============================================
# MASTER SCRIPT MIGRAZIONE VED
# ============================================
# Scopo: Orchestrare l'esecuzione completa della migrazione
#        da gpxnetclone, furmanetclone, vedbondifeclone verso VEDMaster
#
# Uso: .\00_MasterMigrazione.ps1 [-Fase <numero>] [-DaFase <numero>] [-AFase <numero>]
#
# Esempi:
#   .\00_MasterMigrazione.ps1                    # Esegue tutto (con conferma per ogni fase)
#   .\00_MasterMigrazione.ps1 -Fase 3            # Esegue solo Fase 3
#   .\00_MasterMigrazione.ps1 -DaFase 4 -AFase 8 # Esegue da Fase 4 a Fase 8
# ============================================

param(
    [int]$Fase = 0,         # Esegue solo una fase specifica
    [int]$DaFase = 1,       # Fase di partenza (default: 1)
    [int]$AFase = 10        # Fase finale (default: 10)
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

# Se specificata una fase singola, imposta DaFase e AFase
if ($Fase -gt 0) {
    $DaFase = $Fase
    $AFase = $Fase
}

# ============================================
# FUNZIONI DI UTILITA
# ============================================

function Write-Header {
    param([string]$Text)
    $separator = "=" * 70
    Write-Host ""
    Write-Host $separator -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $separator -ForegroundColor Cyan
    Write-Host ""
}

function Write-SubHeader {
    param([string]$Text)
    Write-Host ""
    Write-Host "  --- $Text ---" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Step {
    param(
        [string]$StepId,
        [string]$Type,
        [string]$Description
    )
    $typeColor = switch ($Type) {
        "SCRIPT"  { "Green" }
        "SQL"     { "Magenta" }
        "MANUALE" { "Red" }
        default   { "White" }
    }
    Write-Host "  [$StepId] " -NoNewline -ForegroundColor White
    Write-Host "[$Type] " -NoNewline -ForegroundColor $typeColor
    Write-Host $Description -ForegroundColor White
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    OK: $Message" -ForegroundColor Green
}

function Write-Errore {
    param([string]$Message)
    Write-Host "    ERRORE: $Message" -ForegroundColor Red
}

function Write-Attenzione {
    param([string]$Message)
    Write-Host "    ATTENZIONE: $Message" -ForegroundColor Yellow
}

function Confirm-Continue {
    param([string]$Message = "Continuare?")
    Write-Host ""
    $risposta = Read-Host "  $Message (S/N)"
    if ($risposta -ne "S" -and $risposta -ne "s") {
        Write-Host "  Operazione interrotta dall'utente." -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Confirm-FaseStart {
    param(
        [int]$NumFase,
        [string]$NomeFase
    )
    Write-Host ""
    Write-Host "  Pronto per eseguire FASE $NumFase - $NomeFase" -ForegroundColor White
    return (Confirm-Continue "Avviare la FASE $NumFase?")
}

function Execute-Script {
    param(
        [string]$StepId,
        [string]$ScriptPath,
        [string]$Description
    )
    Write-Step -StepId $StepId -Type "SCRIPT" -Description "$Description"
    Write-Host "    File: $ScriptPath" -ForegroundColor Gray

    $fullPath = Join-Path $ScriptRoot $ScriptPath
    if (-not (Test-Path $fullPath)) {
        Write-Errore "File non trovato: $fullPath"
        if (-not (Confirm-Continue "Ignorare e continuare?")) { exit 1 }
        return
    }

    # Push-Location nella directory dello script per risolvere path relativi
    # (es. CreaMappaCommesseDuplicate.ps1 usa "commesse duplicate.CSV" come path relativo)
    $scriptDir = Split-Path $fullPath -Parent
    try {
        Push-Location $scriptDir
        & $fullPath
        Write-Ok "Completato"
    }
    catch {
        Write-Errore $_.Exception.Message
        if (-not (Confirm-Continue "Si e' verificato un errore. Continuare comunque?")) { exit 1 }
    }
    finally {
        Pop-Location
    }
}

function Execute-SqlFile {
    param(
        [string]$StepId,
        [string]$SqlFilePath,
        [string]$Description,
        [string]$Database = "VEDMaster"
    )
    Write-Step -StepId $StepId -Type "SQL" -Description "$Description"

    $fullPath = Join-Path $ScriptRoot $SqlFilePath
    if (-not (Test-Path $fullPath)) {
        Write-Errore "File SQL non trovato: $fullPath"
        if (-not (Confirm-Continue "Ignorare e continuare?")) { exit 1 }
        return
    }

    Write-Host "    File: $SqlFilePath" -ForegroundColor Gray
    Write-Host "    DB: $Database" -ForegroundColor Gray
    Write-Attenzione "Eseguire manualmente su SSMS collegati a $Database"
    Read-Host "    Premere INVIO dopo aver eseguito la query"
    Write-Ok "Confermato dall'utente"
}

function Execute-SqlInline {
    param(
        [string]$StepId,
        [string]$Description,
        [string]$SqlCode,
        [string]$Database = "VEDMaster"
    )
    Write-Step -StepId $StepId -Type "SQL" -Description "$Description"
    Write-Host "    DB: $Database" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    Query da eseguire su SSMS:" -ForegroundColor Magenta
    Write-Host ""
    foreach ($line in ($SqlCode -split "`n")) {
        Write-Host "      $line" -ForegroundColor DarkGray
    }
    Write-Host ""
    Read-Host "    Premere INVIO dopo aver eseguito la query"
    Write-Ok "Confermato dall'utente"
}

function Show-ManualStep {
    param(
        [string]$StepId,
        [string]$Description,
        [string[]]$Details
    )
    Write-Step -StepId $StepId -Type "MANUALE" -Description "$Description"
    foreach ($detail in $Details) {
        Write-Host "      - $detail" -ForegroundColor DarkYellow
    }
    Read-Host "    Premere INVIO dopo aver completato l'operazione manuale"
    Write-Ok "Confermato dall'utente"
}

# ============================================
# LOG
# ============================================
$logFile = Join-Path $ScriptRoot "log_master_migrazione_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logFile -Append

Write-Header "MASTER MIGRAZIONE VED"
Write-Host "  Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "  Esecuzione: Fase $DaFase -> Fase $AFase" -ForegroundColor Gray
Write-Host "  Script root: $ScriptRoot" -ForegroundColor Gray
Write-Host "  Log: $logFile" -ForegroundColor Gray

# ============================================
# FASE 1 - Clonazione database
# ============================================
if ($DaFase -le 1 -and $AFase -ge 1) {
    Write-Header "FASE 1 - Clonazione database"

    if (Confirm-FaseStart 1 "Clonazione database") {
        Execute-Script "1.1" "duplicadbvedcontab.ps1" "Clona vedcontab"
        Execute-Script "1.2" "duplicadbvedbondife.ps1" "Clona vedbondife"
        Execute-Script "1.3" "duplicadbfurmanet.ps1"   "Clona furmanet"
        Execute-Script "1.4" "duplicadbgpxnet.ps1"     "Clona gpxnet"

        Write-Ok "FASE 1 completata"
    }
}

# ============================================
# FASE 2 - Preparazione VEDMaster
# ============================================
if ($DaFase -le 2 -and $AFase -ge 2) {
    Write-Header "FASE 2 - Preparazione VEDMaster"

    if (Confirm-FaseStart 2 "Preparazione VEDMaster") {
        Execute-Script "2.1" "SvuotaVedmaster.ps1"          "Svuota VEDMaster"
        Execute-Script "2.2" "CreaMappaCommesseDuplicate.ps1" "Crea tabella MM4_MappaJobsCodes"

        Write-Ok "FASE 2 completata"
    }
}

# ============================================
# FASE 3 - Rinumerazione Job (sui DB clone)
# ============================================
if ($DaFase -le 3 -and $AFase -ge 3) {
    Write-Header "FASE 3 - Rinumerazione Job (sui DB clone)"
    Write-Host "  Aggiorna codici commessa nei DB clone per evitare collisioni" -ForegroundColor Gray
    Write-Host "  Offsets: gpx +100k, furma +200k, bondife +300k" -ForegroundColor Gray

    if (Confirm-FaseStart 3 "Rinumerazione Job") {
        Execute-Script "3.1" "01rinumerajobid.ps1"        "Rinumera IM_JobId/JobId (+100k/+200k/+300k)"
        Execute-Script "3.2" "02disableoldjobscodes.ps1"  "Disabilita vecchi codici Job (furma, bondife)"
        Execute-Script "3.3" "03replaceoldcodes.ps1"      "Aggiorna codici Job in 11 tabelle IM_Jobs*"
        Execute-Script "3.4" "04aggiornadocumenti.ps1"    "Aggiorna codici Job in 26 tabelle documento"

        Write-Ok "FASE 3 completata"
    }
}

# ============================================
# FASE 4 - Rinumerazione ID documenti (sui DB clone)
# ============================================
if ($DaFase -le 4 -and $AFase -ge 4) {
    Write-Header "FASE 4 - Rinumerazione ID documenti (sui DB clone)"
    Write-Host "  Ogni script rinumera un tipo di ID con offset diversi per database" -ForegroundColor Gray

    if (Confirm-FaseStart 4 "Rinumerazione ID documenti") {
        Execute-Script "4.1"  "05RinumeraIdAcquisti.ps1"          "Rinumera PurchaseDocId (gpx +100k, furma +200k, bondife +300k)"
        Execute-Script "4.2"  "06RinumeraIdOrdiniFornitori.ps1"   "Rinumera PurchaseOrdId (gpx +100k, furma +200k, bondife +300k)"
        Execute-Script "4.3"  "07RinumeraIdOfferteFornitori.ps1"  "Rinumera SuppQuotaId (gpx +100k, furma +200k, bondife +300k)"
        Execute-Script "4.4"  "08RinumeraIdOfferteClienti.ps1"    "Rinumera CustQuotaId (gpx +100k, furma +200k, bondife +300k)"
        Execute-Script "4.5"  "09RinumeraIdOrdiniClienti.ps1"     "Rinumera SaleOrdId (gpx ESCLUSO, furma +200k, bondife +300k)"
        Execute-Script "4.6"  "10RinumeraEntryId.ps1"             "Rinumera EntryId (gpx +1M, furma +500k, bondife +600k)"
        Execute-Script "4.7"  "11RinumeraImQuotations.ps1"        "Rinumera QuotationRequestId (gpx +400k, furma +500k, bondife +600k)"
        Execute-Script "4.8"  "12RinumeraImRapportini.ps1"        "Rinumera WorkingReportId (gpx +400k, furma +1M, bondife +600k)"
        Execute-Script "4.9"  "13RinumeraLibretti.ps1"            "Rinumera MeasuresBookId (gpx +100k, furma +200k, bondife +300k)"
        Execute-Script "4.10" "14RinumeraAnalisiPreventivo.ps1"   "Rinumera JobQuotationId (gpx +100k, furma +200k, bondife +300k)"
        Execute-Script "4.11" "15RinumeraSal.ps1"                 "Rinumera WPRId (gpx +100k, furma +200k, bondife +300k)"
        Execute-Script "4.12" "27rinumerasaledoc.ps1"             "Rinumera SaleDocId (gpx +400k, furma +200k, bondife +300k)"

        Write-Ok "FASE 4 completata"
    }
}

# ============================================
# FASE 5 - Cross-references (sui DB clone)
# ============================================
if ($DaFase -le 5 -and $AFase -ge 5) {
    Write-Header "FASE 5 - Cross-references (sui DB clone)"
    Write-Host "  Aggiorna i riferimenti incrociati nei DB clone per riflettere i nuovi ID" -ForegroundColor Gray

    if (Confirm-FaseStart 5 "Cross-references") {
        Execute-Script "5.1" "18CreaMappaRiferimenti.ps1"           "Crea TAG_DocumentTypesCr (~85 tipi documento)"
        Execute-Script "5.2" "19AggiornaCRossReference.ps1"         "Aggiorna OriginDocID/DerivedDocID in MA_CrossReferences e Notes"
        Execute-Script "5.3" "19BisRinumerasubid.ps1"               "Rinumera SubID (con WHERE > 0)"
        Execute-Script "5.4" "20AggCrossreferenceCommesse.ps1"      "Aggiorna CrossRef per commesse (offset numerici IM_JobId)"
        Execute-Script "5.5" "22PostTrasfUpdateCrossReference.ps1"  "Aggiorna CrossRef commesse duplicate (vecchiocodice -> nuovocodice)"
        Execute-Script "5.6" "21ExportCrossReference.ps1"           "Esporta CrossRef in MM4HelperDb"
        Execute-Script "5.7" "22Aggiornacausaliedeposuorigini.ps1"  "Aggiorna causali e depositi di origine"

        Write-Ok "FASE 5 completata"
    }
}

# ============================================
# FASE 6 - Creazione depositi e causali (MANUALE)
# ============================================
if ($DaFase -le 6 -and $AFase -ge 6) {
    Write-Header "FASE 6 - Creazione depositi e causali (MANUALE)"
    Write-Host "  ATTENZIONE: Questa fase richiede operazioni manuali su SSMS/Mago" -ForegroundColor Red

    if (Confirm-FaseStart 6 "Creazione depositi e causali") {

        Show-ManualStep "6.1" "Creare depositi su VEDMaster" @(
            "Creare deposito 01FRM su furmanetclone",
            "Creare deposito 01MPFRM su furmanetclone",
            "Creare deposito COLLBDF su vedbondifeclone",
            "Creare deposito SANNABDF su vedbondifeclone"
        )

        Show-ManualStep "6.2" "Creare causali su VEDMaster" @(
            "Creare causale MOV-DEPF su furmanetclone",
            "Creare causale ACQ-FRM su furmanetclone",
            "Creare causale MID-FRM su furmanetclone",
            "Creare causale MOV-LIBF su furmanetclone",
            "Creare causale Mud-FRM su furmanetclone",
            "Creare causale VEN-O-B su VEDBONDIFECLONE",
            "Creare causale MOV-DEPB su bondifeclone"
        )

        Write-Attenzione "Verificare che depositi e causali siano stati creati prima di proseguire"
        Write-Ok "FASE 6 completata"
    }
}

# ============================================
# FASE 7 - Preparazione VEDMaster (pre-trasferimento)
# ============================================
if ($DaFase -le 7 -and $AFase -ge 7) {
    Write-Header "FASE 7 - Preparazione VEDMaster (pre-trasferimento)"

    if (Confirm-FaseStart 7 "Preparazione VEDMaster pre-trasferimento") {

        # 7.0 - Rinumerazione SaleDocId su VEDMaster
        Write-SubHeader "7.0 - Rinumerazione SaleDocId su VEDMaster"
        Write-Host "  Rinumera SaleDocId su VEDMaster per allinearli ai clone" -ForegroundColor Gray
        Write-Host "  PREREQUISITO: Le fatture devono essere gia state importate da vedcontab" -ForegroundColor Yellow
        Write-Host "  CONSEGUENZA: Lo script 23 (post-trasf) non sara piu necessario" -ForegroundColor Yellow

        Execute-Script "7.0.1" "28RinumeraSaleDocVedmaster.ps1" "Rinumera SaleDocId su VEDMaster per allinearli ai clone"

        # 7.1 - Pulizia caratteri speciali
        Write-SubHeader "7.1 - Pulizia caratteri speciali"

        $sqlPulizia = @"
UPDATE IM_JobsNotes SET Note = REPLACE(CAST(Note AS VARCHAR(MAX)), CHAR(31), '')
WHERE CAST(Note AS VARCHAR(MAX)) LIKE '%' + CHAR(31) + '%'

UPDATE ma_jobs SET Description = REPLACE(CAST(Description AS VARCHAR(MAX)), CHAR(31), '')
WHERE CAST(Description AS VARCHAR(MAX)) LIKE '%' + CHAR(31) + '%'

UPDATE IM_WorkingReportsDetails SET Note = REPLACE(CAST(Note AS VARCHAR(MAX)), CHAR(31), '')
WHERE CAST(Note AS VARCHAR(MAX)) LIKE '%' + CHAR(31) + '%'
"@
        Execute-SqlInline "7.1.1" "Pulizia carattere CHAR(31) dalle tabelle" $sqlPulizia "VEDMaster"

        Write-Ok "FASE 7 completata"
    }
}

# ============================================
# FASE 8 - Trasferimento dati su VEDMaster
# ============================================
if ($DaFase -le 8 -and $AFase -ge 8) {
    Write-Header "FASE 8 - Trasferimento dati su VEDMaster"
    Write-Host "  Per ogni sottoinsieme: prima fix SQL su SSMS, poi script PS di migrazione" -ForegroundColor Gray

    if (Confirm-FaseStart 8 "Trasferimento dati su VEDMaster") {

        # 8.1 - Commesse
        Write-SubHeader "8.1 - Commesse"
        Execute-Script "8.1.1" "MigrazioneSottoinsiemeComesse\Migrate-JobsData.ps1" "Migrazione commesse"

        # 8.2 - Perfetto (parte 1)
        Write-SubHeader "8.2 - Perfetto (parte 1)"
        Execute-SqlFile "8.2.1" "MigrazioneSottoinsiemePerfetto01\Fix-Perfetto-Lengths.sql" "Fix lunghezze Perfetto" "VEDMaster"
        Execute-Script "8.2.2" "MigrazioneSottoinsiemePerfetto01\Migrate-PerfettoData.ps1"  "Migrazione dati Perfetto parte 1"

        # 8.3 - Perfetto (parte 2)
        Write-SubHeader "8.3 - Perfetto (parte 2)"
        Execute-SqlFile "8.3.1" "MigrazioneSottoinsiemePerfetto02\Fix-IM-Lengths.sql"   "Fix lunghezze IM" "VEDMaster"
        Execute-Script "8.3.2" "MigrazioneSottoinsiemePerfetto02\Migrate-ItemsData.ps1" "Migrazione dati Perfetto parte 2"

        # 8.4 - Cross-references
        Write-SubHeader "8.4 - Cross-references"
        Execute-Script "8.4.1" "MigrazioneSottoinsiemeCrossReferences\Migrate-CrossReferencesData.ps1" "Migrazione cross-references"

        # 8.5 - Acquisti
        Write-SubHeader "8.5 - Acquisti"
        Execute-Script "8.5.1" "MigrazioneSottoinsiemeAcquisti\Migrate-PurchaseData.ps1" "Migrazione acquisti"

        # 8.6 - Ordini fornitore
        Write-SubHeader "8.6 - Ordini fornitore"
        Execute-SqlFile "8.6.1" "MigrazioneSottoinsiemeOrdiniFornitore\Increase-DescriptionColumnLength.sql" "Aumento lunghezza colonna Description" "VEDMaster"
        Execute-Script "8.6.2" "MigrazioneSottoinsiemeOrdiniFornitore\Migrate-PurchaseOrdData.ps1"           "Migrazione ordini fornitore"

        # 8.7 - Offerte fornitore
        Write-SubHeader "8.7 - Offerte fornitore"
        Execute-SqlFile "8.7.1" "MigrazioneSottoinsiemeOfferteFornitore\Fix-SuppQuotas-Lengths.sql"  "Fix lunghezze SuppQuotas" "VEDMaster"
        Execute-Script "8.7.2" "MigrazioneSottoinsiemeOfferteFornitore\Migrate-SuppQuotasData.ps1"   "Migrazione offerte fornitore"

        # 8.8 - Offerte cliente
        Write-SubHeader "8.8 - Offerte cliente"
        Execute-SqlFile "8.8.1" "MigrazioneSottoinsiemeOfferteCliente\Fix-CustQuotas-Lengths.sql"  "Fix lunghezze CustQuotas" "VEDMaster"
        Execute-Script "8.8.2" "MigrazioneSottoinsiemeOfferteCliente\Migrate-CustQuotasData.ps1"   "Migrazione offerte cliente"

        # 8.9 - Ordini cliente
        Write-SubHeader "8.9 - Ordini cliente"
        Write-Attenzione "Le tabelle GPX vengono importate da gpxnet (NON gpxnetclone)"
        Execute-SqlFile "8.9.1" "MigrazioneSottoinsiemeOrdiniCliente\Alter_Description_VEDMaster_MA_SaleOrdDetails.sql" "Alter Description MA_SaleOrdDetails" "VEDMaster"
        Execute-Script "8.9.2" "MigrazioneSottoinsiemeOrdiniCliente\Migrate-SaleOrdData.ps1"                            "Migrazione ordini cliente"

        # 8.10 - Preparazione articoli (pulizia tabelle dipendenti)
        Write-SubHeader "8.10 - Preparazione articoli (pulizia tabelle dipendenti)"

        $sqlDeleteArticoli = @"
DELETE FROM vedmaster.dbo.MA_ItemsWMSZones WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsLIFO WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsKit WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsFIFO WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsStorageQtyMonthly WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsLIFODomCurr WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsManufacturingData WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsFIFODomCurr WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsIntrastat WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemNotes WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsPurchaseBarCode WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsLanguageDescri WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsSubstitute WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_StandardCostHistorical WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemsComparableUoM WHERE Item IN (SELECT Item FROM vedmaster.dbo.ma_items);
DELETE FROM vedmaster.dbo.MA_ItemCustomers;
DELETE FROM vedmaster.dbo.MA_ItemSuppliers;
DELETE FROM vedmaster.dbo.ma_items;
"@
        Execute-SqlInline "8.10.1" "DELETE tabelle dipendenti articoli su VEDMaster" $sqlDeleteArticoli "VEDMaster"

        # 8.11 - Articoli
        Write-SubHeader "8.11 - Articoli"
        Execute-SqlFile "8.11.1" "MigrazioneSottoinsiemeArticoli\Fix-MA_Items-Description-280.sql" "Fix Description 280 su MA_Items" "VEDMaster"
        Execute-Script "8.11.2" "MigrazioneSottoinsiemeArticoli\Migrate-ItemsData.ps1"             "Migrazione articoli"

        # 8.12 - Magazzino
        Write-SubHeader "8.12 - Magazzino"
        Execute-Script "8.12.1" "MigrazioneSottoinsiemeMagazzino\Migrate-StockData.ps1" "Migrazione magazzino"

        Write-Ok "FASE 8 completata"
    }
}

# ============================================
# FASE 9 - Post-trasferimento (su VEDMaster)
# ============================================
if ($DaFase -le 9 -and $AFase -ge 9) {
    Write-Header "FASE 9 - Post-trasferimento (su VEDMaster)"

    if (Confirm-FaseStart 9 "Post-trasferimento") {

        # 9.1 - Non piu necessario (sostituito dallo script 28 in Fase 7.0)
        Write-SubHeader "9.1 - Aggiornamento riferimenti fatture"
        Write-Host "  NOTA: Se e stato eseguito lo script 28 (Fase 7.0), questo passo e SALTATO" -ForegroundColor Yellow
        Write-Host "  Lo script 23 e disponibile come fallback se non si usa lo script 28" -ForegroundColor Gray

        $usaScript23 = Read-Host "  Hai eseguito lo script 28 (Fase 7.0)? (S=salta / N=esegui script 23)"
        if ($usaScript23 -eq "N" -or $usaScript23 -eq "n") {
            Execute-Script "9.1.1" "23PostTrasfAggiornariffatturevedmaster.ps1" "Fix riferimenti fatture VEDMaster (fallback)"
        } else {
            Write-Host "  Passo 9.1 saltato (script 28 gia eseguito)" -ForegroundColor Green
        }

        # 9.2 - Colonne aggiuntive
        Write-SubHeader "9.2 - Colonne aggiuntive IM_SpecificationsItems"
        Show-ManualStep "9.2.1" "Aggiungere colonne a IM_SpecificationsItems su VEDMaster" @(
            "k (float, NULL)",
            "idSal (nchar(10), NULL)",
            "Riga (float, NULL)"
        )

        # 9.3 - Aggiornamento numeratori
        Write-SubHeader "9.3 - Aggiornamento numeratori"
        Execute-Script "9.3.1" "24OpreazioniIds.ps1" "Aggiorna MA_IDNumbers con i nuovi ID"

        # 9.4 - Dati GPX RAM
        Write-SubHeader "9.4 - Dati GPX RAM"

        Show-ManualStep "9.4.1" "Controllare campi chiave tabelle gpx_" @(
            "Verificare che i campi chiave delle tabelle gpx_ esistano"
        )

        Show-ManualStep "9.4.2" "Chiave su gpx_parametri" @(
            "Su VEDMaster: inserire chiave su gpx_parametri campo chiave 'Codice'"
        )

        Show-ManualStep "9.4.3" "Chiave multipla su gpx_parametririghe" @(
            "Su VEDMaster: inserire chiave multipla su gpx_parametririghe campi 'Codice' e 'Deposito'"
        )

        Execute-SqlFile "9.4.4" "MigrazioneSottoinsiemeGpx\Fix-gpx_righeram-Descrizione-280.sql" "Fix Descrizione 280 su gpx_righeram" "VEDMaster"
        Execute-Script "9.4.5" "MigrazioneSottoinsiemeGpx\Migrate-GpxData.ps1"                   "Migrazione dati GPX"

        $sqlGpxRam = @"
UPDATE d
SET d.SaleDocId = c.SaleOrdId
FROM VEDMaster.dbo.gpx_saledocram d
INNER JOIN gpxnet.dbo.gpx_saledocram a ON d.IdRam = a.IdRam
INNER JOIN gpxnet.dbo.MA_SaleOrd b ON a.SaleDocId = b.SaleOrdId
INNER JOIN VEDMaster.dbo.MA_SaleOrd c ON c.InternalOrdNo = b.InternalOrdNo
"@
        Execute-SqlInline "9.4.6" "Aggiorna riferimenti ordini clienti alle RAM di GPX" $sqlGpxRam "VEDMaster"

        # 9.5 - Employees
        Write-SubHeader "9.5 - Employees"
        Execute-Script "9.5.1" "MigrazioneSottoinsiemeEmployees\Migrate-ItemsData.ps1" "Migrazione employees"

        # 9.6 - Viste
        Write-SubHeader "9.6 - Viste"
        Execute-Script "9.6.1" "25trasferisciviews.ps1" "Trasferisci viste per i report"

        # 9.7 - Multistorages
        Write-SubHeader "9.7 - Multistorages"
        Execute-Script "9.7.1" "MigrazioneSottoinsiemeMultistorages\Migrate-ItemsData.ps1" "Migrazione multistorages"

        # 9.8 - Lotti
        Write-SubHeader "9.8 - Lotti"
        Execute-Script "9.8.1" "MigrazioneSottoinsiemeLotti\Migrate-LotsData.ps1" "Migrazione lotti"

        # 9.9 - DDT
        Write-SubHeader "9.9 - DDT"
        Execute-SqlFile "9.9.1" "MigrazioneSottoinsiemeDdt\Fix-MA_SaleDocDetail-Description-512.sql" "Fix Description 512 su MA_SaleDocDetail" "VEDMaster"
        Execute-Script "9.9.2" "MigrazioneSottoinsiemeDdt\Migrate-ItemsData.ps1"                     "Migrazione DDT"

        # 9.10 - Fix CrossReferences Fatture -> Doc Contabile
        Write-SubHeader "9.10 - Fix CrossReferences Fatture"
        Execute-Script "9.10.1" "29a_CreaMA_CrossReferencesOrigin.ps1"      "Backup MA_CrossReferences (Origin + Backup)"
        Execute-Script "9.10.2" "29CorrettivoFixDerivedDocIdFatture.ps1"    "Fix DerivedDocID Fattura->DocContabile"

        Write-Ok "FASE 9 completata"
    }
}

# ============================================
# FASE 10 - Workaround RAM GPX + Chiusura
# ============================================
if ($DaFase -le 10 -and $AFase -ge 10) {
    Write-Header "FASE 10 - Workaround RAM GPX"
    Write-Host "  Necessario per evitare collisioni ID tra ordini GPX esistenti e nuovi" -ForegroundColor Gray

    if (Confirm-FaseStart 10 "Workaround RAM GPX") {

        $sqlRamWorkaround = @"
-- Verificare l'ultimo SaleOrdId su gpxnet
SELECT MAX(SaleOrdId) FROM gpxnet.dbo.MA_SaleOrd

-- Impostare LastId al valore negativo corrispondente
-- ATTENZIONE: sostituire 6335 con il valore MAX effettivo trovato sopra!
-- UPDATE VEDMaster.dbo.MA_IDNumbers SET LastId = -6335 WHERE CodeType = 3801098
"@
        Execute-SqlInline "10.1" "Impostare numeratore ordini in negativo" $sqlRamWorkaround "VEDMaster"
        Write-Attenzione "Sostituire 6335 con il valore MAX effettivo da gpxnet.dbo.MA_SaleOrd"

        Show-ManualStep "10.2" "Creare chiave multipla su gpx_saledocram" @(
            "Su VEDMaster: creare chiave multipla su gpx_saledocram campi 'SaleDocId' e 'IdRam'"
        )

        Write-Ok "FASE 10 completata"
    }
}

# ============================================
# RIEPILOGO FINALE
# ============================================
Write-Header "MIGRAZIONE COMPLETATA"
Write-Host "  Fasi eseguite: $DaFase -> $AFase" -ForegroundColor Green
Write-Host "  Log salvato in: $logFile" -ForegroundColor Gray
Write-Host ""
Write-Host "  Verifiche consigliate:" -ForegroundColor Yellow
Write-Host "    - Controllare i log per errori" -ForegroundColor White
Write-Host "    - Verificare conteggio record nelle tabelle principali" -ForegroundColor White
Write-Host "    - Verificare integrita cross-references" -ForegroundColor White
Write-Host "    - Testare apertura documenti da Mago4" -ForegroundColor White
Write-Host ""

Stop-Transcript
