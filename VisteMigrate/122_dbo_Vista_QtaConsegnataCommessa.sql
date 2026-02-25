-- Vista [dbo].[Vista_QtaConsegnataCommessa] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_QtaConsegnataCommessa')
BEGIN
    DROP VIEW [dbo].[Vista_QtaConsegnataCommessa]
    PRINT 'Vista [dbo].[Vista_QtaConsegnataCommessa] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_QtaConsegnataCommessa]
AS
SELECT     dbo.MA_SaleDocDetail.Item, SUM(dbo.MA_SaleDocDetail.Qty) AS QtaCons, dbo.MA_SaleDocDetail.Job, dbo.MA_SaleDocDetail.SaleOrdId, 
                      dbo.MA_SaleDocDetail.SaleOrdPos, dbo.MA_SaleDoc.DocumentType
FROM         dbo.MA_SaleDocDetail INNER JOIN
                      dbo.MA_SaleDoc ON dbo.MA_SaleDocDetail.SaleDocId = dbo.MA_SaleDoc.SaleDocId
GROUP BY dbo.MA_SaleDocDetail.Item, dbo.MA_SaleDocDetail.Job, dbo.MA_SaleDocDetail.SaleOrdId, dbo.MA_SaleDocDetail.SaleOrdPos, 
                      dbo.MA_SaleDoc.DocumentType
HAVING      (dbo.MA_SaleDoc.DocumentType = 3407873)
GO

PRINT 'Vista [dbo].[Vista_QtaConsegnataCommessa] creata con successo'
GO

