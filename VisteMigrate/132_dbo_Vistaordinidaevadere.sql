-- Vista [dbo].[Vistaordinidaevadere] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vistaordinidaevadere')
BEGIN
    DROP VIEW [dbo].[Vistaordinidaevadere]
    PRINT 'Vista [dbo].[Vistaordinidaevadere] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vistaordinidaevadere]
AS
SELECT     dbo.MA_SaleOrdDetails.Item, dbo.MA_Items.Description, dbo.MA_Items.TaxCode, dbo.MA_Items.BaseUoM, dbo.MA_Items.CommodityCtg, 
                      dbo.MA_SaleOrdDetails.Qty, dbo.MA_SaleOrdDetails.DeliveredQty, dbo.MA_SaleOrdDetails.Delivered, dbo.MA_SaleOrdDetails.Job, 
                      dbo.MA_Items.SaleBarCode, dbo.MA_CommodityCtg.Description AS DescriCategoria, dbo.MA_SaleOrdDetails.ExpectedDeliveryDate, 
                      dbo.MA_SaleOrdDetails.TaxableAmount / dbo.MA_SaleOrdDetails.Qty AS imponibileunitario, dbo.MA_SaleOrdDetails.TaxableAmount, 
                      dbo.MA_SaleOrdDetails.Qty - dbo.Vista_QtaConsegnataCommessa.QtaCons AS saldoqta, dbo.MA_SaleOrdDetails.Customer, 
                      dbo.MA_CustSupp.CompanyName, dbo.MA_CustSupp.CustSuppType, dbo.MA_CustSupp.Address, dbo.MA_CustSupp.ZIPCode, dbo.MA_CustSupp.City, 
                      dbo.MA_CustSupp.County, dbo.MA_SaleOrd.ExternalOrdNo, dbo.MA_ItemsGoodsData.Department, dbo.MA_SaleOrdDetails.Position, 
                      dbo.MA_SaleOrd.StoragePhase1, dbo.Vista_QtaConsegnataCommessa.QtaCons, dbo.gpx_testaram.NrRam, dbo.MA_SaleOrdDetails.Line, 
                      dbo.MA_SaleOrdDetails.UoM, dbo.gpx_righeram.StatoRiga, dbo.gpx_righeram.QtaDaProd
FROM         dbo.gpx_testaram INNER JOIN
                      dbo.gpx_righeram ON dbo.gpx_testaram.IdRam = dbo.gpx_righeram.IdRam RIGHT OUTER JOIN
                      dbo.MA_SaleOrdDetails INNER JOIN
                      dbo.MA_Items ON dbo.MA_SaleOrdDetails.Item = dbo.MA_Items.Item INNER JOIN
                      dbo.MA_CommodityCtg ON dbo.MA_Items.CommodityCtg = dbo.MA_CommodityCtg.Category INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleOrdDetails.Customer = dbo.MA_CustSupp.CustSupp INNER JOIN
                      dbo.MA_SaleOrd ON dbo.MA_SaleOrdDetails.SaleOrdId = dbo.MA_SaleOrd.SaleOrdId INNER JOIN
                      dbo.MA_ItemsGoodsData ON dbo.MA_Items.Item = dbo.MA_ItemsGoodsData.Item ON dbo.gpx_righeram.Articolo = dbo.MA_SaleOrdDetails.Item AND 
                      dbo.gpx_righeram.PosizioneOrdine = dbo.MA_SaleOrdDetails.Position AND 
                      dbo.gpx_righeram.Commessa = dbo.MA_SaleOrdDetails.Job LEFT OUTER JOIN
                      dbo.Vista_QtaConsegnataCommessa ON dbo.MA_SaleOrdDetails.Item = dbo.Vista_QtaConsegnataCommessa.Item AND 
                      dbo.MA_SaleOrdDetails.Job = dbo.Vista_QtaConsegnataCommessa.Job AND 
                      dbo.MA_SaleOrdDetails.SaleOrdId = dbo.Vista_QtaConsegnataCommessa.SaleOrdId AND 
                      dbo.MA_SaleOrdDetails.Position = dbo.Vista_QtaConsegnataCommessa.SaleOrdPos
WHERE     (dbo.MA_CustSupp.CustSuppType = 3211264)
GO

PRINT 'Vista [dbo].[Vistaordinidaevadere] creata con successo'
GO

