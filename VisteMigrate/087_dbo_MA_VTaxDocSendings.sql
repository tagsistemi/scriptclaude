-- Vista [dbo].[MA_VTaxDocSendings] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VTaxDocSendings')
BEGIN
    DROP VIEW [dbo].[MA_VTaxDocSendings]
    PRINT 'Vista [dbo].[MA_VTaxDocSendings] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VTaxDocSendings] AS  
	SELECT 
		[dbo].[MA_TaxDocSendings].[TaxDocSendingId],
		[dbo].[MA_TaxDocSendings].[TaxDocSendingNo],
		[dbo].[MA_TaxDocSendings].[SendingType],
		[dbo].[MA_TaxDocSendings].[SendingStatus],
		[dbo].[MA_TaxDocSendings].[SetupDate],
		[dbo].[MA_TaxDocSendings].[Retails],
		[dbo].[MA_JournalEntriesTax].[JournalEntryId],
		[dbo].[MA_JournalEntriesTax].[TaxAccrualDate],
		[dbo].[MA_JournalEntriesTax].[BlackListCustSupp],
		[dbo].[MA_JournalEntriesTax].[CustSuppType],
		[dbo].[MA_JournalEntriesTax].[DocNo],
		[dbo].[MA_JournalEntriesTax].[LogNo],
		[dbo].[MA_JournalEntriesTax].[AccTpl],
		[dbo].[MA_JournalEntriesTax].[TaxJournal],
		[dbo].[MA_JournalEntriesTax].[TaxSign],
		[dbo].[MA_JournalEntries].[TotalAmount],
		[dbo].[MA_CustSupp].[CompanyName],
		[dbo].[MA_CustSupp].[TaxIdNumber],
		[dbo].[MA_CustSupp].[FiscalCode],
		[dbo].[MA_CustSupp].[IsCustoms],
		[dbo].[MA_CustSupp].[IsoCountryCode],
		[dbo].[MA_CustSupp].[UsedForSummaryDocuments],
		[dbo].[MA_TaxDocSendingsDetails].[Line] 
	FROM [dbo].[MA_TaxDocSendings]
		INNER JOIN [dbo].[MA_TaxDocSendingsDetails] ON
		[dbo].[MA_TaxDocSendings].[TaxDocSendingId] = [dbo].[MA_TaxDocSendingsDetails].[TaxDocSendingId]
		INNER JOIN [dbo].[MA_JournalEntriesTax] ON
		[dbo].[MA_TaxDocSendingsDetails].[CRRefID] = [dbo].[MA_JournalEntriesTax].[JournalEntryId]
		INNER JOIN [dbo].[MA_JournalEntries] ON
		[dbo].[MA_JournalEntriesTax].[JournalEntryId] = [dbo].[MA_JournalEntries].[JournalEntryId]
		LEFT OUTER JOIN [dbo].[MA_CustSupp] ON
		[dbo].[MA_JournalEntriesTax].[CustSuppType] = [dbo].[MA_CustSupp].[CustSuppType] AND
		[dbo].[MA_JournalEntriesTax].[BlackListCustSupp] = [dbo].[MA_CustSupp].[CustSupp]
GO

PRINT 'Vista [dbo].[MA_VTaxDocSendings] creata con successo'
GO

