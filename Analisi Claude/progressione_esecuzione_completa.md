# Progressione Esecuzione Completa - Migrazione VED

**Scopo**: Unire al DB di destinazione (VEDMaster) i documenti presenti nei DB clone (gpxnetclone, furmanetclone, vedbondifeclone).
**Premessa**: VEDMaster contiene gia fatture, movimenti contabili e anagrafica clienti/fornitori (da vedcontab).
**Criticita**: Evitare sovrapposizione di ID, ricostruzione corretta della tabella MA_CrossReferences.

**Legenda**:

- SCRIPT = script PowerShell da eseguire
- SQL = query SQL da eseguire su SSMS
- MANUALE = operazione manuale

---

## FASE 1 - Clonazione database

| #   | Tipo   | Azione                    |
| --- | ------ | ------------------------- |
| 1.1 | SCRIPT | `duplicadbvedcontab.ps1`  |
| 1.2 | SCRIPT | `duplicadbvedbondife.ps1` |
| 1.3 | SCRIPT | `duplicadbfurmanet.ps1`   |
| 1.4 | SCRIPT | `duplicadbgpxnet.ps1`     |

---

## FASE 2 - Preparazione VEDMaster

| #   | Tipo   | Azione                                                             |
| --- | ------ | ------------------------------------------------------------------ |
| 2.1 | SCRIPT | `SvuotaVedmaster.ps1`                                              |
| 2.2 | SCRIPT | `CreaMappaCommesseDuplicate.ps1` - crea tabella MM4_MappaJobsCodes |

---

## FASE 3 - Rinumerazione Job (sui DB clone)

Questi script aggiornano i codici commessa nei DB clone per evitare collisioni.

| #   | Tipo   | Azione                                                                  | DB coinvolti        |
| --- | ------ | ----------------------------------------------------------------------- | ------------------- |
| 3.1 | SCRIPT | `01rinumerajobid.ps1` - rinumera IM_JobId/JobId (+100k/+200k/+300k)     | gpx, furma, bondife |
| 3.2 | SCRIPT | `02disableoldjobscodes.ps1` - disabilita vecchi codici Job              | furma, bondife      |
| 3.3 | SCRIPT | `03replaceoldcodes.ps1` - aggiorna codici Job in 11 tabelle IM_Jobs*    | furma, bondife      |
| 3.4 | SCRIPT | `04aggiornadocumenti.ps1` - aggiorna codici Job in 26 tabelle documento | furma, bondife      |

> **NOTA**: Lo script 03 non era presente nella progressione originale ma e' necessario. Senza di esso le tabelle IM_Jobs* restano con i vecchi codici.

---

## FASE 4 - Rinumerazione ID documenti (sui DB clone)

Ogni script rinumera un tipo di ID con offset diversi per database per evitare collisioni.

| #    | Tipo   | Azione                                             | gpx         | furma    | bondife |
| ---- | ------ | -------------------------------------------------- | ----------- | -------- | ------- |
| 4.1  | SCRIPT | `05RinumeraIdAcquisti.ps1` - PurchaseDocId         | +100000     | +200000  | +300000 |
| 4.2  | SCRIPT | `06RinumeraIdOrdiniFornitori.ps1` - PurchaseOrdId  | +100000     | +200000  | +300000 |
| 4.3  | SCRIPT | `07RinumeraIdOfferteFornitori.ps1` - SuppQuotaId   | +100000     | +200000  | +300000 |
| 4.4  | SCRIPT | `08RinumeraIdOfferteClienti.ps1` - CustQuotaId     | +100000     | +200000  | +300000 |
| 4.5  | SCRIPT | `09RinumeraIdOrdiniClienti.ps1` - SaleOrdId        | **escluso** | +200000  | +300000 |
| 4.6  | SCRIPT | `10RinumeraEntryId.ps1` - EntryId                  | +1000000    | +500000  | +600000 |
| 4.7  | SCRIPT | `11RinumeraImQuotations.ps1` - QuotationRequestId  | +400000     | +500000  | +600000 |
| 4.8  | SCRIPT | `12RinumeraImRapportini.ps1` - WorkingReportId     | +400000     | +1000000 | +600000 |
| 4.9  | SCRIPT | `13RinumeraLibretti.ps1` - MeasuresBookId          | +100000     | +200000  | +300000 |
| 4.10 | SCRIPT | `14RinumeraAnalisiPreventivo.ps1` - JobQuotationId | +100000     | +200000  | +300000 |
| 4.11 | SCRIPT | `15RinumeraSal.ps1` - WPRId                        | +100000     | +200000  | +300000 |
| 4.12 | SCRIPT | `27rinumerasaledoc.ps1` - SaleDocId                | +400000     | +200000  | +300000 |

