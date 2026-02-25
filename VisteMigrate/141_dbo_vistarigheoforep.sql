-- Vista [dbo].[vistarigheoforep] - Creazione
-- Generato: 2026-02-23 21:30:43

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[vistarigheoforep] AS SELECT     MA_ItemsGoodsData.Department, MA_PurchaseOrdDetails.Item, MA_PurchaseOrdDetails.Description, MA_PurchaseOrdDetails.NoPrint, MA_PurchaseOrdDetails.Supplier, MA_PurchaseOrdDetails.OrderDate,                        MA_PurchaseOrdDetails.UoM, MA_PurchaseOrdDetails.Qty, MA_PurchaseOrdDetails.PurchaseOrdId, MA_PurchaseOrdDetails.Line, MA_PurchaseOrdDetails.Position, MA_PurchaseOrdDetails.LineType,                        MA_PurchaseOrdDetails.AdditionalQty1, MA_PurchaseOrdDetails.AdditionalQty2, MA_PurchaseOrdDetails.AdditionalQty3, MA_PurchaseOrdDetails.AdditionalQty, MA_PurchaseOrdDetails.UnitValue, MA_PurchaseOrdDetails.TaxableAmount,                        MA_PurchaseOrdDetails.TaxCode, MA_PurchaseOrdDetails.TotalAmount, MA_PurchaseOrdDetails.Discount1, MA_PurchaseOrdDetails.Discount2, MA_PurchaseOrdDetails.DiscountFormula, MA_PurchaseOrdDetails.DiscountAmount,                        MA_PurchaseOrdDetails.ExpectedDeliveryDate, MA_PurchaseOrdDetails.ConfirmedDeliveryDate, MA_PurchaseOrdDetails.DeliveredQty, MA_PurchaseOrdDetails.PaidQty, MA_PurchaseOrdDetails.SaleType,                        MA_PurchaseOrdDetails.Paid, MA_PurchaseOrdDetails.Delivered, MA_PurchaseOrdDetails.Cancelled, MA_PurchaseOrdDetails.Lot, MA_PurchaseOrdDetails.SaleOrdNo,                        MA_PurchaseOrdDetails.SaleOrdPos, MA_PurchaseOrdDetails.Job, MA_PurchaseOrdDetails.CostCenter, MA_PurchaseOrdDetails.Offset, MA_PurchaseOrdDetails.PurchaseReqId,                        MA_PurchaseOrdDetails.PurchaseReqPos, MA_PurchaseOrdDetails.PurchaseReqNo, MA_PurchaseOrdDetails.NoDN, MA_PurchaseOrdDetails.NoInvoice, MA_PurchaseOrdDetails.SuppQuotaId,                        MA_PurchaseOrdDetails.SuppQuotaLine, MA_PurchaseOrdDetails.MOId, MA_PurchaseOrdDetails.RtgStep, MA_PurchaseOrdDetails.Alternate, MA_PurchaseOrdDetails.AltRtgStep, MA_PurchaseOrdDetails.KitNo,                        MA_PurchaseOrdDetails.KitQty, MA_PurchaseOrdDetails.SubId, MA_PurchaseOrdDetails.StoragePhase1, MA_PurchaseOrdDetails.StoragePhase2, MA_PurchaseOrdDetails.SpecificatorPhase1,                        MA_PurchaseOrdDetails.SpecificatorPhase2, MA_PurchaseOrdDetails.ExternalLineReference, MA_PurchaseOrdDetails.ReferenceDocId, MA_PurchaseOrdDetails.ReferenceDocNo, MA_PurchaseOrdDetails.NoOfPacks,                        MA_PurchaseOrdDetails.PacksUoM, MA_PurchaseOrdDetails.GrossWeight, MA_PurchaseOrdDetails.NetWeight, MA_PurchaseOrdDetails.GrossVolume, MA_PurchaseOrdDetails.SaleOrdId,                        MA_PurchaseOrdDetails.DefaultValueType, MA_PurchaseOrdDetails.DiscountDefaultType, MA_PurchaseOrdDetails.Notes, MA_PurchaseOrdDetails.FixedCost, MA_PurchaseOrdDetails.SupplierCode FROM         MA_PurchaseOrdDetails INNER JOIN                       MA_ItemsGoodsData ON MA_PurchaseOrdDetails.Item = MA_ItemsGoodsData.Item
GO

PRINT 'Vista [dbo].[vistarigheoforep] creata con successo'
GO

