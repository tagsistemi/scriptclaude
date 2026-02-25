-- Vista [dbo].[vistaperbilanciomagazzinox] - Aggiornamento
-- Generato: 2026-02-23 21:30:43

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'vistaperbilanciomagazzinox')
BEGIN
    DROP VIEW [dbo].[vistaperbilanciomagazzinox]
    PRINT 'Vista [dbo].[vistaperbilanciomagazzinox] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[vistaperbilanciomagazzinox]
AS
SELECT     dbo.MA_Items.Item, dbo.MA_Items.SaleBarCode, dbo.MA_Items.Description, dbo.MA_Items.BaseUoM, dbo.MA_ItemsFiscalData.FiscalYear, 
                      dbo.MA_ItemsFiscalData.ReservedSaleOrd, dbo.MA_ItemsFiscalData.OrderedPurchOrd, dbo.MA_ItemsFiscalData.BookInv, 
                      dbo.MA_Items.CommodityCtg, dbo.MA_Items.HomogeneousCtg, dbo.MA_Items.CommissionCtg, dbo.MA_Items.ItemType, 
                      dbo.MA_ItemsStorageQty.InitialQty, dbo.MA_ItemsStorageQty.ReceivedQty, dbo.MA_ItemsStorageQty.IssuedQty, 
                      dbo.MA_ItemsStorageQty.ReservedSaleOrd AS ordclidepo, dbo.MA_ItemsStorageQty.OrderedPurchOrd AS ordafordepo, 
                      dbo.MA_ItemsFiscalData.LastCost, dbo.MA_ItemsFiscalData.StandardCost, dbo.MA_ItemsStorageQty.Storage
FROM         dbo.MA_ItemsStorageQty INNER JOIN
                      dbo.MA_ItemsFiscalData ON dbo.MA_ItemsStorageQty.Item = dbo.MA_ItemsFiscalData.Item AND 
                      dbo.MA_ItemsStorageQty.FiscalYear = dbo.MA_ItemsFiscalData.FiscalYear RIGHT OUTER JOIN
                      dbo.MA_Items ON dbo.MA_ItemsFiscalData.Item = dbo.MA_Items.Item
GO

PRINT 'Vista [dbo].[vistaperbilanciomagazzinox] creata con successo'
GO