> **NOTA (correzione 3C)**: gpxnetclone e' stato escluso dallo script 09 perche gli ordini clienti GPX vengono importati da gpxnet originale (non dal clone), quindi non devono essere rinumerati.

---

## FASE 5 - Cross-references (sui DB clone)

Aggiorna i riferimenti incrociati nei DB clone per riflettere i nuovi ID.

| #   | Tipo   | Azione                                                                                                             |
| --- | ------ | ------------------------------------------------------------------------------------------------------------------ |
| 5.1 | SCRIPT | `18CreaMappaRiferimenti.ps1` - crea TAG_DocumentTypesCr (~85 tipi documento)                                       |
| 5.2 | SCRIPT | `19AggiornaCRossReference.ps1` - aggiorna OriginDocID/DerivedDocID in MA_CrossReferences e MA_CrossReferencesNotes |
| 5.3 | SCRIPT | `19BisRinumerasubid.ps1` - rinumera SubID (con WHERE > 0)                                                          |
| 5.4 | SCRIPT | `20AggCrossreferenceCommesse.ps1` - aggiorna CrossRef per commesse (offset numerici IM_JobId)                      |
| 5.5 | SCRIPT | `22PostTrasfUpdateCrossReference.ps1` - aggiorna CrossRef per commesse duplicate (vecchiocodice → nuovocodice)     |
| 5.6 | SCRIPT | `21ExportCrossReference.ps1` - esporta CrossRef in MM4HelperDb                                                     |
| 5.7 | SCRIPT | `22Aggiornacausaliedeposuorigini.ps1` - aggiorna causali e depositi di origine                                     |

---

## FASE 6 - Creazione depositi e causali

> **NOTA**: Questa fase puo essere eseguita in qualsiasi momento dopo la clonazione (Fase 1) e prima del trasferimento (Fase 8). Non ha dipendenze con le fasi di rinumerazione (3, 4) ne con i cross-references (5), perche queste operano esclusivamente su ID numerici. Lo script 5.6 si limita a rinominare valori varchar nelle tabelle dei clone e non richiede che depositi/causali esistano come entita configurate.

| #   | Tipo    | Azione                                                   |
| --- | ------- | -------------------------------------------------------- |
| 6.1 | MANUALE | ***Creare depositi e causali manualmente su VEDMaster*** |
|     |         | Creare deposito 01FRM su furmanetclone                   |
|     |         | Creare deposito 01MPFRM su furmanetclone                 |
|     |         | Creare deposito COLLBDF su vedbondifeclone               |
|     |         | Creare deposito SANNABDF su vedbondifeclone              |
| 6.2 | MANUALE | Creare causale MOV-DEPF su furmanetclone                 |
|     |         | Creare causale ACQ-FRM su furmanetclone                  |
|     |         | Creare causale MID-FRM su furmanetclone                  |
|     |         | Creare causale MOV-LIBF su furmanetclone                 |
|     |         | Creare causale Mud-FRM su furmanetclone                  |
|     |         |                                                          |
|     |         | Creare causale VEN-O-B su VEDBONDIFECLONE                |
|     |         | Creare causale MOV-DEPB su bondifeclone                  |

**STOP** - Verificare che depositi e causali siano stati creati prima di proseguire con il trasferimento (Fase 8).

---

## FASE 7 - Preparazione VEDMaster (pre-trasferimento)

### 7.0 - Rinumerazione SaleDocId su VEDMaster (NUOVO)

