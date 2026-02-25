-- Vista [dbo].[MA_VSaleOrdersToDelivered] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VSaleOrdersToDelivered')
BEGIN
    DROP VIEW [dbo].[MA_VSaleOrdersToDelivered]
    PRINT 'Vista [dbo].[MA_VSaleOrdersToDelivered] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VSaleOrdersToDelivered] AS SELECT
	MA_SaleOrd.StubBook,
	MA_SaleOrd.StoragePhase1,
	MA_SaleOrd.Specificator1Type,
	MA_SaleOrd.SpecificatorPhase1,
	MA_SaleOrd.Salesperson,
	MA_SaleOrd.Priority,
	MA_SaleOrd.AllocationArea,
	MA_SaleOrd.Area,
	MA_SaleOrd.InternalOrdNo,
	MA_SaleOrd.Carrier1,
	MA_SaleOrd.IsBlocked,
	MA_SaleOrd.ShipToAddress,
	MA_SaleOrd.Port,
	MA_SaleOrd.Package,
	MA_SaleOrd.Transport,
	MA_SaleOrd.SingleDelivery,
	MA_Items.AvailabilityDate,
	MA_CustSuppCustomerOptions.Blocked,
	MA_CustSuppCustomerOptions.Category,
	MA_SaleOrdDetails.SaleOrdId,
	MA_SaleOrdDetails.Line,
	MA_SaleOrdDetails.SubId,
	MA_SaleOrdDetails.Position,
	MA_SaleOrdDetails.Item,
	MA_SaleOrdDetails.UoM,
	MA_SaleOrdDetails.Qty,
	MA_SaleOrdDetails.OrderDate,
	MA_SaleOrdDetails.ExpectedDeliveryDate,
	MA_SaleOrdDetails.ConfirmedDeliveryDate,
	MA_SaleOrdDetails.Cancelled,
	MA_SaleOrdDetails.Customer,
	MA_SaleOrdDetails.Allocated,
	MA_SaleOrdDetails.AllocatedQty,
	MA_SaleOrdDetails.PreShipped,
	MA_SaleOrdDetails.PreShippedQty,
	MA_SaleOrdDetails.PickedAndDeliveredQty,
	MA_SaleOrdDetails.Delivered,
	MA_SaleOrdDetails.DeliveredQty,
	MA_SaleOrdDetails.LineType,
	MA_SaleOrdDetails.BOMItem,
	MA_SaleOrdDetails.CrossDocking,
	MA_Storages.ConsignmentStock
	FROM MA_SaleOrdDetails INNER JOIN
    MA_SaleOrdShipping ON MA_SaleOrdDetails.SaleOrdId = MA_SaleOrdShipping.SaleOrdId INNER JOIN
    MA_Items ON MA_SaleOrdDetails.Item = MA_Items.Item INNER JOIN
    MA_CustSuppCustomerOptions ON MA_SaleOrdDetails.Customer = MA_CustSuppCustomerOptions.Customer INNER JOIN
    MA_SaleOrd ON MA_SaleOrdDetails.SaleOrdId = MA_SaleOrd.SaleOrdId INNER JOIN
    MA_Storages ON MA_SaleOrd.StoragePhase1 = MA_Storages.Storage
    WHERE MA_SaleOrd.IsBlocked = '0' AND MA_SaleOrdDetails.PreShipped = '0' AND MA_SaleOrdDetails.Delivered = '0' AND MA_SaleOrdDetails.Cancelled = '0' AND MA_SaleOrdDetails.LineType = 3538947 AND MA_SaleOrdDetails.NoDN = '0'
GO

PRINT 'Vista [dbo].[MA_VSaleOrdersToDelivered] creata con successo'
GO

