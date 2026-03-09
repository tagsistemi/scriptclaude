# Analisi Migrazione DMS - Piano Operativo

## 1. Contesto

L'ERP Mago.net utilizza database DMS separati per memorizzare gli allegati ai documenti ERP. Ogni azienda ha il proprio DB DMS:

| Database DMS | Azienda | Clone ERP | Ruolo |
|---|---|---|---|
| vedcontabdms | VedContab | vedcontab | **BASE** (offset 0) |
| gpxnetdms | GPXNet | gpxnetclone | Clone (da rinumerare) |
| furmanetdms | FurmaNet | furmanetclone | Clone (da rinumerare) |
| vedbondifedms | VEDBondife | vedbondifeclone | Clone (da rinumerare) |

| VedMasterDMS | VedMaster (unificato) | - | **5a sorgente** (125 allegati post-migrazione) |

**Obiettivo**: Unificare i 4 DB DMS originali + i 125 allegati di VedMasterDMS in un nuovo database `vedDMS`.

**Nota**: VedMasterDMS contiene 125 allegati inseriti dopo la migrazione ERP. Non puo essere usato come target, diventa la 5a sorgente. Il database `vedDMS` viene creato manualmente dall'utente (clone di VedMasterDMS per schema, poi svuotato).

---

## 2. Schema DMS - Catena FK

```
DMS_Collector
  +-- DMS_Collection
       +-- DMS_CollectionsFields --> DMS_Field --> DMS_FieldProperties
       +-- DMS_ArchivedDocument
       |    +-- DMS_ArchivedDocContent      (contenuto binario)
       |    +-- DMS_ArchivedDocTextContent
       |    +-- DMS_ArchivedDocSearchIndexes --> DMS_SearchFieldIndexes
       +-- DMS_Attachment
       |    +-- DMS_AttachmentSearchIndexes  --> DMS_SearchFieldIndexes
       +-- DMS_SOSEnvelope
            +-- DMS_SOSDocument --> DMS_Attachment

DMS_ErpDocument
  +-- DMS_Attachment
  +-- DMS_ErpDocBarcodes
  +-- DMS_IndexesSynchronization
```

---

## 3. Volume dati censiti

### 3.1 Record per tabella

| Tabella | vedcontab | gpxnet | furmanet | vedbondife | TOTALE |
|---|---:|---:|---:|---:|---:|
| DMS_ArchivedDocument | 153,453 | 118,472 | 38,570 | 14,660 | **325,155** |
| DMS_ArchivedDocContent | 153,452 | 118,468 | 38,557 | 14,659 | **325,136** |
| DMS_ArchivedDocTextContent | 4,744 | 598 | 3,768 | 94 | 9,204 |
| DMS_ArchivedDocSearchIndexes | 154,055 | 153,367 | 42,076 | 16,116 | 365,614 |
| DMS_ErpDocument | 144,921 | 58,757 | 19,067 | 6,025 | **228,770** |
| DMS_Attachment | 151,991 | 123,876 | 38,495 | 14,596 | **328,958** |
| DMS_AttachmentSearchIndexes | 1,344,778 | 664,088 | 226,257 | 78,791 | 2,313,914 |
| DMS_SearchFieldIndexes | 388,700 | 204,644 | 75,191 | 28,528 | **697,063** |
| DMS_ErpDocBarcodes | 0 | 0 | 16 | 0 | 16 |

### 3.2 Dimensione binari

| Database | Documenti | Dimensione | Media | Max singolo |
|---|---:|---:|---:|---:|
| vedcontabdms | 153,452 | **79 GB** | 539 KB | 200 MB |
| gpxnetdms | 118,468 | **43 GB** | 380 KB | 124 MB |
| furmanetdms | 38,557 | **16.4 GB** | 446 KB | 192 MB |
| vedbondifedms | 14,659 | **8.5 GB** | 605 KB | 132 MB |
| **TOTALE** | **325,136** | **146.8 GB** | | |

### 3.3 Tabelle vuote (SKIP)

Le seguenti tabelle sono vuote su tutti e 4 i database - **non richiedono migrazione**:
- DMS_SOSDocument
- DMS_SOSEnvelope
- DMS_IndexesSynchronization
- DMS_DocumentToArchive

### 3.4 Tabelle di configurazione (IDENTICHE)

Le seguenti tabelle sono identiche tra i 4 database - **copia singola da vedcontabdms**:
- DMS_Collection (98 record)
- DMS_Collector (31 record)
- DMS_CollectionsFields
- DMS_Field (21-34 record)
- DMS_FieldProperties
- DMS_Settings (1-2 record)
- DMS_SOSConfiguration
- DMS_TextExtensions
- TB_DBMark