> **IMPORTANTE**: Questo script risolve alla radice il problema dei riferimenti incrociati tra fatture vedcontab e documenti dei clone. Le fatture su VEDMaster (da vedcontab) vengono rinumerate per avere lo stesso SaleDocId che hanno nei DB clone. In questo modo i cross-references importati dai clone saranno corretti **by design**, senza bisogno di fix post-trasferimento.

| #     | Tipo   | Azione                                                                                                  |
| ----- | ------ | ------------------------------------------------------------------------------------------------------- |
| 7.0.1 | SCRIPT | `28RinumeraSaleDocVedmaster.ps1` - rinumera SaleDocId su VEDMaster per allinearli ai clone (vedi sotto) |

**Script 28 - Logica:**
1. **Fase 0**: Diagnostica - conta documenti, distribuzione per tipo
2. **Fase 1**: Crea `TAG_RenumberMapping` con match per chiave business (DocNo + DocumentDate + CustSupp + DocumentType) tra VEDMaster e ogni clone. Include controlli per collisioni, ambiguita e documenti non matchati
3. **Fase 2**: Disabilita FK constraints su MA_SaleDoc
4. **Fase 3**: Rinumera SaleDocId in MA_SaleDoc + 17 child tables (stessa lista di `27rinumerasaledoc`)
5. **Fase 4**: Aggiorna MA_CrossReferences e MA_CrossReferencesNotes gia presenti su VEDMaster (da vedcontab) con approccio DELETE+INSERT per evitare violazioni PK
6. **Fase 5**: Riabilita FK constraints
7. **Fase 6**: Verifica finale (distribuzione ID per range, orfani residui, campioni)

**Prerequisiti**: Le fatture devono essere gia state importate su VEDMaster da vedcontab (procedura esterna).

**Conseguenza**: Lo script `23PostTrasfAggiornariffatturevedmaster.ps1` (Fase 9.1 / Fase 11) **non e piu necessario**. I cross-references importati dai clone punteranno direttamente agli ID corretti.

**Documenti non matchati**: Le fatture su VEDMaster senza corrispondenza nei clone restano con l'ID originale. Questo e sicuro perche gli ID originali vedcontab sono < 200.000, mentre i clone usano offset da 200.000 in su (nessuna collisione).

### 7.1 - Pulizia caratteri speciali

Query SQL da eseguire su SSMS collegati a VEDMaster.

| #     | Tipo | Azione                                   |
| ----- | ---- | ---------------------------------------- |
| 7.1.1 | SQL  | Pulizia carattere CHAR(31) dalle tabelle |

```sql
UPDATE IM_JobsNotes SET Note = REPLACE(CAST(Note AS VARCHAR(MAX)), CHAR(31), '')
WHERE CAST(Note AS VARCHAR(MAX)) LIKE '%' + CHAR(31) + '%'

UPDATE ma_jobs SET Description = REPLACE(CAST(Description AS VARCHAR(MAX)), CHAR(31), '')
WHERE CAST(Description AS VARCHAR(MAX)) LIKE '%' + CHAR(31) + '%'

UPDATE IM_WorkingReportsDetails SET Note = REPLACE(CAST(Note AS VARCHAR(MAX)), CHAR(31), '')
WHERE CAST(Note AS VARCHAR(MAX)) LIKE '%' + CHAR(31) + '%'
```

---

## FASE 8 - Trasferimento dati su VEDMaster

Per ogni sottoinsieme: prima eseguire eventuali script SQL di fix su SSMS, poi lo script PowerShell di migrazione.

### 8.1 - Commesse

| #     | Tipo   | Azione                                                                     |
| ----- | ------ | -------------------------------------------------------------------------- |
| 8.1.1 | SCRIPT | Cartella `MigrazioneSottoInsiemeComesse` → eseguire `Migrate-JobsData.ps1` |

### 8.2 - Perfetto (parte 1)

| #     | Tipo   | Azione                                                                                    |
| ----- | ------ | ----------------------------------------------------------------------------------------- |
| 8.2.1 | SQL    | Cartella `MigrazioneSottoinsiemePerfetto01` → eseguire su SSMS `Fix-Perfetto-Lengths.sql` |
| 8.2.2 | SCRIPT | Eseguire `Migrate-PerfettoData.ps1`                                                       |

