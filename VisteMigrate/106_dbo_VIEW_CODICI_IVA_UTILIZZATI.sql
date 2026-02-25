-- Vista [dbo].[VIEW_CODICI_IVA_UTILIZZATI] - Creazione
-- Generato: 2026-02-23 21:30:40

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[VIEW_CODICI_IVA_UTILIZZATI] AS SELECT DISTINCT MA_JournalEntriesTaxDetail.TaxCode, MA_TaxCodes.Description, MA_TaxCodes.Perc FROM         MA_JournalEntriesTaxDetail INNER JOIN                       MA_TaxCodes ON MA_JournalEntriesTaxDetail.TaxCode = MA_TaxCodes.TaxCode
GO

PRINT 'Vista [dbo].[VIEW_CODICI_IVA_UTILIZZATI] creata con successo'
GO

