-- Vista [dbo].[VwIxW_OrdForCom] - Creazione
-- Generato: 2026-02-23 21:30:43

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[VwIxW_OrdForCom] AS  SELECT MA_PurchaseOrd.InternalOrdNo, MA_PurchaseOrdDetails.Description, MA_PurchaseOrdDetails.Item, MA_PurchaseOrdDetails.Supplier, MA_PurchaseOrdDetails.OrderDate, MA_PurchaseOrdDetails.ExpectedDeliveryDate, MA_PurchaseOrdDetails.DeliveredQty, MA_PurchaseOrdDetails.Qty, MA_PurchaseOrdDetails.Job, MA_PurchaseOrdDetails.UoM, MA_PurchaseOrdDetails.Delivered, MA_PurchaseOrdDetails.UnitValue, MA_PurchaseOrdDetails.TaxableAmount, MA_PurchaseOrdDetails.DiscountAmount, MA_PurchaseOrdDetails.DiscountFormula, MA_PurchaseOrdDetails.Discount1, MA_PurchaseOrdDetails.Discount2, { fn MONTH	(MA_PurchaseOrdDetails.ExpectedDeliveryDate) }  AS Mese, { fn YEAR	(MA_PurchaseOrdDetails.ExpectedDeliveryDate) }  AS Anno, LineType, MA_PurchaseOrd.Currency, MA_PurchaseOrd.FixingDate, MA_PurchaseOrd.FixingIsManual, MA_PurchaseOrd.Fixing FROM MA_PurchaseOrd LEFT OUTER JOIN MA_PurchaseOrdDetails ON MA_PurchaseOrd.PurchaseOrdId = MA_PurchaseOrdDetails.PurchaseOrdId
GO

PRINT 'Vista [dbo].[VwIxW_OrdForCom] creata con successo'
GO