### 8.3 - Perfetto (parte 2)

| #     | Tipo   | Azione                                                                              |
| ----- | ------ | ----------------------------------------------------------------------------------- |
| 8.3.1 | SQL    | Cartella `MigrazioneSottoinsiemePerfetto02` → eseguire su SSMS `Fix-IM-Lengths.sql` |
| 8.3.2 | SCRIPT | Eseguire `Migrate-ItemsData.ps1`                                                    |

### 8.4 - Cross-references

| #     | Tipo   | Azione                                                                                        |
| ----- | ------ | --------------------------------------------------------------------------------------------- |
| 8.4.1 | SCRIPT | Cartella `MigrazioneSottoinsiemeCrossReferences` → eseguire `Migrate-CrossReferencesData.ps1` |

### 8.5 - Acquisti

| #     | Tipo   | Azione                                                                          |
| ----- | ------ | ------------------------------------------------------------------------------- |
| 8.5.1 | SCRIPT | Cartella `MigrazioneSottoinsiemeAcquisti` → eseguire `Migrate-PurchaseData.ps1` |

### 8.6 - Ordini fornitore

| #     | Tipo   | Azione                                                                                                     |
| ----- | ------ | ---------------------------------------------------------------------------------------------------------- |
| 8.6.1 | SQL    | Cartella `MigrazioneSottoinsiemeOrdiniFornitore` → eseguire su SSMS `Increase-DescriptionColumnLength.sql` |
| 8.6.2 | SCRIPT | Eseguire `Migrate-PurchaseOrdData.ps1`                                                                     |

### 8.7 - Offerte fornitore

| #     | Tipo   | Azione                                                                                            |
| ----- | ------ | ------------------------------------------------------------------------------------------------- |
| 8.7.1 | SQL    | Cartella `MigrazioneSottoinsiemeOfferteFornitore` → eseguire su SSMS `Fix-SuppQuotas-Lengths.sql` |
| 8.7.2 | SCRIPT | Eseguire `Migrate-SuppQuotasData.ps1`                                                             |

### 8.8 - Offerte cliente

| #     | Tipo   | Azione                                                                                          |
| ----- | ------ | ----------------------------------------------------------------------------------------------- |
| 8.8.1 | SQL    | Cartella `MigrazioneSottoinsiemeOfferteCliente` → eseguire su SSMS `Fix-CustQuotas-Lengths.sql` |
| 8.8.2 | SCRIPT | Eseguire `Migrate-CustQuotasData.ps1`                                                           |

### 8.9 - Ordini cliente

| #     | Tipo   | Azione                                                                                                            |
| ----- | ------ | ----------------------------------------------------------------------------------------------------------------- |
| 8.9.1 | SQL    | Cartella `MigrazioneSottoinsiemeOrdiniCliente` → eseguire su SSMS `Alter_Description_VEDMaster_MA_SaleOrdDetails` |
| 8.9.2 | SCRIPT | Eseguire `Migrate-SaleOrdData.ps1`                                                                                |

> **N.B.**: Nello script di migrazione le tabelle GPX vanno importate da **gpxnet** (NON da gpxnetclone) perche gli ordini clienti di GPX non devono essere rinumerati. Lo script e' gia configurato correttamente.

### 8.10 - Preparazione articoli (pulizia tabelle dipendenti)

| #      | Tipo | Azione                                           |
| ------ | ---- | ------------------------------------------------ |
| 8.10.1 | SQL  | Eseguire su SSMS le seguenti DELETE su VEDMaster |

```sql
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
```

### 8.11 - Articoli

| #      | Tipo   | Azione                                                                                          |
| ------ | ------ | ----------------------------------------------------------------------------------------------- |
| 8.11.1 | SQL    | Cartella `MigrazioneSottoinsiemeArticoli` → eseguire su SSMS `Fix-MA_Items-Description-280.sql` |
| 8.11.2 | SCRIPT | Eseguire `Migrate-ItemsData.ps1`                                                                |

