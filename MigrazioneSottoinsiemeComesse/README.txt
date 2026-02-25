Sottoinsieme: Commesse
Tabelle: MA_JobGroups, MA_Jobs, MA_JobsBalances, MA_JobsParameters

Prerequisiti:
- Modulo PowerShell SqlServer (Invoke-Sqlcmd)
- Accesso a 192.168.0.3\\SQL2008, DB: VEDMaster, sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

1) Analisi strutture
- Eseguire Analyze-JobsTableSchemas.ps1
- Output: ANALISI_STRUTTURA_TABELLE_COMMESSE_yyyyMMdd_HHmmss.txt
- Controlla: tipo, lunghezza, nullability, ordine, precisione/scala, collation; segnala colonne mancanti/in più e tabelle assenti.

2) Correzioni schema (se necessarie)
- In base al report, modificare Fix-Jobs-Lengths.sql aggiungendo ALTER COLUMN per armonizzare le lunghezze nel DB di destinazione.

3) Migrazione dati
- Eseguire Migrate-JobsData.ps1
- Lo script:
  * Disabilita i vincoli FK sulle tabelle target
  * Svuota le tabelle in ordine inverso di dipendenza
  * Inserisce i dati da ciascun DB sorgente usando l'intersezione dei nomi colonna (case-insensitive)
  * Evita duplicati usando WHERE NOT EXISTS sul PK (o su tutte le colonne comuni se PK assente)
  * Riabilita i vincoli FK
  * Stampa i conteggi righe per confronto sorgenti/destinazione

Note:
- Se emergono errori di chiave o conversione, verificare mapping colonne, tipi e lunghezze nel report di analisi.
- Adeguare l'ordine tabelle se esistono dipendenze diverse nell'installazione.
