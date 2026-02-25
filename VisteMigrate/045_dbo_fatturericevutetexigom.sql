-- Vista [dbo].[fatturericevutetexigom] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'fatturericevutetexigom')
BEGIN
    DROP VIEW [dbo].[fatturericevutetexigom]
    PRINT 'Vista [dbo].[fatturericevutetexigom] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[fatturericevutetexigom]
AS
SELECT     'texigom' AS Azienda, TexigomSqlNet.dbo.MA_JournalEntriesTax.AccTpl, TexigomSqlNet.dbo.MA_JournalEntriesTax.DocumentDate, 
                      TexigomSqlNet.dbo.MA_JournalEntriesTax.PostingDate, TexigomSqlNet.dbo.MA_JournalEntriesTax.CustSupp, 
                      TexigomSqlNet.dbo.MA_JournalEntriesTax.TaxableAmount, TexigomSqlNet.dbo.MA_CustSupp.CompanyName, 
                      TexigomSqlNet.dbo.MA_CustSupp.TaxIdNumber
FROM         TexigomSqlNet.dbo.MA_JournalEntriesTax INNER JOIN
                      TexigomSqlNet.dbo.MA_CustSupp ON TexigomSqlNet.dbo.MA_JournalEntriesTax.CustSupp = TexigomSqlNet.dbo.MA_CustSupp.CustSupp AND 
                      TexigomSqlNet.dbo.MA_JournalEntriesTax.CustSuppType = TexigomSqlNet.dbo.MA_CustSupp.CustSuppType
WHERE     (TexigomSqlNet.dbo.MA_JournalEntriesTax.CustSuppType = 3211265) AND (TexigomSqlNet.dbo.MA_JournalEntriesTax.Nature = 9306112) AND 
                      (TexigomSqlNet.dbo.MA_JournalEntriesTax.TransactionType = 6225922)
GO

PRINT 'Vista [dbo].[fatturericevutetexigom] creata con successo'
GO