### 8.12 - Magazzino

| #      | Tipo   | Azione                                                                        |
| ------ | ------ | ----------------------------------------------------------------------------- |
| 8.12.1 | SCRIPT | Cartella `MigrazioneSottoinsiemeMagazzino` → eseguire `Migrate-StockData.ps1` |

---

## FASE 9 - Post-trasferimento (su VEDMaster)

### 9.1 - ~~Aggiornamento riferimenti post-trasferimento~~ SOSTITUITO

> **NOTA**: Se si e eseguito lo script `28RinumeraSaleDocVedmaster.ps1` (Fase 7.0), questa fase **non e piu necessaria**. Gli ID fatture su VEDMaster sono gia allineati ai clone, quindi i cross-references importati dai clone sono corretti by design.
>
> Lo script `23PostTrasfAggiornariffatturevedmaster.ps1` (v4.0/v4.1) resta disponibile come **fallback** nel caso non si utilizzi lo script 28.

<details>
<summary>Dettaglio script 23 (riferimento storico)</summary>

| #     | Tipo   | Azione                                                                                                              |
| ----- | ------ | ------------------------------------------------------------------------------------------------------------------- |
| 9.1.1 | SCRIPT | `23PostTrasfAggiornariffatturevedmaster.ps1` v4.1 - approccio basato sui clone (vedi dettaglio sotto) |

**Script 23 v4.1 - Approccio basato sui clone:**

Le fatture su VEDMaster sono state importate da **procedura esterna** (non da Mago4), quindi Mago4 non ha trasferito i relativi cross-references. I DB clone hanno i cross-references corretti post-rinumerazione.

Lo script esegue:

1. **Fase 0**: Diagnostica rapida stato cross-references (conteggio orfani, catene)
2. **Fase 1**: Crea TAG_SaleDocMapping (clone → VEDMaster) per TUTTI i DocumentType, con match per DocNo+DocumentDate+CustSupp+DocumentType
3. **Fase 2**: Corregge DerivedDocID su cross-ref ESISTENTI su VEDMaster che hanno ancora ID clone (DELETE+INSERT con dedup ROW_NUMBER)
4. **Fase 3**: Corregge OriginDocID su cross-ref ESISTENTI su VEDMaster (stessa logica)
5. **Fase 4**: **Importa cross-references MANCANTI dai DB clone** - legge TUTTI i cross-ref SaleDoc/SaleOrd dai 3 clone, mappa SaleDocId tramite TAG_SaleDocMapping, inserisce su VEDMaster quelli che non esistono ancora (NOT EXISTS + dedup tra clone). SaleOrdId (27066372) usato as-is (preservato nel trasferimento).
6. **Fase 5**: Verifica finale con confronto prima/dopo (orfani, catene Ordine→Fattura, campione)

</details>

### 9.2 - Colonne aggiuntive

| #     | Tipo    | Azione                                                                           |
| ----- | ------- | -------------------------------------------------------------------------------- |
| 9.2.1 | MANUALE | Su VEDMaster, aggiungere alla tabella `IM_SpecificationsItems` i seguenti campi: |

- `k` (float, NULL)
- `idSal` (nchar(10), NULL)
- `Riga` (float, NULL)

### 9.3 - Aggiornamento numeratori

| #     | Tipo   | Azione                                                       |
| ----- | ------ | ------------------------------------------------------------ |
| 9.3.1 | SCRIPT | `24OpreazioniIds.ps1` - aggiorna MA_IDNumbers con i nuovi ID |

### 9.4 - Dati GPX RAM

| #     | Tipo    | Azione                                                                                         |
| ----- | ------- | ---------------------------------------------------------------------------------------------- |
| 9.4.1 | MANUALE | Controllare i campi chiave delle tabelle gpx_ (potrebbero essere mancanti)                     |
| 9.4.2 | MANUALE | Su VEDMaster: inserire chiave su `gpx_parametri` campo chiave `Codice`                         |
| 9.4.3 | MANUALE | Su VEDMaster: inserire chiave multipla su `gpx_parametririghe` campi `Codice` e `Deposito`     |
| 9.4.4 | SQL     | Cartella `MigrazioneSottoinsiemeGpx` → eseguire su SSMS `Fix-gpx_righeram-Descrizione-280.sql` |
| 9.4.5 | SCRIPT  | Eseguire `Migrate-GpxData.ps1`                                                                 |
| 9.4.6 | SQL     | Aggiornare riferimenti ordini clienti alle RAM di GPX:                                         |

