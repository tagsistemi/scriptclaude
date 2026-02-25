-- Vista [dbo].[MA_JournalEntriesTaxJoin] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_JournalEntriesTaxJoin')
BEGIN
    DROP VIEW [dbo].[MA_JournalEntriesTaxJoin]
    PRINT 'Vista [dbo].[MA_JournalEntriesTaxJoin] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_JournalEntriesTaxJoin] AS  
	SELECT  COALESCE(MA_JournalEntriesIntraTax.TaxJournal,MA_JournalEntriesTax.TaxJournal)   AS TaxJournal,  
			COALESCE(MA_JournalEntriesIntraTax.DocNo,MA_JournalEntriesTax.DocNo)   AS No, 
			MA_JournalEntriesTax.PostingDate, 
			MA_JournalEntriesTax.TaxAccrualDate, 
			MA_JournalEntriesTax.DocNo, 
			MA_JournalEntriesTax.DocumentDate, 
			MA_JournalEntriesTax.CustSupp, 
			MA_JournalEntriesTax.CustSuppType, 
			MA_JournalEntriesTax.JournalEntryId, 
			MA_JournalEntriesTax.TaxSign, 
			MA_JournalEntriesTax.IntrastatOperation, 
			MA_JournalEntriesTax.AccTpl, 
			MA_JournalEntriesTax.NotExigible, 
			MA_JournalEntriesIntraTax.Currency, 
			MA_JournalEntriesIntraTax.TotalAmountDocCurr, 
			MA_JournalEntriesIntraTax.Fixing 
	FROM MA_JournalEntriesTax LEFT OUTER JOIN MA_JournalEntriesIntraTax 
	ON  MA_JournalEntriesTax.JournalEntryId=MA_JournalEntriesIntraTax.JournalEntryId
GO

PRINT 'Vista [dbo].[MA_JournalEntriesTaxJoin] creata con successo'
GO

