# Analisi Progressione Script Migrazione VED

**Data analisi**: 2026-02-23
**Documento analizzato**: `progressionescripts.txt`
**Script totali nel progetto**: ~134 file .ps1

---

## Indice

1. [Flusso completo ricostruito](#1-flusso-completo-ricostruito)
2. [Bug critici](#2-bug-critici)
3. [Script mancante nella progressione](#3-script-mancante-nella-progressione)
4. [Problemi di design e fragilita](#4-problemi-di-design-e-fragilita)
5. [Script potenzialmente ridondanti](#5-script-potenzialmente-ridondanti)
6. [Correzioni gia applicate](#6-correzioni-gia-applicate)
7. [Ordine di esecuzione suggerito](#7-ordine-di-esecuzione-suggerito)

---

## 1. Flusso completo ricostruito

### Fase A: Preparazione (clonazione e pulizia)

| Step | Script | Descrizione |
|------|--------|-------------|
| A1 | `duplicadbvedcontab.ps1` | Clona DB vedcontab |
| A2 | `duplicadbvedbondife.ps1` | Clona DB vedbondife |
| A3 | `duplicadbfurmanet.ps1` | Clona DB furmanet |
| A4 | `duplicadbgpxnet.ps1` | Clona DB gpxnet |
| A5 | `SvuotaVedmaster.ps1` | Svuota DB destinazione VEDMaster |
| A6 | `CreaMappaCommesseDuplicate.ps1` | Crea mappa commesse duplicate (MM4_MappaJobsCodes) |
| A7 | *MANUALE* | Creare depositi e causali |

### Fase B: Rinumerazione (sui DB clone)

| Step | Script | ID rinumerato | gpx | furma | vedbondife |
|------|--------|---------------|-----|-------|------------|
| B1 | `01rinumerajobid.ps1` | IM_JobId / JobId | +100000 | +200000 | +300000 |
| B2 | `02disableoldjobscodes.ps1` | - (disabilita vecchi codici) | - | furma+bondife | - |
| B3 | **MANCANTE: `03replaceoldcodes.ps1`** | Job codes in tabelle IM_Jobs* | - | furma+bondife | - |
| B4 | `04aggiornadocumenti.ps1` | Job codes in tabelle documento | - | furma+bondife | - |
| B5 | `05RinumeraIdAcquisti.ps1` | PurchaseDocId | +100000 | +200000 | +300000 |
| B6 | `06RinumeraIdOrdiniFornitori.ps1` | PurchaseOrdId | +100000 | +200000 | +300000 |
| B7 | `07RinumeraIdOfferteFornitori.ps1` | SuppQuotaId | +100000 | +200000 | +300000 |
| B8 | `08RinumeraIdOfferteClienti.ps1` | CustQuotaId | +100000 | +200000 | +300000 |
| B9 | `09RinumeraIdOrdiniClienti.ps1` | SaleOrdId | +100000 | +200000 | +300000 |
| B10 | `10RinumeraEntryId.ps1` | EntryId | +1000000 | +500000 | +600000 |
| B11 | `11RinumeraImQuotations.ps1` | QuotationRequestId | +400000 | +500000 | +600000 |
| B12 | `12RinumeraImRapportini.ps1` | WorkingReportId | +400000 | +1000000 | +600000 |
| B13 | `13RinumeraLibretti.ps1` | MeasuresBookId | +100000 | +200000 | +300000 |
| B14 | `14RinumeraAnalisiPreventivo.ps1` | JobQuotationId | +100000 | +200000 | +300000 |
| B15 | `15RinumeraSal.ps1` | WPRId | +100000 | +200000 | +300000 |
| B16 | `27rinumerasaledoc.ps1` | SaleDocId | +400000 | +200000 | +300000 |

### Fase C: Cross-references (sui DB clone)

| Step | Script | Descrizione |
|------|--------|-------------|
| C1 | `18CreaMappaRiferimenti.ps1` | Crea TAG_DocumentTypesCr (~85 tipi documento) |
| C2 | `19AggiornaCRossReference.ps1` | Aggiorna OriginDocID/DerivedDocID in MA_CrossReferences + MA_CrossReferencesNotes |
| C3 | `19BisRinumerasubid.ps1` | Rinumera SubID (WHERE > 0, offset 100k/200k/300k) |
| C4 | `20AggCrossreferenceCommesse.ps1` | Aggiorna CrossRef per commesse (DocType 27066672/27066673) |
| C5 | `21ExportCrossReference.ps1` | Esporta CrossRef in MM4HelperDb (tabelle con suffisso Bondife/Furma/Gpx) |
| C6 | `22Aggiornacausaliedeposuorigini.ps1` | Aggiorna causali (InvRsn) e depositi (StoragePhase) |

### Fase D: Trasferimento dati su VEDMaster

| Step | Cartella/Script | Descrizione |
|------|----------------|-------------|
| D0 | *SQL manuale* | Pulizia CHAR(31) da IM_JobsNotes, MA_Jobs.Description, IM_WorkingReportsDetails.Note |
| D1 | `MigrazioneSottoinsiemeComesse/` | Migrate-JobsData.ps1 |
| D2 | `MigrazioneSottoinsiemePerfetto01/` | Fix-Perfetto-Lengths.sql + Migrate-PerfettoData.ps1 |
| D3 | `MigrazioneSottoinsiemePerfetto02/` | Fix-IM-Lengths.sql + Migrate-ItemsData.ps1 |
| D4 | `MigrazioneSottoinsiemeCrossReferences/` | Migrate-CrossReferencesData.ps1 |
| D5 | `MigrazioneSottoinsiemeAcquisti/` | Migrate-PurchaseData.ps1 |
| D6 | `MigrazioneSottoinsiemeOrdiniFornitore/` | Increase-DescriptionColumnLength.sql + Migrate-PurchaseOrdData.ps1 |
| D7 | `MigrazioneSottoinsiemeOfferteFornitore/` | Fix-SuppQuotas-Lengths.sql + Migrate-SuppQuotasData.ps1 |
| D8 | `MigrazioneSottoinsiemeOfferteCliente/` | Fix-CustQuotas-Lengths.sql + Migrate-CustQuotasData.ps1 |
| D9 | `MigrazioneSottoinsiemeOrdiniCliente/` | Alter_Description + Migrate-SaleOrdData.ps1 **NB: GPX da gpxnet, NON gpxnetclone** |
| D10 | *SQL manuale* | DELETE tabelle Items dipendenti + DELETE MA_Items |
| D11 | `MigrazioneSottoinsiemeArticoli/` | Fix-MA_Items-Description-280.sql + Migrate-ItemsData.ps1 |
| D12 | `MigrazioneSottoinsiemeMagazzino/` | Migrate-StockData.ps1 |

### Fase D-bis: Rinumerazione SaleDocId su VEDMaster (NUOVO)

| Step | Script | Descrizione |
|------|--------|-------------|
| D-bis | `28RinumeraSaleDocVedmaster.ps1` | Rinumera SaleDocId su VEDMaster per allinearli ai clone (match per business key). **Rende superfluo lo script 23** |

> **NOTA**: Questo script va eseguito DOPO l'importazione fatture da vedcontab su VEDMaster e PRIMA dell'importazione cross-references dai clone (D4). Risolvendo il problema degli ID alla radice, i cross-references importati dai clone sono corretti by design.

### Fase E: Post-trasferimento (su VEDMaster)

| Step | Script | Descrizione |
|------|--------|-------------|
| E1 | `22PostTrasfUpdateCrossReference.ps1` | Aggiorna CrossRef commesse (OriginDocID + DerivedDocID) |
| ~~E2~~ | ~~`23PostTrasfAggiornariffatturevedmaster.ps1`~~ | ~~Corregge ID esistenti + importa cross-ref mancanti dai clone~~ **SOSTITUITO da script 28 (Fase D-bis)** |
| E3 | *MANUALE* | Aggiungere colonne a IM_SpecificationsItems (k, idSal, Riga) |
| E4 | `24OpreazioniIds.ps1` | Aggiorna MA_IDNumbers (numeratori) |
| E5 | *MANUALE* | Chiavi su tabelle gpx_parametri e gpx_parametririghe |
| E6 | `MigrazioneSottoinsiemeGpx/` | Fix-gpx_righeram + Migrate-GpxData.ps1 |
| E7 | *SQL manuale* | UPDATE gpx_saledocram per riferimenti RAM |
| E8 | `MigrazioneSottoinsiemeEmployees/` | Migrate-ItemsData.ps1 |
| E9 | `25trasferisciviews.ps1` | Trasferisce viste per report |
| E10 | `MigrazioneSottoinsiemeMultistorages/` | Migrate-ItemsData.ps1 |
| E11 | `MigrazioneSottoinsiemeLotti/` | Migrate-LotsData.ps1 |
| E12 | `MigrazioneSottoinsiemeDdt/` | Fix-MA_SaleDocDetail-Description-512 + Migrate-ItemsData.ps1 |

### Fase F: Fix cross-references su VEDMaster

> **NOTA**: I passi F3-F7 sono ora **completamente superflui** grazie allo script 28 (Fase D-bis).
> Rinumerando gli ID su VEDMaster PRIMA del trasferimento, i cross-references sono corretti by design.

| Step | Tipo | Descrizione | Stato |
|------|------|-------------|-------|
| F1 | *MANUALE* | Impostare numeratore ordini negativo per RAM GPX | Attivo |
| F2 | *MANUALE* | Creare chiave multipla su gpx_saledocram | Attivo |
| ~~F3~~ | ~~*SQL manuale*~~ | ~~Creare e popolare tabella SaleDocMapping~~ | **SUPERFLUO** (script 28 allinea gli ID alla radice) |
| ~~F4~~ | ~~*SQL manuale*~~ | ~~UPDATE OriginDocID per fatture vedcontab~~ | **SUPERFLUO** (script 28) |
| ~~F5~~ | ~~*SQL manuale*~~ | ~~UPDATE DerivedDocID per fatture (per SourceDB)~~ | **SUPERFLUO** (script 28) |
| ~~F6~~ | ~~*SQL manuale*~~ | ~~Revert offset ordini GPX~~ | **RIMOSSO** (correzione 3C) |
| ~~F7~~ | ~~*SQL manuale*~~ | ~~DELETE cross-ref con customer mismatch~~ | **SUPERFLUO** (script 28: cross-ref corretti by design) |

---

## 2. Bug critici

### 2.1 ~~[CRITICO] UPDATE -100000 senza filtro per database di origine~~ RISOLTO

**Stato**: **RISOLTO con correzione 3C** - gpxnetclone escluso dallo script 09, l'intero workaround -100000 e' stato rimosso da progressionescripts.txt.

**Problema originale**: Lo script 09 rinumerava ordini GPX (+100000), ma gli ordini venivano importati da gpxnet (non clone) con ID originali. Serviva un workaround -100000 post-trasferimento che aveva un bug (nessun filtro per range).

**Soluzione applicata**: gpxnetclone rimosso da tutti i 4 file nella cartella `09rinumeraIdordiniclienti/`:
- `01disableconstraints.ps1`
- `02rinumeraIdordiniclienti.ps1`
- `02rinumeraidordiniclientiCrs.ps1`
- `03enableconstraints.ps1`

Gli ordini GPX non vengono piu rinumerati, quindi i CrossReferences (dal clone) restano coerenti con gli ordini importati (da gpxnet originale). Il workaround -100000 in progressionescripts.txt e' stato rimosso.

---

### ~~2.2 [CRITICO] Mismatch DocumentType / DocType nello script 23 e SaleDocMapping~~ RISOLTO

**Stato**: **RISOLTO con script 23 v4.0** - lo script non filtra piu per singolo DocumentType/ReferenceCode. Opera su TUTTI i 19 ReferenceCode SaleDoc (27066381-27066399) e crea TAG_SaleDocMapping per TUTTI i DocumentType. Il mismatch tra 27066387/27066385 non e' piu rilevante.

**Problema originale**: Lo script joinava Fatture Accompagnatorie (DocumentType=3407874) con il ReferenceCode di Fatture Immediate (27066387) anzi che 27066385. Corretto nella v1.0→v2.0, ma nella v4.0 il problema e' eliminato alla radice perche gestisce tutti i tipi.

---

### ~~2.3 [CRITICO] SaleDocMapping gestisce solo DocumentType 3407874~~ RISOLTO

**Stato**: **RISOLTO con script 23 v4.0** - TAG_SaleDocMapping viene ora creata per TUTTI i DocumentType (non solo 3407874). La query di matching usa DocNo+DocumentDate+CustSupp+DocumentType senza filtro su tipo specifico.

**Problema originale**: La tabella SaleDocMapping manuale veniva popolata solo per DocumentType=3407874 (Fattura Accompagnatoria), ignorando DDT, Fatture Immediate, Note di Credito, etc.

---

## 3. Script mancante nella progressione

### 3.1 `03replaceoldcodes.ps1` non elencato

Lo script esiste nel progetto ma non appare nella progressione tra `02disableoldjobscodes.ps1` e `04aggiornadocumenti.ps1`.

**Cosa fa**: Aggiorna i codici Job in 11 tabelle IM_Jobs*:
- IM_JobsBalance, IM_JobsComponents, IM_JobsCostsRevenuesSummary
- IM_JobsDetailsVCL, IM_JobsDocuments, IM_JobsItems
- IM_JobsNotes, IM_JobsSummaryByCompTypeByWorkingStep
- IM_JobsStatOfAccount, IM_JobsWithholdingTax, IM_JobsWorkingStep

**Cosa fa script 04**: Aggiorna i codici Job in 26 tabelle documento (MA_PurchaseOrd, MA_SaleDoc, etc.)

**I due script sono complementari**, non sovrapposti. Senza script 03, le tabelle IM_Jobs* restano con i vecchi codici Job.

**Processano**: Solo furmanetclone e vedbondifeclone (gpxnetclone escluso - probabilmente intenzionale se GPX non ha commesse duplicate).

---

## 4. Problemi di design e fragilita

### 4.1 Doppio "script 22" con scopi diversi

Due script condividono lo stesso numero:
- **Pre-trasferimento**: `22Aggiornacausaliedeposuorigini.ps1` - aggiorna causali e depositi
- **Post-trasferimento**: `22PostTrasfUpdateCrossReference.ps1` - aggiorna cross-references commesse

**Suggerimento**: Rinominare il post-trasferimento con un numero diverso (es. `25PostTrasfUpdateCrossReference.ps1`).

### 4.2 Numerazione script non sequenziale

| Range | Script presenti | Gap |
|-------|----------------|-----|
| 01-04 | 01, 02, 03, 04 | Nessuno (ma 03 manca dalla progressione) |
| 05-15 | 05-15 | Nessuno |
| 16-17 | - | Non esistono |
| 18-22 | 18, 19, 19Bis, 20, 21, 22 | OK |
| 23-26 | 23, 24, 25, 26 | Post-trasferimento |
| 27 | 27 | Fuori sequenza (dovrebbe essere tra 15 e 18) |

### 4.3 ~~Workaround GPX ordini clienti - approccio fragile~~ RISOLTO

**Correzione 3C applicata**: gpxnetclone escluso dallo script 09.

**Flusso corretto**:

1. Script 09 rinumera ordini solo in furmanetclone (+200000) e vedbondifeclone (+300000)
2. Script 19 aggiorna CrossReferences nei clone (gpxnetclone non ha offset su ordini)
3. Migrazione ordini GPX da **gpxnet** (originale) - ID originali
4. CrossReferences GPX nel clone hanno gli stessi ID originali - **coerenti**
5. Nessun workaround -100000 necessario

**File modificati**:

- `09rinumeraIdordiniclienti/01disableconstraints.ps1` - rimosso gpxnetclone
- `09rinumeraIdordiniclienti/02rinumeraIdordiniclienti.ps1` - rimosso gpxnetclone
- `09rinumeraIdordiniclienti/02rinumeraidordiniclientiCrs.ps1` - rimosso gpxnetclone
- `09rinumeraIdordiniclienti/03enableconstraints.ps1` - rimosso gpxnetclone
- `progressionescripts.txt` - rimosso workaround -100000

### ~~4.4 Script 23 opera solo su un DocType~~ RISOLTO

**Stato**: **RISOLTO con script 23 v4.0** - gestisce TUTTI i 19 tipi SaleDoc (27066381-27066399), sia come OriginDocType che DerivedDocType. Inoltre importa i cross-references mancanti direttamente dai DB clone.

**Problema originale**: Lo script aggiornava solo `DerivedDocType = 27066387`, ignorando OriginDocType e altri tipi documento.

### 4.5 Script 03 e 04 - gpxnetclone escluso

Entrambi gli script processano solo `furmanetclone` e `vedbondifeclone`. Se gpxnetclone ha commesse con codici da rimappare tramite MM4_MappaJobsCodes, queste non vengono aggiornate.

Potrebbe essere intenzionale (GPX non ha commesse duplicate), ma da verificare.

---

## 5. Script potenzialmente ridondanti

| Script | Scopo | Osservazione |
|--------|-------|-------------|
| `21ExportCrossReference.ps1` | Esporta CrossRef in MM4HelperDb con suffissi (Bondife/Furma/Gpx) | Passaggio intermedio. Se `Migrate-CrossReferencesData.ps1` legge direttamente dai clone, questo step potrebbe non servire. **Verificare** se il Migrate legge da MM4HelperDb o dai clone. |
| ~~Query manuali SaleDocMapping (F3-F5)~~ | ~~Fix fatture vedcontab su VEDMaster~~ | **SOSTITUITO** da script 23 v4.0 (Fasi 1-3) |
| ~~DELETE cross-ref (F7)~~ | ~~Pulizia cross-ref con customer mismatch~~ | **SOSTITUITO** da script 23 v4.0 (Fase 4: importa solo cross-ref validi dai clone) |

### Script non menzionati nella progressione

Questi script esistono nel progetto ma non appaiono nella progressione:

| Script | Scopo probabile | Necessario? |
|--------|----------------|-------------|
| `03replaceoldcodes.ps1` | Replace codici Job in tabelle IM_Jobs* | **SI - da aggiungere** (vedi punto 3.1) |
| `26_sistemazioneMa_IremsCustomers.ps1` | Fix tabella MA_ItemCustomers | Da verificare se serve nella progressione |
| `28RinumeraSaleDocVedmaster.ps1` | Rinumera SaleDocId su VEDMaster per allinearli ai clone | **SI - da eseguire prima di D4 (cross-references)** |
| `28TrasferisciJobs.ps1` | Trasferimento Jobs | Da verificare - potrebbe essere un'alternativa a MigrazioneSottoinsiemeComesse |
| `conflitti.ps1` | Analisi conflitti | Diagnostica, non necessario nella progressione |
| `AnalizzaConflittiJob.ps1` | Analisi conflitti Job | Diagnostica |
| `DiagnosticaMigrazioneProblemi.ps1` | Diagnostica | Diagnostica |
| `DiagnosticaSemplice.ps1` | Diagnostica | Diagnostica |
| `TransferAllJobTables.ps1` | Trasferimento tabelle Job | Da verificare - potrebbe essere un'alternativa |

---

## 6. Correzioni gia applicate

Le seguenti correzioni sono state applicate agli script prima di questa analisi:

| Script | Correzione | Priorita |
|--------|-----------|----------|
| `27rinumerasaledoc/02rinumeraIdSaledocCrs.ps1` | CASE mapping per tutti i 17 tipi SaleDoc (non solo DDT). Aggiunte 3 tabelle FK mancanti (MA_SaleDocDetailAccDef, MA_SaleDocDetailVar, MA_BRNotaFiscalForCustAdDat) | CRITICO |
| `18CreaMappaRiferimenti.ps1` | Espanso da 19 a ~85 tipi documento. Mantenuta doppia serie 98304xx (acquisti script 05) e 3801xxx (tutti gli altri) | CRITICO |
| `19BisRinumerasubid.ps1` | Aggiunto `WHERE field > 0` per non corrompere valori zero. Update separati per campo (MA_CrossReferences: OriginDocSubID e DerivedDocSubID indipendenti) | ALTO |
| `19AggiornaCRossReference.ps1` | Aggiunto aggiornamento OriginDocID e DerivedDocID su MA_CrossReferencesNotes | ALTO |
| `claudecorrection/03_AggiornaCrossReferencesCompleto.ps1` | Aggiunta Fase 2B per MA_CrossReferencesNotes | ALTO |
| `22PostTrasfUpdateCrossReference.ps1` | Aggiunto DerivedDocID update, aggiunto gpxnetclone, filtro DocType, check esistenza MM4_MappaJobsCodes | MEDIO |
| `23PostTrasfAggiornariffatturevedmaster.ps1` | Corretto mismatch DocType: 27066387 (Fatt.Immediata) → 27066385 (Fatt.Accompagnatoria) per coerenza con DocumentType=3407874 | CRITICO |
| `progressionescripts.txt` (query manuali) | Corretto 27066387→27066385 nelle query SaleDocMapping (backup, UPDATE Origin, UPDATE Derived x3). Corretto -100000 con filtro BETWEEN per range GPX | CRITICO |
| `23PostTrasfAggiornariffatturevedmaster.ps1` **v4.0** | Riscrittura completa: approccio basato sui clone. Importa cross-ref mancanti dai 3 DB clone con mapping ID tramite TAG_SaleDocMapping. Risolve bug 2.2, 2.3, 4.4. Sostituisce query manuali F3-F7 | CRITICO |
| `09rinumeraIdordiniclienti/01disableconstraints.ps1` | Rimosso gpxnetclone (correzione 3C: ordini GPX non devono essere rinumerati) | CRITICO |
| `09rinumeraIdordiniclienti/02rinumeraIdordiniclienti.ps1` | Rimosso gpxnetclone (correzione 3C) | CRITICO |
| `09rinumeraIdordiniclienti/02rinumeraidordiniclientiCrs.ps1` | Rimosso gpxnetclone (correzione 3C) - include anche TAG_CrMaps per DocumentType 3801098 | CRITICO |
| `09rinumeraIdordiniclienti/03enableconstraints.ps1` | Rimosso gpxnetclone (correzione 3C) | CRITICO |
| `progressionescripts.txt` (workaround -100000) | Rimosso workaround revert offset GPX (correzione 3C: non piu necessario) | CRITICO |
| **`28RinumeraSaleDocVedmaster.ps1`** | **NUOVO: Rinumera SaleDocId su VEDMaster per allinearli ai clone (match per business key). Rende superfluo lo script 23 e tutte le query manuali F3-F7** | **CRITICO** |

---

## 7. Ordine di esecuzione suggerito

### Pre-trasferimento (sui DB clone)

```
-- Clonazione
duplicadbvedcontab.ps1
duplicadbvedbondife.ps1
duplicadbfurmanet.ps1
duplicadbgpxnet.ps1

-- Preparazione
SvuotaVedmaster.ps1
CreaMappaCommesseDuplicate.ps1
[MANUALE: creare depositi e causali]

-- Rinumerazione Job
01  rinumerajobid.ps1
02  disableoldjobscodes.ps1
03  replaceoldcodes.ps1                    <-- AGGIUNGERE alla progressione
04  aggiornadocumenti.ps1

-- Rinumerazione ID documenti
05  RinumeraIdAcquisti.ps1
06  RinumeraIdOrdiniFornitori.ps1
07  RinumeraIdOfferteFornitori.ps1
08  RinumeraIdOfferteClienti.ps1
09  RinumeraIdOrdiniClienti.ps1            [CORRETTO 3C: gpxnetclone escluso]
10  RinumeraEntryId.ps1
11  RinumeraImQuotations.ps1
12  RinumeraImRapportini.ps1
13  RinumeraLibretti.ps1
14  RinumeraAnalisiPreventivo.ps1
15  RinumeraSal.ps1
27  rinumerasaledoc.ps1

-- Cross-references
18  CreaMappaRiferimenti.ps1               [CORRETTO: ~85 tipi]
19  AggiornaCRossReference.ps1             [CORRETTO: + CrossReferencesNotes]
19B RinumeraSubid.ps1                      [CORRETTO: WHERE > 0]
20  AggCrossreferenceCommesse.ps1
21  ExportCrossReference.ps1
22  Aggiornacausaliedeposuorigini.ps1
```

### Trasferimento (su VEDMaster)

```
[SQL: pulizia CHAR(31)]
MigrazioneSottoinsiemeComesse
MigrazioneSottoinsiemePerfetto01
MigrazioneSottoinsiemePerfetto02
MigrazioneSottoinsiemeCrossReferences
MigrazioneSottoinsiemeAcquisti
MigrazioneSottoinsiemeOrdiniFornitore
MigrazioneSottoinsiemeOfferteFornitore
MigrazioneSottoinsiemeOfferteCliente
MigrazioneSottoinsiemeOrdiniCliente       [NB: GPX da gpxnet, non clone]
[SQL: DELETE tabelle Items dipendenti]
MigrazioneSottoinsiemeArticoli
MigrazioneSottoinsiemeMagazzino
```

### Pre-trasferimento su VEDMaster (NUOVO)

```text
28  RinumeraSaleDocVedmaster.ps1           [NUOVO: rinumera SaleDocId su VEDMaster per allinearli ai clone]
```

> **NOTA**: Eseguire DOPO importazione fatture da vedcontab e PRIMA di MigrazioneSottoinsiemeCrossReferences.
> Rende superfluo lo script 23 e tutte le query manuali della Fase F.

### Post-trasferimento (su VEDMaster)

```text
22P PostTrasfUpdateCrossReference.ps1      [CORRETTO: + DerivedDocID + gpxnetclone]
--  23 NON PIU NECESSARIO                 [SOSTITUITO da script 28]
[MANUALE: colonne IM_SpecificationsItems]
24  OpreazioniIds.ps1
[MANUALE: chiavi tabelle gpx_]
MigrazioneSottoinsiemeGpx
[SQL: UPDATE gpx_saledocram]
MigrazioneSottoinsiemeEmployees
25  trasferisciviews.ps1
MigrazioneSottoinsiemeMultistorages
MigrazioneSottoinsiemeLotti
MigrazioneSottoinsiemeDdt

-- Fix fatture vedcontab: TUTTO SOSTITUITO dallo script 28 (rinumerazione proattiva)
-- [RIMOSSO F3: SaleDocMapping manuale]    -> non necessario (ID gia allineati)
-- [RIMOSSO F4-F5: UPDATE cross-ref]       -> non necessario (ID gia allineati)
-- [RIMOSSO F6: revert offset GPX]         -> correzione 3C
-- [RIMOSSO F7: pulizia customer mismatch] -> non necessario (cross-ref corretti by design)
```

---

## Appendice: Mappa completa DocumentType / ReferenceCode

Riferimento per verificare la coerenza dei filtri nelle query:

| Tipo documento | DocumentType (MA_SaleDoc) | Specie Archivio (EnumValue) | ReferenceCode (CrossRef) |
|---------------|--------------------------|---------------------------|-------------------------|
| DDT | 3407873 | 3801088 | 27066383 |
| Fattura Accompagnatoria | 3407874 | 3801091 | 27066385 |
| Fattura Immediata | 3407875 | 3801095 | 27066387 |
| Nota di Credito | 3407876 | 3801097 | 27066389 |
| Nota di Debito | 3407877 | 3801101 | 27066390 |
| Ricevuta Fiscale | 3407878 | 3801104 | 27066391 |
| Ricevuta Fiscale a Correzione | 3407879 | 3801105 | 27066392 |
| Ricevuta Fiscale Non Incassata | 3407880 | 3801106 | 27066393 |
| Paragon | 3407881 | 3801107 | 27066394 |
| Paragon a Correzione | 3407882 | 3801108 | 27066395 |
| Fattura di Acconto | 3407883 | 3801102 | 27066396 |
| Fattura ProForma | 3407884 | 3801103 | 27066397 |
| Fattura Accomp. a Correzione | 3407885 | 3801094 | 27066386 |
| Fattura a Correzione | 3407886 | 3801096 | 27066388 |
| Reso da Cliente | 3407887 | 3801089 | 27066382 |
| DDT per Lavorazione Esterna | 3407888 | 3801090 | 27066384 |
| Trasferimento tra Depositi | 3407889 | 3801110 | 27066398 |