```sql
UPDATE d
SET d.SaleDocId = c.SaleOrdId
FROM VEDMaster.dbo.gpx_saledocram d
INNER JOIN gpxnet.dbo.gpx_saledocram a ON d.IdRam = a.IdRam
INNER JOIN gpxnet.dbo.MA_SaleOrd b ON a.SaleDocId = b.SaleOrdId
INNER JOIN VEDMaster.dbo.MA_SaleOrd c ON c.InternalOrdNo = b.InternalOrdNo
```

### 9.5 - Employees

| #     | Tipo   | Azione                                                                        |
| ----- | ------ | ----------------------------------------------------------------------------- |
| 9.5.1 | SCRIPT | Cartella `MigrazioneSottoinsiemeEmployees` → eseguire `Migrate-ItemsData.ps1` |

### 9.6 - Viste

| #     | Tipo   | Azione                                                                                                |
| ----- | ------ | ----------------------------------------------------------------------------------------------------- |
| 9.6.1 | SCRIPT | `25trasferisciviews.ps1` - trasferisce le viste per i report (ignora errori su viste non compatibili) |

### 9.7 - Multistorages

| #     | Tipo   | Azione                                                                            |
| ----- | ------ | --------------------------------------------------------------------------------- |
| 9.7.1 | SCRIPT | Cartella `MigrazioneSottoinsiemeMultistorages` → eseguire `Migrate-ItemsData.ps1` |

### 9.8 - Lotti

| #     | Tipo   | Azione                                                                   |
| ----- | ------ | ------------------------------------------------------------------------ |
| 9.8.1 | SCRIPT | Cartella `MigrazioneSottoinsiemeLotti` → eseguire `Migrate-LotsData.ps1` |

### 9.9 - DDT

| #     | Tipo   | Azione                                                                                         |
| ----- | ------ | ---------------------------------------------------------------------------------------------- |
| 9.9.1 | SQL    | Cartella `MigrazioneSottoinsiemeDdt` → eseguire su SSMS `Fix-MA_SaleDocDetail-Description-512` |
| 9.9.2 | SCRIPT | Eseguire `Migrate-ItemsData.ps1`                                                               |

### 9.10 - Fix CrossReferences Fatture

| #      | Tipo   | Azione                                                                               |
| ------ | ------ | ------------------------------------------------------------------------------------ |
| 9.10.1 | SCRIPT | `29a_CreaMA_CrossReferencesOrigin.ps1` - backup MA_CrossReferences (Origin + Backup) |
| 9.10.2 | SCRIPT | `29CorrettivoFixDerivedDocIdFatture.ps1` - fix DerivedDocID Fattura->DocContabile     |

> **Problema**: I cross-references Fattura Immediata (27066387) -> Documento Contabile Emesso (27066419) hanno DerivedDocID errato su VEDMaster. I movimenti contabili mantengono gli ID originali di vedcontab (non rinumerati), ma i cross-references puntano a ID sbagliati.
> **Soluzione**: Lo script 29 mappa le fatture VEDMaster -> vedcontab tramite business key e copia il DerivedDocID corretto da vedcontab.

### 9.11 - Pulizia e fix CrossReferences destinazioni

| #      | Tipo   | Azione                                                                                           |
| ------ | ------ | ------------------------------------------------------------------------------------------------ |
| 9.11.1 | SCRIPT | `30EliminaDestinazioniPartiteCliente.ps1` - elimina CrossRef Fattura->Partita Cliente            |
| 9.11.2 | SCRIPT | `31FixOriginDocIdCrossReferences.ps1` - fix OriginDocID orfani Fattura->DocContabile             |

