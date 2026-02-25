-- Vista [dbo].[fatturericevuteoikos] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'fatturericevuteoikos')
BEGIN
    DROP VIEW [dbo].[fatturericevuteoikos]
    PRINT 'Vista [dbo].[fatturericevuteoikos] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[fatturericevuteoikos]
AS
SELECT     'oikos' AS Azienda, OikosNet.dbo.MA_JournalEntriesTax.AccTpl, OikosNet.dbo.MA_JournalEntriesTax.DocumentDate, 
                      OikosNet.dbo.MA_JournalEntriesTax.PostingDate, OikosNet.dbo.MA_JournalEntriesTax.CustSupp, 
                      OikosNet.dbo.MA_JournalEntriesTax.TaxableAmount, OikosNet.dbo.MA_CustSupp.CompanyName, OikosNet.dbo.MA_CustSupp.TaxIdNumber
FROM         OikosNet.dbo.MA_JournalEntriesTax INNER JOIN
                      OikosNet.dbo.MA_CustSupp ON OikosNet.dbo.MA_JournalEntriesTax.CustSupp = OikosNet.dbo.MA_CustSupp.CustSupp AND 
                      OikosNet.dbo.MA_JournalEntriesTax.CustSuppType = OikosNet.dbo.MA_CustSupp.CustSuppType
WHERE     (OikosNet.dbo.MA_JournalEntriesTax.CustSuppType = 3211265) AND (OikosNet.dbo.MA_JournalEntriesTax.Nature = 9306112) AND 
                      (OikosNet.dbo.MA_JournalEntriesTax.TransactionType = 6225922)
GO

PRINT 'Vista [dbo].[fatturericevuteoikos] creata con successo'
GO

