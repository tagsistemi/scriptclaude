Questa cartella contiene gli script per l'analisi e la migrazione della tabella MA_CrossReferences.

1) Analyze-CrossReferencesTableSchemas.ps1
   - Confronta lo schema tra VEDMaster e i DB sorgenti (gpxnetclone, furmanetclone, vedbondifeclone)
   - Genera il report: Analyze-CrossReferencesTableSchemas_Report.txt

2) Migrate-CrossReferencesData.ps1
   - Disabilita le FK, svuota la tabella, migra i dati con mappatura colonne per nome e NOT EXISTS su PK
   - Riabilita le FK e verifica conteggi finali

Note:
- Esegui sempre prima l'analisi. Se emergono mismatch (lunghezze, tipi, nullability, precisione/scala, collation), adegua VEDMaster prima della migrazione.
