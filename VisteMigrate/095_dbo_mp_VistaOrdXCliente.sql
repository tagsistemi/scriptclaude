-- Vista [dbo].[mp_VistaOrdXCliente] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'mp_VistaOrdXCliente')
BEGIN
    DROP VIEW [dbo].[mp_VistaOrdXCliente]
    PRINT 'Vista [dbo].[mp_VistaOrdXCliente] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[mp_VistaOrdXCliente]
AS
SELECT     TOP (100) PERCENT dbo.MA_SaleOrdDetails.Customer, dbo.MA_SaleOrdDetails.OrderDate, dbo.MA_CustSupp.CustSuppType, 
                      dbo.MA_CustSupp.CompanyName, dbo.MA_ItemCustomers.CustomerCode, dbo.MA_ItemCustomers.CustomerDescription, 
                      dbo.MA_CommodityCtg.Description, dbo.MA_Items.CommodityCtg, dbo.MA_SaleOrdDetails.Qty, dbo.MA_SaleOrdDetails.UoM, 
                      dbo.MA_SaleOrdDetails.Item, dbo.MA_Items.OldItem, dbo.MA_SaleOrdDetails.LineType
FROM         dbo.MA_Items INNER JOIN
                      dbo.MA_SaleOrdDetails ON dbo.MA_Items.Item = dbo.MA_SaleOrdDetails.Item INNER JOIN
                      dbo.MA_ItemCustomers ON dbo.MA_SaleOrdDetails.Customer = dbo.MA_ItemCustomers.Customer AND 
                      dbo.MA_SaleOrdDetails.Item = dbo.MA_ItemCustomers.Item INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleOrdDetails.Customer = dbo.MA_CustSupp.CustSupp INNER JOIN
                      dbo.MA_CommodityCtg ON dbo.MA_Items.CommodityCtg = dbo.MA_CommodityCtg.Category
WHERE     (dbo.MA_CustSupp.CustSuppType = 3211264) AND (dbo.MA_SaleOrdDetails.LineType = 3538947)
ORDER BY dbo.MA_SaleOrdDetails.Customer
GO

PRINT 'Vista [dbo].[mp_VistaOrdXCliente] creata con successo'
GO

