Questa cartella contiene gli script per l'analisi e la migrazione del sottoinsieme di tabelle MAGAZZINO.

1) Analyze-StockTableSchemas.ps1
   - Confronta gli schemi tra VEDMaster e i DB sorgenti (gpxnetclone, furmanetclone, vedbondifeclone)
   - Genera il report: Analyze-StockTableSchemas_Report.txt

2) Migrate-StockData.ps1
   - Disabilita le FK sulle tabelle target, svuota le tabelle, migra i dati con mappatura colonne per nome e NOT EXISTS su PK
   - Riabilita le FK e fa una verifica finale dei conteggi

Note:
- Esegui sempre prima l'analisi. Se emergono mismatch (lunghezza, tipo, nullability, precisione/scala), adegua lo schema di VEDMaster prima della migrazione.
- L'ordine in $TablesToMigrate è impostato per minimizzare conflitti di FK (genitori prima dei figli). Adattalo se le relazioni reali differiscono nel tuo schema.
