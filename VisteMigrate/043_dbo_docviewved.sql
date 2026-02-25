-- Vista [dbo].[docviewved] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'docviewved')
BEGIN
    DROP VIEW [dbo].[docviewved]
    PRINT 'Vista [dbo].[docviewved] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[docviewved]
AS
SELECT     dbo.MA_SaleDoc.DocumentType, dbo.MA_SaleDoc.DocumentDate, dbo.MA_SaleDoc.CustSupp, dbo.MA_CustSupp.CompanyName, 
                      dbo.MA_SaleDocSummary.TaxableAmount, dbo.MA_SaleDocSummary.TotalAmount, dbo.MA_CustSupp.CustSuppType, 
                      dbo.MA_CustSupp.TaxIdNumber
FROM         dbo.MA_SaleDoc INNER JOIN
                      dbo.MA_SaleDocSummary ON dbo.MA_SaleDoc.SaleDocId = dbo.MA_SaleDocSummary.SaleDocId INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleDoc.CustSupp = dbo.MA_CustSupp.CustSupp
WHERE     (dbo.MA_SaleDoc.DocumentType = 3407874 OR
                      dbo.MA_SaleDoc.DocumentType = 3407875 OR
                      dbo.MA_SaleDoc.DocumentType = 3407876) AND (dbo.MA_CustSupp.CustSuppType = 3211264)
GO

PRINT 'Vista [dbo].[docviewved] creata con successo'
GO

