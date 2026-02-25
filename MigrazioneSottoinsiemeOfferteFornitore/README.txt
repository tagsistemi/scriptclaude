Questa cartella contiene gli script per l'analisi e la migrazione delle tabelle MA_SuppQuotas*.

1) Analyze-SuppQuotasTableSchemas.ps1
   - Confronta gli schemi tra VEDMaster e i DB sorgenti (gpxnetclone, furmanetclone, vedbondifeclone)
   - Genera il report: Analyze-SuppQuotasTableSchemas_Report.txt

2) Migrate-SuppQuotasData.ps1
   - Disabilita le FK sulle tabelle target, svuota le tabelle, migra i dati con mappatura colonne per nome e NOT EXISTS su PK
   - Riabilita le FK e fa una verifica finale dei conteggi

Note:
- Aggiorna le connessioni se necessario.
- Se nel report emergono mismatch di lunghezze, esegui prima le opportune ALTER TABLE nel VEDMaster.
