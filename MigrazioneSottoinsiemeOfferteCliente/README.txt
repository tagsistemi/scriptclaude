Questa cartella contiene gli script per l'analisi e la migrazione delle tabelle MA_CustQuotas*.

1) Analyze-CustQuotasTableSchemas.ps1
   - Confronta gli schemi tra VEDMaster e i DB sorgenti (gpxnetclone, furmanetclone, vedbondifeclone)
   - Genera il report: Analyze-CustQuotasTableSchemas_Report.txt

2) Migrate-CustQuotasData.ps1
   - Disabilita le FK sulle tabelle target, svuota le tabelle, migra i dati con mappatura colonne per nome e NOT EXISTS su PK
   - Riabilita le FK e fa una verifica finale dei conteggi

Note:
- Esegui sempre prima l'analisi. Se emergono mismatch (lunghezza, tipo, nullability), adegua lo schema di VEDMaster prima della migrazione.
