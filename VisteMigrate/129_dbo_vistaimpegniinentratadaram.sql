-- Vista [dbo].[vistaimpegniinentratadaram] - Creazione
-- Generato: 2026-02-23 21:30:42

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[vistaimpegniinentratadaram] AS SELECT     MA_PurchaseOrdDetails.Supplier, MA_PurchaseOrdDetails.UoM, MA_PurchaseOrdDetails.Qty, MA_PurchaseOrdDetails.DeliveredQty, MA_PurchaseOrdDetails.Item, MA_PurchaseOrdDetails.Delivered,                        MA_ItemsComparableUoM.BaseUoMQty, MA_ItemsComparableUoM.CompUoMQty, MA_ItemsComparableUoM.BaseUoMQty * (MA_PurchaseOrdDetails.Qty - MA_PurchaseOrdDetails.DeliveredQty)                        AS QtaInUmBase, MA_PurchaseOrdDetails.OrderDate, YEAR(MA_PurchaseOrdDetails.OrderDate) AS Esercizio FROM         MA_PurchaseOrdDetails LEFT OUTER JOIN                       MA_ItemsComparableUoM ON MA_PurchaseOrdDetails.Item = MA_ItemsComparableUoM.Item AND MA_PurchaseOrdDetails.UoM = MA_ItemsComparableUoM.ComparableUoM WHERE     (MA_PurchaseOrdDetails.Delivered = '0') AND (MA_PurchaseOrdDetails.Supplier = 'RAM')
GO

PRINT 'Vista [dbo].[vistaimpegniinentratadaram] creata con successo'
GO

