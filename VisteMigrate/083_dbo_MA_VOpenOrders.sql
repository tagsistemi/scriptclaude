-- Vista [dbo].[MA_VOpenOrders] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VOpenOrders')
BEGIN
    DROP VIEW [dbo].[MA_VOpenOrders]
    PRINT 'Vista [dbo].[MA_VOpenOrders] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VOpenOrders] AS SELECT
	MA_SaleOrdDetails.SaleOrdId,
	MA_SaleOrd.Customer,
	MA_SaleOrd.ContractNo,
	MA_SaleOrd.OrderDate,
    MA_SaleOrd.OpenOrder,
	MA_SaleOrdDetails.Line,
	MA_SaleOrdDetails.Position,
    MA_SaleOrdDetails.Item,
	MA_SaleOrdDetails.Qty,
	MA_SaleOrdDetails.ExpectedDeliveryDate,
    MA_SaleOrdDetails.DeliveredQty,
	MA_SaleOrdDetails.ConfirmationLevel,
	MA_SaleOrdDetails.Cancelled,
	MA_SaleOrdDetails.UoM,
	MA_SaleOrd.InternalOrdNo,
	MA_SaleOrdDetails.Notes
	FROM MA_SaleOrd INNER JOIN MA_SaleOrdDetails 
					ON MA_SaleOrd.SaleOrdId = MA_SaleOrdDetails.SaleOrdId
		AND MA_SaleOrd.OpenOrder = '1'
GO

PRINT 'Vista [dbo].[MA_VOpenOrders] creata con successo'
GO