> **Script 30 - Problema**: MA_CrossReferences contiene record con OriginDocType=27066387 (Fattura Immediata) e DerivedDocType=27066423 (Partita Cliente). Questi sono errati perche sono i documenti contabili a generare le partite, non le fatture direttamente.
> **Soluzione**: Elimina tutti i record con quella combinazione Origin/Derived DocType.

> **Script 31 - Problema**: Dopo la rinumerazione SaleDocId, alcuni cross-references Fattura (27066387) -> DocContabile (27066419) hanno ancora il vecchio OriginDocID di vedcontab (es. 141874) invece del nuovo ID VEDMaster (es. 535618). Questo perche il record con il vecchio ID non e stato aggiornato durante la rinumerazione.
> **Soluzione**: Lo script mappa il vecchio ID al nuovo tramite business key (DocNo + DocumentDate + CustSupp + DocumentType) via vedcontab -> VEDMaster. Gestisce anche i conflitti PK: se il nuovo ID esiste gia, elimina il record orfano ridondante prima di aggiornare i rimanenti.

### 9.12 - Importazione dati anagrafici aggiuntivi

| #      | Tipo   | Azione                                                                                                    |
| ------ | ------ | --------------------------------------------------------------------------------------------------------- |
| 9.12.1 | SCRIPT | `32ImportaCustSuppBranches.ps1` - importa sedi clienti/fornitori (MA_CustSuppBranches) dai clone          |

> Lo script importa i record di `MA_CustSuppBranches` dai 3 DB clone su VEDMaster senza cancellare i dati esistenti (vedcontab). Gestisce automaticamente:
> - **Duplicati PK**: record gia presenti su VEDMaster vengono saltati (NOT EXISTS su chiave CustSuppType + CustSupp + Branch)
> - **FK mancanti**: record con CustSupp/CustSuppType non presenti in MA_CustSupp vengono saltati e segnalati con campione
> - **Errori**: se un clone fallisce, lo segnala e continua con il successivo

---

## FASE 10 - Workaround RAM GPX

Necessario per evitare collisioni ID tra ordini GPX esistenti e nuovi ordini.

| #    | Tipo | Azione                                     |
| ---- | ---- | ------------------------------------------ |
| 10.1 | SQL  | Impostare il numeratore ordini in negativo |

```sql
-- Verificare l'ultimo SaleOrdId su gpxnet
SELECT MAX(SaleOrdId) FROM gpxnet.dbo.MA_SaleOrd

-- Impostare LastId al valore negativo corrispondente (es. se max = 6335)
UPDATE VEDMaster.dbo.MA_IDNumbers SET LastId = -6335 WHERE CodeType = 3801098
```

> **ATTENZIONE**: Il valore 6335 e' un esempio. Va aggiornato al momento verificando l'ultimo ID ordine cliente su gpxnet. Da questo momento tutti i nuovi ordini cliente avranno ID negativo. Per gli ordini GPX senza RAM generata sara necessario ricaricarli. Preferibilmente, prima della migrazione tutti gli ordini devono avere le RAM generate.

| #    | Tipo    | Azione                                                                                        |
| ---- | ------- | --------------------------------------------------------------------------------------------- |
| 10.2 | MANUALE | Creare su VEDMaster nella tabella `gpx_saledocram` la chiave multipla su `SaleDocId`, `IdRam` |

---

## FASE 11 - ~~Fix cross-references post-trasferimento~~ SOSTITUITA

> **NOTA**: La Fase 11 e ora **completamente sostituita** dallo script `28RinumeraSaleDocVedmaster.ps1` (Fase 7.0).
> Rinumerando gli ID fatture su VEDMaster PRIMA del trasferimento, i cross-references dai clone sono corretti by design.
> Lo script 23 e le query manuali sotto sono mantenuti come **riferimento storico** ma **non devono piu essere eseguiti**.

<details>
<summary>Riferimento storico (non eseguire)</summary>

### 11.1 - Script 23

| #      | Tipo   | Azione                                                                                                |
| ------ | ------ | ----------------------------------------------------------------------------------------------------- |
| 11.1.1 | SCRIPT | `23PostTrasfAggiornariffatturevedmaster.ps1` v4.1 - vedi dettaglio in Fase 9.1 |

