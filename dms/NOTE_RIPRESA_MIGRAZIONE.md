# NOTA: Ripresa migrazione DMS dopo errore spazio disco

## Situazione
Lo script 06 si è interrotto per mancanza di spazio disco.
I cloni (03, 04, 05) sono già completati e NON vanno rifatti.

## Passaggi da eseguire

1. **Eliminare vedDMS** da SQL Server Management Studio:
   ```sql
   ALTER DATABASE [vedDMS] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
   DROP DATABASE [vedDMS];
   ```

2. **Eliminare il file .bak** rimasto su `O:\BackupDMS` (dal server, se serve ulteriore spazio)

3. **Ricreare vedDMS** (manualmente come fatto in precedenza)

4. **Rilanciare solo lo script 06**:
   ```powershell
   . 'E:\MigrazioneVed\ScriptsClaude\dms\06_TrasferisciInVedMasterDMS.ps1'
   ```

5. **Poi proseguire con 07** (verifica post-migrazione):
   ```powershell
   . 'E:\MigrazioneVed\ScriptsClaude\dms\07_VerificaPostMigrazione.ps1'
   ```

## NON rieseguire
- 03_ClonaDatabaseDMS.ps1 (cloni già creati)
- 04_AggiornaPrimaryKeyValue.ps1 (già completato)
- 05_RinumeraIdDMS.ps1 (già completato)
