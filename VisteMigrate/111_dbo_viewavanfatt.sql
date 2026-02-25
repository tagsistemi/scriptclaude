-- Vista [dbo].[viewavanfatt] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'viewavanfatt')
BEGIN
    DROP VIEW [dbo].[viewavanfatt]
    PRINT 'Vista [dbo].[viewavanfatt] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[viewavanfatt]
AS
SELECT     dbo.MA_SaleOrd.InternalOrdNo, dbo.MA_SaleOrd.OrderDate, dbo.MA_SaleOrd.Customer, dbo.MA_SaleOrd.ExpectedDeliveryDate, 
                      dbo.MA_SaleOrd.Invoiced, dbo.MA_SaleOrd.SaleOrdId, dbo.MA_SaleOrdSummary.TotalAmount, dbo.MA_SaleOrdReferences.DocumentType, 
                      dbo.MA_SaleOrdReferences.DocumentDate, dbo.MA_SaleOrdReferences.DocumentNumber, dbo.MA_SaleDoc.PostedToAccounting, 
                      dbo.MA_SaleDocSummary.TotalAmount AS Expr1, dbo.MA_CustSupp.CompanyName, dbo.MA_CustSupp.CustSuppType
FROM         dbo.MA_SaleOrd INNER JOIN
                      dbo.MA_SaleOrdSummary ON dbo.MA_SaleOrd.SaleOrdId = dbo.MA_SaleOrdSummary.SaleOrdId INNER JOIN
                      dbo.MA_SaleOrdReferences ON dbo.MA_SaleOrdSummary.SaleOrdId = dbo.MA_SaleOrdReferences.SaleOrdId INNER JOIN
                      dbo.MA_SaleDoc ON dbo.MA_SaleOrdReferences.DocumentId = dbo.MA_SaleDoc.SaleDocId INNER JOIN
                      dbo.MA_SaleDocSummary ON dbo.MA_SaleDoc.SaleDocId = dbo.MA_SaleDocSummary.SaleDocId INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleOrd.Customer = dbo.MA_CustSupp.CustSupp
WHERE     (dbo.MA_CustSupp.CustSuppType = 3211264)
GO

PRINT 'Vista [dbo].[viewavanfatt] creata con successo'
GO