> **Evoluzione versioni**:
> - v1.0: gestiva solo Fattura Accompagnatoria (27066385/3407874)
> - v2.0: esteso a TUTTI i tipi SaleDoc + SaleOrd, aggiunta pulizia customer mismatch
> - v3.1: aggiunta diagnostica dettagliata catena Ordine→DDT→Fattura (fasi 5a-5g)
> - v4.0: approccio semplificato - legge cross-ref corretti dai clone e li importa su VEDMaster
> - **v4.1**: fallback ID diretto per documenti vedcontab non rinumerati
> - **SOSTITUITO**: dallo script 28 che risolve il problema alla radice

</details>

---

## Riepilogo correzioni applicate

| Correzione    | Script/File                                    | Descrizione                                |
| ------------- | ---------------------------------------------- | ------------------------------------------ |
| Script 27     | `27rinumerasaledoc/02rinumeraIdSaledocCrs.ps1` | CASE mapping per tutti i 17 tipi SaleDoc   |
| Script 18     | `18CreaMappaRiferimenti.ps1`                   | Espanso da 19 a ~85 tipi documento         |
| Script 19Bis  | `19BisRinumerasubid.ps1`                       | WHERE > 0 + update separati per campo      |
| Script 19     | `19AggiornaCRossReference.ps1`                 | Aggiunto MA_CrossReferencesNotes           |
| Script 22Post | `22PostTrasfUpdateCrossReference.ps1`          | +DerivedDocID +gpxnetclone +filtro DocType  |
| Bug 1B        | `23PostTrasfAggiornariffatturevedmaster.ps1`   | 27066387 → 27066385                        |
| Bug 1B        | Query manuali Fase 11                          | 27066387 → 27066385                        |
| Bug 3C        | `09rinumeraIdordiniclienti/*` (4 file)         | gpxnetclone escluso                        |
| Bug 3C        | Workaround -100000                             | Rimosso (non piu necessario)               |
| Script 23 v4  | `23PostTrasfAggiornariffatturevedmaster.ps1`   | Riscrittura completa: importa cross-ref dai clone anziche tentare fix su VEDMaster |
| **Script 28** | **`28RinumeraSaleDocVedmaster.ps1`**           | **Rinumera SaleDocId su VEDMaster per allinearli ai clone. Rende superfluo lo script 23** |
| Script 29a    | `29a_CreaMA_CrossReferencesOrigin.ps1`         | Backup MA_CrossReferences (Origin + Backup)                                               |
| Script 29     | `29CorrettivoFixDerivedDocIdFatture.ps1`       | Fix DerivedDocID Fattura->DocContabile da vedcontab                                       |
| **Script 30** | **`30EliminaDestinazioniPartiteCliente.ps1`**  | **Elimina CrossRef errati Fattura->Partita Cliente**                                      |
| **Script 31** | **`31FixOriginDocIdCrossReferences.ps1`**      | **Fix OriginDocID orfani (vecchio vedcontab->nuovo VEDMaster) con gestione duplicati PK** |
| Script 32     | `32ImportaCustSuppBranches.ps1`                | Importa MA_CustSuppBranches dai clone con gestione duplicati PK e FK mancanti             |

## Bug ancora aperti / risolti

| Bug | Descrizione                                                   | Stato |
| --- | ------------------------------------------------------------- | ----- |
| 2.2 | ~~Mismatch DocumentType/DocType nello script 23~~             | **RISOLTO** v4.0: script opera su TUTTI i 19 ReferenceCode SaleDoc, non piu su singolo tipo |
| 2.3 | ~~SaleDocMapping gestisce solo DocumentType 3407874~~         | **RISOLTO** v4.0: TAG_SaleDocMapping creata per TUTTI i DocumentType |
| 3.1 | Script `03replaceoldcodes.ps1` da inserire nella progressione | **RISOLTO**: aggiunto in questo documento al punto 3.3 |
| 4.4 | ~~Script 23 opera solo su un DocType~~                        | **RISOLTO** v4.0: gestisce tutti i tipi SaleDoc (Origin+Derived) + importa dai clone |
