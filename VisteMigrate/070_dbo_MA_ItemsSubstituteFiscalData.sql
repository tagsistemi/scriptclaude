-- Vista [dbo].[MA_ItemsSubstituteFiscalData] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_ItemsSubstituteFiscalData')
BEGIN
    DROP VIEW [dbo].[MA_ItemsSubstituteFiscalData]
    PRINT 'Vista [dbo].[MA_ItemsSubstituteFiscalData] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_ItemsSubstituteFiscalData] AS  
	SELECT 
			MA_ItemsSubstitute.Item, 
			MA_ItemsSubstitute.Substitute, 
			MA_ItemsSubstitute.ItemQty, 
			MA_ItemsSubstitute.SubstituteQty, 
			MA_ItemsSubstitute.Notes, 
			MA_ItemsFiscalData.FiscalYear, 
			MA_ItemsFiscalData.FinalOnHand, 
			MA_ItemsFiscalData.BookInv,
			MA_ItemsFiscalData.FiscalPeriod

	FROM   MA_ItemsSubstitute  LEFT OUTER JOIN MA_ItemsFiscalData
	ON  MA_ItemsSubstitute.Substitute=MA_ItemsFiscalData.Item
GO

PRINT 'Vista [dbo].[MA_ItemsSubstituteFiscalData] creata con successo'
GO

