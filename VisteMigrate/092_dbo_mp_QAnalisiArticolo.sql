-- Vista [dbo].[mp_QAnalisiArticolo] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'mp_QAnalisiArticolo')
BEGIN
    DROP VIEW [dbo].[mp_QAnalisiArticolo]
    PRINT 'Vista [dbo].[mp_QAnalisiArticolo] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[mp_QAnalisiArticolo]
AS
SELECT     TOP (100) PERCENT dbo.MA_Items.Description, dbo.MA_SaleDoc.DocumentType, dbo.MA_SaleDocDetail.SaleDocId AS IDDetail, 
                      dbo.MA_SaleDocDetail.Line, dbo.MA_SaleDocDetail.LineType, dbo.MA_SaleDocDetail.Item, dbo.MA_SaleDoc.DocumentDate, 
                      dbo.MA_SalesPeople.Name AS Agente, dbo.MA_SaleDocDetail.TaxableAmount, dbo.MA_SaleDoc.Salesperson, dbo.MA_Items.CommodityCtg, 
                      dbo.MA_SaleDoc.TaxJournal, dbo.MA_SaleDoc.CustSupp, dbo.MA_SaleDoc.CustSuppType, dbo.MA_CustSupp.Region, dbo.MA_SaleDoc.DocNo
FROM         dbo.MA_SaleDoc INNER JOIN
                      dbo.MA_SaleDocDetail ON dbo.MA_SaleDoc.SaleDocId = dbo.MA_SaleDocDetail.SaleDocId INNER JOIN
                      dbo.MA_SalesPeople ON dbo.MA_SaleDoc.Salesperson = dbo.MA_SalesPeople.Salesperson INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleDoc.CustSuppType = dbo.MA_CustSupp.CustSuppType AND 
                      dbo.MA_SaleDoc.CustSupp = dbo.MA_CustSupp.CustSupp LEFT OUTER JOIN
                      dbo.MA_Items ON dbo.MA_SaleDocDetail.Item = dbo.MA_Items.Item
GO

PRINT 'Vista [dbo].[mp_QAnalisiArticolo] creata con successo'
GO

