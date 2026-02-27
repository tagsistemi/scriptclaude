# Progetto Migrazione VED - Report Finale

## La sfida impossibile che e' diventata realta'

### Il contesto

Unificare **4 database** ERP Mago.net — `vedcontab`, `gpxnet`, `furmanet`, `vedbondife` — in un'unica istanza `VEDMaster`, preservando l'integrita' referenziale di centinaia di migliaia di documenti contabili, fiscali e gestionali.

Un progetto che i tool standard di Mago.net non potevano affrontare: la migrazione nativa, pensata per singole aziende, avrebbe richiesto **tempi improponibili** e non avrebbe gestito la fusione simultanea di piu' database con ID sovrapposti.

La scelta obbligata: **bypassare completamente la migrazione standard** e costruire da zero un motore di migrazione SQL personalizzato.

---

## I numeri del progetto

| Metrica | Valore |
| --- | --- |
| Script PowerShell (.ps1) | **134** |
| Script SQL (.sql) | **169** |
| Totale file di progetto | **340** |
| Righe di codice PowerShell | **23.898** |
| Righe di codice SQL | **88.041** |
| **Totale righe di codice** | **111.939** |
| Fasi di orchestrazione | **10** |
| Sotto-fasi dettagliate | **50+** |
| Moduli di migrazione specializzati | **16** |
| Tabelle migrate direttamente | **160+** |
| Viste database ricreate | **145** |
| Tipi documento gestiti (Cross-References) | **85+** |
| Database sorgente | **4** |
| Database clone intermedi | **3** |

---

## Le 3 sfide principali

### 1. La riconciliazione dei riferimenti incrociati — La sfida piu' ardua

La tabella `MA_CrossReferences` e' il cuore pulsante di Mago.net: ogni fattura punta al suo documento contabile, ogni DDT alla sua fattura, ogni ordine al suo DDT. Una rete di riferimenti incrociati che collega **85 tipi di documento diversi** con milioni di combinazioni possibili.

Unificare 3 database significava far convivere 3 reti di riferimenti, ciascuna con i propri ID, in un'unica struttura coerente. Un singolo riferimento sbagliato avrebbe reso un documento inaccessibile o, peggio, lo avrebbe collegato al documento sbagliato.

**Cosa abbiamo fatto:**
- Creato una **mappa completa di 85+ tipi documento** con i relativi codici di riferimento
- Sviluppato script che aggiornano `OriginDocID` e `DerivedDocID` in modo consistente su tutti i clone
- Gestito i cross-references delle **commesse duplicate** (codici identici tra aziende diverse)
- Rinumerato i `SubID` mantenendo la coerenza delle catene documentali
- Costruito un sistema di **fix post-migrazione** multi-livello per i casi edge:
  - Fix dei `DerivedDocID` Fattura -> Documento Contabile tramite business key
  - Eliminazione dei riferimenti errati Fattura -> Partita Cliente
  - Correzione degli `OriginDocID` orfani con gestione dei conflitti di chiave primaria

Il risultato: ogni documento su VEDMaster punta esattamente dove deve puntare.

### 2. Migrazione SQL diretta — Bypassare l'impossibile

La migrazione standard di Mago.net non era un'opzione. Trasferire tabella per tabella attraverso l'interfaccia nativa avrebbe richiesto un tempo inaccettabile e non avrebbe supportato la fusione di piu' database.

**Cosa abbiamo fatto:**
- Sviluppato **16 moduli di migrazione specializzati**, uno per ogni sottoinsieme funzionale:
  - Commesse, Articoli, Acquisti, Ordini Fornitore, Offerte Fornitore
  - Offerte Cliente, Ordini Cliente, DDT, Magazzino, Lotti
  - Cross-References, Employees, Multistorages, GPX, Perfetto (2 parti)
