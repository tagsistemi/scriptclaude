-- Vista [dbo].[IM_PurchaseOrdOrdDetails] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_PurchaseOrdOrdDetails')
BEGIN
    DROP VIEW [dbo].[IM_PurchaseOrdOrdDetails]
    PRINT 'Vista [dbo].[IM_PurchaseOrdOrdDetails] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_PurchaseOrdOrdDetails]
AS
SELECT     
      MA_PurchaseOrd.InternalOrdNo, 
      MA_PurchaseOrdDetails.Description, 
      MA_PurchaseOrdDetails.Item, 
      MA_PurchaseOrdDetails.Supplier, 
    MA_PurchaseOrdDetails.OrderDate, 
      MA_PurchaseOrdDetails.ExpectedDeliveryDate, 
      MA_PurchaseOrdDetails.DeliveredQty, 
    MA_PurchaseOrdDetails.Qty, 
      MA_PurchaseOrdDetails.Job, 
      MA_PurchaseOrdDetails.UoM, 
      MA_PurchaseOrdDetails.Delivered, 
    MA_PurchaseOrdDetails.UnitValue, 
      MA_PurchaseOrdDetails.TaxableAmount, 
      MA_PurchaseOrdDetails.DiscountAmount, 
    MA_PurchaseOrdDetails.DiscountFormula, 
      MA_PurchaseOrdDetails.Discount1, 
      MA_PurchaseOrdDetails.Discount2, 
    { fn MONTH(MA_PurchaseOrdDetails.ExpectedDeliveryDate) } AS ExpectedDeliveryMonth, { fn YEAR(MA_PurchaseOrdDetails.ExpectedDeliveryDate) } AS ExpectedDeliveryYear, 
      MA_PurchaseOrdDetails.LineType, 
      MA_PurchaseOrd.Currency, 
      MA_PurchaseOrd.FixingDate, 
    MA_PurchaseOrd.FixingIsManual, 
      MA_PurchaseOrd.Fixing, 
      MA_PurchaseOrdDetails.Cancelled,
      MA_PurchaseOrd.PurchaseOrdId
FROM         MA_PurchaseOrd LEFT OUTER JOIN
                      MA_PurchaseOrdDetails ON MA_PurchaseOrd.PurchaseOrdId = MA_PurchaseOrdDetails.PurchaseOrdId
GO

PRINT 'Vista [dbo].[IM_PurchaseOrdOrdDetails] creata con successo'
GO