**Nota**: furmanet e vedbondife hanno qualche Field in piu (30-34 vs 21). Potrebbe servire un MERGE invece di una copia secca, oppure verificare che i Field extra non siano necessari su VedMaster.

---

## 4. MAX ID e Offset per ID interni DMS

### 4.1 MAX ID attuali

| ID | vedcontab | gpxnet | furmanet | vedbondife | MAX globale |
|---|---:|---:|---:|---:|---:|
| ArchivedDocID | 154,788 | 123,709 | 39,588 | 14,702 | **154,788** |
| ErpDocumentID | 144,986 | 58,788 | 19,086 | 6,028 | **144,986** |
| AttachmentID | 155,262 | 129,654 | 40,492 | 14,999 | **155,262** |
| SearchIndexID | 391,628 | 211,337 | 77,378 | 29,542 | **391,628** |

### 4.2 Offset per ID interni DMS

vedcontabdms e' la base (offset 0). I 3 cloni DMS + VedMasterDMS ricevono offset per evitare collisioni:

| ID | gpxnetdms | furmanetdms | vedbondifedms | VedMasterDMS |
|---|---:|---:|---:|---:|
| ArchivedDocID | +200,000 | +400,000 | +600,000 | +800,000 |
| ErpDocumentID | +200,000 | +400,000 | +600,000 | +800,000 |
| AttachmentID | +200,000 | +400,000 | +600,000 | +800,000 |
| SearchIndexID | +400,000 | +800,000 | +1,200,000 | +1,600,000 |

**Nota**: EnvelopeID, CollectionID, CollectorID non richiedono offset (EnvelopeID=0 ovunque, Collection/Collector sono config identiche).

**VedMasterDMS**: Ha 125 allegati post-migrazione. I suoi ID interni vengono rinumerati con offset +800k/+1.6M, ma il PrimaryKeyValue **non** viene rimappato (gia corretto, gli allegati sono stati inseriti dopo la migrazione ERP su VedMaster).

---

## 5. PrimaryKeyValue - Rimappatura ID ERP

### 5.1 Il campo DMS_ErpDocument.PrimaryKeyValue

Contiene riferimenti agli ID dei documenti ERP nel formato `IdType:valore;` (es. `SaleDocId:81565;`).
Questi ID sono stati rinumerati durante la migrazione ERP (fasi 3-4) con offset diversi per tipo e per database.

### 5.2 Mappa offset ERP per IdType (da TAG_CrMaps)

Offset verificati al 100% consistenti (nessuna anomalia):

| IdType | Record totali | gpxnet | furmanet | vedbondife | Note |
|---|---:|---:|---:|---:|---|
| SaleDocId | 71,960 | +400,000 | +200,000 | +300,000 | Tipo piu numeroso |
| JournalEntryId | 111,566 | - | - | - | Solo vedcontab (base), nessun offset |
| PurchaseOrdId | 21,605 | +100,000 | +200,000 | +300,000 | |
| CustQuotaId | 9,214 | +100,000 | - | +300,000 | Solo gpxnet e vedbondife |
| SaleOrdId | 6,594 | **nessuno** | +200,000 | +300,000 | gpxnet ESCLUSO dalla rinumerazione |
| Item | 5,516 | - | - | - | Codice stringa, no remap |
| SuppQuotaId | 746 | +100,000 | +200,000 | +300,000 | |
| Job | 710 | - | - | - | Codice stringa, gia nella forma finale |
| JobQuotationId | 354 | - | +200,000 | +300,000 | Solo furmanet e vedbondife |
| WorkingReportId | 165 | +400,000 | +1,000,000 | +600,000 | Offset molto diversi tra DB |
| MeasuresBookId | 155 | - | +200,000 | +300,000 | Solo furmanet e vedbondife |
| EntryId | 8 | +1,000,000 | +500,000 | +600,000 | Pochi record |
| Employee | 65 | - | - | - | Codice stringa, no remap |
| FeeId | 56 | - | - | - | Solo vedcontab (base) |
| QuotationRequestId | 31 | - | +500,000 | +600,000 | Solo furmanet e vedbondife |
| PurchaseDocId | 10 | +100,000 | +200,000 | +300,000 | Pochi record |
| CustSuppType | 6 | - | - | - | Pattern multi-chiave stringa |
| IdRam | 4 | - | - | - | NON rinumerato, solo 4 record |
| PymtSchedId | 2 | - | - | - | Solo vedcontab (base) |
| PurchaseRequestId | 1 | - | +500,000 | - | Solo 1 record su furmanet |
| WPRId | 0 (DMS) | - | +200,000 | +300,000 | Nessun record DMS, solo TAG_CrMaps |
| CompanyId | 1 | - | - | - | Valore fisso |
| Specification | 1 | - | - | - | Codice stringa |

