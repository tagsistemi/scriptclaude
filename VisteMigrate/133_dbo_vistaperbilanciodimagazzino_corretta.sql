-- Vista [dbo].[vistaperbilanciodimagazzino_corretta] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'vistaperbilanciodimagazzino_corretta')
BEGIN
    DROP VIEW [dbo].[vistaperbilanciodimagazzino_corretta]
    PRINT 'Vista [dbo].[vistaperbilanciodimagazzino_corretta] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[vistaperbilanciodimagazzino_corretta]
AS
SELECT  TOP (100) PERCENT dbo.MA_ItemsStorageQty.Item, dbo.MA_Items.SaleBarCode, dbo.MA_Items.BaseUoM, dbo.MA_ItemsStorageQty.FiscalYear, dbo.MA_ItemsFiscalData.ReservedSaleOrd, 
               dbo.MA_ItemsFiscalData.OrderedPurchOrd, dbo.MA_Items.CommodityCtg, dbo.MA_Items.HomogeneousCtg, dbo.MA_Items.CommissionCtg, dbo.MA_Items.ItemType, dbo.MA_ItemsStorageQty.InitialQty, 
               dbo.MA_ItemsStorageQty.ReceivedQty, dbo.MA_ItemsStorageQty.IssuedQty, dbo.MA_ItemsStorageQty.ReservedSaleOrd AS ordclidepo, dbo.MA_ItemsStorageQty.OrderedPurchOrd AS ordafordepo, 
               dbo.MA_ItemsFiscalData.LastCost, dbo.MA_ItemsFiscalData.StandardCost, dbo.MA_ItemsStorageQty.Storage, dbo.MA_Items.PublicNote AS Descrid, dbo.MA_Items.Description, 
               dbo.MA_ItemsGoodsData.MinimumStock AS ScortaMin, dbo.MA_Items.OldItem, LEFT(dbo.MA_Items.OldItem, 3) AS radice, dbo.MA_ItemsStorageQty.MinimumStock, 
               dbo.MA_ItemsStorageQty.MinimumStock - (dbo.MA_ItemsStorageQty.InitialQty + dbo.MA_ItemsStorageQty.ReceivedQty - dbo.MA_ItemsStorageQty.IssuedQty) AS inscorta, 
               dbo.MA_ItemsFiscalData.BookInv AS BookInv_, ROUND(dbo.MA_ItemsStorageQty.InitialQty + dbo.MA_ItemsStorageQty.ReceivedQty - dbo.MA_ItemsStorageQty.IssuedQty, 2) AS BookInv
FROM     dbo.MA_ItemsFiscalData RIGHT OUTER JOIN
               dbo.MA_ItemsStorageQty INNER JOIN
               dbo.MA_ItemsGoodsData INNER JOIN
               dbo.MA_Items ON dbo.MA_ItemsGoodsData.Item = dbo.MA_Items.Item ON dbo.MA_ItemsStorageQty.Item = dbo.MA_Items.Item ON dbo.MA_ItemsFiscalData.FiscalYear = dbo.MA_ItemsStorageQty.FiscalYear AND 
               dbo.MA_ItemsFiscalData.Item = dbo.MA_ItemsStorageQty.Item AND dbo.MA_ItemsFiscalData.Storage = dbo.MA_ItemsStorageQty.Storage
ORDER BY dbo.MA_ItemsStorageQty.Storage, dbo.MA_Items.CommodityCtg, dbo.MA_Items.OldItem
GO

PRINT 'Vista [dbo].[vistaperbilanciodimagazzino_corretta] creata con successo'
GO

