-- Vista [dbo].[fatturericevuteved2007] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'fatturericevuteved2007')
BEGIN
    DROP VIEW [dbo].[fatturericevuteved2007]
    PRINT 'Vista [dbo].[fatturericevuteved2007] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[fatturericevuteved2007]
AS
SELECT     'ved2007' AS Azienda, dbo.MA_JournalEntriesTax.AccTpl, dbo.MA_JournalEntriesTax.DocumentDate, dbo.MA_JournalEntriesTax.PostingDate, 
                      dbo.MA_JournalEntriesTax.CustSupp, dbo.MA_JournalEntriesTax.TaxableAmount, dbo.MA_CustSupp.CompanyName, 
                      dbo.MA_CustSupp.TaxIdNumber
FROM         dbo.MA_JournalEntriesTax INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_JournalEntriesTax.CustSupp = dbo.MA_CustSupp.CustSupp AND 
                      dbo.MA_JournalEntriesTax.CustSuppType = dbo.MA_CustSupp.CustSuppType
WHERE     (dbo.MA_JournalEntriesTax.CustSuppType = 3211265) AND (dbo.MA_JournalEntriesTax.Nature = 9306112) AND 
                      (dbo.MA_JournalEntriesTax.TransactionType = 6225922)
GO

PRINT 'Vista [dbo].[fatturericevuteved2007] creata con successo'
GO