### 5.3 Casi speciali

**SaleOrdId su gpxnet**: Lo script `09rinumeraIdordiniclienti` **esclude esplicitamente gpxnetclone** dalla rinumerazione SaleOrdId (commento: "gli ordini clienti GPX non devono essere rinumerati - importati da gpxnet originale"). Gli ordini cliente gpxnet sono gli **unici** confluiti su VedMaster (nessun ordine dalle altre aziende). I 6,594 record nel DMS mantengono gli ID originali. **Nessun offset da applicare.** I record con SaleOrdId negativo (bozze/temporanei) vanno gestiti separatamente: verificare se esistono nel DMS e se vanno preservati o scartati.

**Job codes**: I codici Job nel DMS sono gia nella forma finale (es. `12/00006CS`, `25/02775M2`). Nessun match trovato in MM4_MappaJobsCodes. **Nessuna rimappatura necessaria.**

**IdRam**: Solo 4 record su gpxnetdms. IdRam **non fu mai rinumerato** nella migrazione ERP. **Nessun offset da applicare.**

### 5.4 Tipi che NON richiedono rimappatura

| IdType | Motivo |
|---|---|
| JournalEntryId | Solo vedcontab (base, offset 0) |
| PymtSchedId | Solo vedcontab (base) |
| FeeId | Solo vedcontab (base) |
| CompanyId | Valore fisso (1 record) |
| Specification | Codice stringa (1 record) |
| Item | Codice stringa articolo |
| Employee | Codice stringa dipendente |
| CustSuppType | Pattern multi-chiave stringa |
| Job | Codice stringa, gia nella forma finale |
| IdRam | Non rinumerato |
| SaleOrdId (gpxnet) | Escluso dalla rinumerazione |

---

## 6. Piano operativo

### FASE 0 - Preparazione

1. Creare i 4 cloni DMS per lavorare in sicurezza (script `03_ClonaDatabaseDMS.ps1`):
   - vedcontabdms → vedcontabdmsclone
   - gpxnetdms → gpxnetdmsclone
   - furmanetdms → furmanetdmsclone
   - vedbondifedms → vedbondifedmsclone
2. Creare manualmente il database target `vedDMS` (clone di VedMasterDMS per schema, poi svuotato)

### FASE 1 - Aggiornamento PrimaryKeyValue sui cloni DMS

