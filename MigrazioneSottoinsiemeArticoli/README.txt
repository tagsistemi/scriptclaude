Questa cartella contiene gli script per l'analisi e la migrazione del sottoinsieme di tabelle ARTICOLI.

1) Analyze-ItemsTableSchemas.ps1
   - Confronta gli schemi tra VEDMaster e i DB sorgenti (gpxnetclone, furmanetclone, vedbondifeclone)
   - Genera il report: Analyze-ItemsTableSchemas_Report.txt

2) Fix-Items-Lengths.sql (opzionale)
   - Modello per adeguare lunghezze colonne in VEDMaster in base al massimo rilevato nei sorgenti
   - Personalizza duplicando il blocco per ogni colonna segnalata nel report

3) Migrate-ItemsData.ps1
   - Disabilita le FK sulle tabelle target, svuota le tabelle, migra i dati con mappatura colonne per nome e NOT EXISTS su PK
   - Riabilita le FK e fa una verifica finale dei conteggi

Note:
- Esegui sempre prima l'analisi. Se emergono mismatch (lunghezza, tipo, nullability), adegua lo schema di VEDMaster prima della migrazione.
- L'ordine in $TablesToMigrate è impostato per minimizzare conflitti di FK (genitori prima dei figli).