- Ogni modulo:
  - Rileva automaticamente lo **schema della tabella** (colonne, chiavi primarie)
  - Calcola le **colonne in comune** tra sorgente e destinazione
  - Gestisce le **foreign key** (disabilita prima, riabilita dopo)
  - Usa `NOT EXISTS` per evitare duplicati
  - Verifica i conteggi prima e dopo
- Migrato **145 viste** per mantenere operativi tutti i report aziendali

### 3. Unificazione tramite offset di ID — L'architettura anti-collisione

Il problema fondamentale: 4 database con ID che partono tutti da 1. Un `SaleDocId = 100` esiste in tutti e 4 i database ma si riferisce a 4 documenti completamente diversi.

**La soluzione: un sistema di offset scalare.**

| Database | Offset tipico | Range ID risultante |
| --- | --- | --- |
| vedcontab | 0 (base) | 1 - 99.999 |
| gpxnetclone | +100.000 / +400.000 | 100.000 - 199.999 / 400.000+ |
| furmanetclone | +200.000 / +500.000 | 200.000 - 299.999 / 500.000+ |
| vedbondifeclone | +300.000 / +600.000 | 300.000 - 399.999 / 600.000+ |

**12 tipi di ID rinumerati** con offset specifici per database:
`PurchaseDocId`, `PurchaseOrdId`, `SuppQuotaId`, `CustQuotaId`, `SaleOrdId`, `EntryId`, `QuotationRequestId`, `WorkingReportId`, `MeasuresBookId`, `JobQuotationId`, `WPRId`, `SaleDocId`

Ogni rinumerazione non si limita alla tabella principale: aggiorna **tutte le tabelle figlie** collegate tramite foreign key. Un singolo `SaleDocId` viene aggiornato in **17 tabelle correlate**, con disabilitazione e riabilitazione dei vincoli FK.

L'innovazione finale: la **rinumerazione preventiva su VEDMaster** (script 28). Invece di correggere i riferimenti dopo il trasferimento, rinumeriamo gli ID delle fatture su VEDMaster *prima* di importare i dati dai clone. I cross-references arrivano gia' corretti — by design, non by fix.

---

## L'architettura: 10 fasi orchestrate

```
FASE 1  - Clonazione database (4 DB clonati per lavorare in sicurezza)
FASE 2  - Preparazione VEDMaster (svuotamento, mappa commesse duplicate)
FASE 3  - Rinumerazione Job sui clone (codici commessa anti-collisione)
FASE 4  - Rinumerazione ID documenti (12 tipi, 3 clone, offset scalari)
FASE 5  - Cross-references sui clone (85+ tipi documento riconciliati)
FASE 6  - Creazione depositi e causali (configurazione manuale Mago)
FASE 7  - Preparazione VEDMaster pre-trasferimento (rinumerazione + pulizia)
FASE 8  - Trasferimento dati (16 moduli, 160+ tabelle)
FASE 9  - Post-trasferimento (fix cross-ref, numeratori, viste, dati GPX)
FASE 10 - Workaround finali (RAM GPX, chiavi composite)
```

Il tutto orchestrato da un **master script** (`00_MasterMigrazione.ps1`) che permette di eseguire l'intero processo o singole fasi, con conferma interattiva ad ogni passo e logging completo su file.

---

## Il risultato

4 database separati. 160+ tabelle. 85+ tipi di documento incrociato. 145 viste. 12 tipi di ID rinumerati. 111.939 righe di codice.

**Un unico database unificato, perfettamente funzionante.**

Ogni fattura trova il suo documento contabile. Ogni DDT trova la sua fattura. Ogni ordine trova il suo DDT. Ogni commessa trova i suoi rapportini, le sue analisi, i suoi SAL.

Quello che la migrazione standard di Mago.net non poteva fare in tempi accettabili, questo progetto lo ha realizzato con un motore di migrazione costruito su misura — script dopo script, tabella dopo tabella, riferimento dopo riferimento.

Una sfida impossibile, trasformata in realta'.

---

*Progetto realizzato con vscode e script ps1 — Febbraio 2026*