Per ogni clone DMS (non vedcontab che e' la base):
1. Parsare `DMS_ErpDocument.PrimaryKeyValue` per estrarre IdType e valore numerico
2. Applicare l'offset corretto in base alla mappa della sezione 5.2
3. Riscrivere il PrimaryKeyValue aggiornato

**Operazione SQL tipo:**
```sql
-- Esempio: SaleDocId su gpxnetdmsclone, offset +400000
UPDATE DMS_ErpDocument
SET PrimaryKeyValue = 'SaleDocId:' +
    CAST(
        CAST(SUBSTRING(PrimaryKeyValue,
            CHARINDEX(':', PrimaryKeyValue) + 1,
            CHARINDEX(';', PrimaryKeyValue) - CHARINDEX(':', PrimaryKeyValue) - 1
        ) AS INT) + 400000
    AS VARCHAR) + ';'
WHERE PrimaryKeyValue LIKE 'SaleDocId:%'
```

**Nota**: Per i pattern multi-chiave (es. `CustSuppType:00310000;CustSupp:023696;`) non applicare offset (sono codici stringa).

### FASE 2 - Rinumerazione ID interni DMS sui cloni e VedMasterDMS

Per i 3 cloni (gpxnetdmsclone, furmanetdmsclone, vedbondifedmsclone) + VedMasterDMS:

1. **Disabilitare tutte le FK**
2. **Rinumerare ArchivedDocID** (offset +200k/+400k/+600k) su:
   - DMS_ArchivedDocument (PK)
   - DMS_ArchivedDocContent (PK/FK)
   - DMS_ArchivedDocTextContent (PK/FK)
   - DMS_ArchivedDocSearchIndexes (FK)
   - DMS_Attachment (FK ArchivedDocID)
3. **Rinumerare ErpDocumentID** (offset +200k/+400k/+600k) su:
   - DMS_ErpDocument (PK)
   - DMS_Attachment (FK ErpDocumentID)
   - DMS_ErpDocBarcodes (FK)
   - DMS_IndexesSynchronization (FK) - vuota ma per sicurezza
4. **Rinumerare AttachmentID** (offset +200k/+400k/+600k) su:
   - DMS_Attachment (PK)
   - DMS_AttachmentSearchIndexes (FK)
   - DMS_SOSDocument (FK) - vuota ma per sicurezza
5. **Rinumerare SearchIndexID** (offset +400k/+800k/+1200k) su:
   - DMS_SearchFieldIndexes (PK)
   - DMS_ArchivedDocSearchIndexes (FK)
   - DMS_AttachmentSearchIndexes (FK)
6. **Riabilitare FK** e verificare integrita

### FASE 3 - Trasferimento in vedDMS

Ordine di inserimento (rispettando FK). **5 sorgenti**: vedcontabdmsclone, gpxnetdmsclone, furmanetdmsclone, vedbondifedmsclone, VedMasterDMS.

**Step 3.1 - Configurazione (solo da vedcontabdmsclone):**
1. DMS_Field
2. DMS_FieldProperties
3. DMS_Collector
4. DMS_Collection
5. DMS_CollectionsFields
6. DMS_TextExtensions
7. DMS_Settings
8. TB_DBMark

**Step 3.2 - Dati di ricerca (da tutti e 5):**
9. DMS_SearchFieldIndexes (con IDENTITY_INSERT ON)

**Step 3.3 - Documenti archiviati (da tutti e 5):**
10. DMS_ArchivedDocument (con IDENTITY_INSERT ON)
11. DMS_ArchivedDocContent (**attenzione: ~147 GB di binari**)
12. DMS_ArchivedDocTextContent
13. DMS_ArchivedDocSearchIndexes

**Step 3.4 - Documenti ERP e allegati (da tutti e 5):**
14. DMS_ErpDocument (con IDENTITY_INSERT ON)
15. DMS_Attachment (con IDENTITY_INSERT ON)
16. DMS_AttachmentSearchIndexes
17. DMS_ErpDocBarcodes (16 record da furmanet)

### FASE 4 - Verifiche post-migrazione

1. Conteggio record per tabella su vedDMS = somma delle 5 sorgenti
2. Verifica FK integrity (nessun orfano)
3. Verifica campione PrimaryKeyValue: i valori rimappati corrispondono ai documenti ERP su VedMaster
4. Aggiornare IDENTITY seed su vedDMS (DBCC CHECKIDENT)

---

## 7. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| 146.8 GB di binari da trasferire | Timeout, OOM | Trasferimento batch (1000 record alla volta) |
| Collisione ID residua | Dati corrotti | Offset calcolati con margine (+200k vs max 155k) |
| PrimaryKeyValue malformato | Errore UPDATE | WHERE con LIKE pattern + TRY/CATCH |
| DMS_Field divergenti tra DB | Field mancanti | MERGE/INSERT con ignore duplicati |
| Spazio disco VedMasterDMS | DB pieno | Pre-allocare ~200 GB |

---

## 8. Stima effort

| Fase | Script da creare | Complessita |
|---|---|---|
| FASE 0 | 1 (clone DB) | Bassa |
| FASE 1 | 1 (update PrimaryKeyValue) | Media - parsing stringhe |
| FASE 2 | 3 (disable FK + rinumera + enable FK) | Media - pattern collaudato |
| FASE 3 | 4 (config + search + docs + erp) | Alta - volume binari 146 GB |
| FASE 4 | 1 (verifiche) | Bassa |
| **TOTALE** | **~10 script** | |

---

## 9. Script di analisi gia creati

| Script | Scopo | Stato |
|---|---|---|
| `dms/00_CensimentoDMS.ps1` | Censimento MAX ID, conteggi, namespace | Completato |
| `dms/01_VerificaMappaDMS.ps1` | Verifica mappa IdType/DocumentType, binari | Completato |
| `dms/02_EstraiOffsetDMS.ps1` | Estrazione offset da TAG_CrMaps | Completato |
| `dms/03_ClonaDatabaseDMS.ps1` | FASE 0: Clona 4 DB DMS (vedDMS creato manualmente) | Pronto |
| `dms/04_AggiornaPrimaryKeyValue.ps1` | FASE 1: Aggiorna PrimaryKeyValue su 3 cloni | Pronto |
| `dms/05_RinumeraIdDMS.ps1` | FASE 2: Rinumera ID interni su 3 cloni + VedMasterDMS | Pronto |
| `dms/06_TrasferisciInVedMasterDMS.ps1` | FASE 3: Trasferisce 5 sorgenti in vedDMS | Pronto |
| `dms/07_VerificaPostMigrazione.ps1` | FASE 4: Verifiche integrita su vedDMS | Pronto |
| `dms/schemadbdms.sql` | Schema DB DMS di riferimento | Riferimento |
