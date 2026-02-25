-- Vista [dbo].[MA_VWMSaleOrdersPreShipping] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VWMSaleOrdersPreShipping')
BEGIN
    DROP VIEW [dbo].[MA_VWMSaleOrdersPreShipping]
    PRINT 'Vista [dbo].[MA_VWMSaleOrdersPreShipping] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VWMSaleOrdersPreShipping] AS SELECT
	MA_WMPreShippingDetails.PreShippingID,
	MA_WMPreShippingDetails.PreShippingSubID,
	MA_WMPreShippingDetails.PreShippingType,
	MA_WMPreShippingDetails.PreShippingDate,
	MA_WMPreShippingDetails.PreShippingLine,
	MA_WMPreShippingDetails.CRRefID,
	MA_WMPreShippingDetails.CRRefSubID,
	MA_WMPreShippingDetails.CustSuppType,
	MA_WMPreShippingDetails.CustSupp,
	MA_WMPreShippingDetails.Storage,
	MA_WMPreShippingDetails.Zone,
	MA_WMPreShippingDetails.Item,
	MA_WMPreShippingDetails.Description,
	MA_WMPreShippingDetails.UnitOfMeasure,
	MA_WMPreShippingDetails.Lot,
	MA_WMPreShippingDetails.InternalIdNo,
	MA_WMPreShippingDetails.ConsignmentPartner,
	MA_WMPreShippingDetails.Qty,
	MA_WMPreShippingDetails.PickingRequestQty,
	MA_WMPreShippingDetails.PickedQty,
	MA_WMPreShippingDetails.QtyToDeliver,
	MA_WMPreShippingDetails.QtyDelivered,
	MA_WMPreShippingDetails.TOGenerated,
	MA_WMPreShippingDetails.TOConfirmed,
	MA_WMPreShippingDetails.DeliveryDocumentGenerated,
	MA_WMPreShippingDetails.Cancelled,
	MA_WMPreShippingDetails.NotTransactable,
	MA_WMPreShippingDetails.ExpectedDeliveryDate,
	MA_WMPreShippingDetails.ConfirmedDeliveryDate,
	MA_WMPreShippingDetails.Carrier,
	MA_WMPreShippingDetails.ShipToAddress,
	MA_WMPreShippingDetails.Port,
	MA_WMPreShippingDetails.Transport,
	MA_WMPreShippingDetails.Package,
	MA_WMPreShippingDetails.IsABOM,
	MA_WMPreShippingDetails.NoInvoice,
	MA_WMPreShippingDetails.NoPrint,
	MA_WMPreShippingDetails.InvoiceTypes,
	MA_WMPreShipping.DestinationStorage,
	MA_WMPreShipping.PreShippingNo,
	MA_SaleOrd.InvoicingCustomer,
	MA_SaleOrd.Payment,
	MA_SaleOrd.TaxJournal,
	MA_SaleOrd.StubBook,
	MA_SaleOrd.Currency,
	MA_SaleOrd.Salesperson,
	MA_SaleOrd.AreaManager,
	MA_SaleOrd.SalespersonPolicy,
	MA_SaleOrd.AreaManagerPolicy,
	MA_SaleOrd.SalespersonCommAuto,
	MA_SaleOrd.AreaManagerCommAuto,
	MA_SaleOrd.SalespersonCommPercAuto,
	MA_SaleOrd.AreaManagerCommPercAuto,
	MA_SaleOrd.Area,
	MA_SaleOrd.InvRsn,
	MA_SaleOrd.Job,
	MA_SaleOrd.SendDocumentsTo,
	MA_SaleOrd.ShippingReason,
	MA_SaleOrd.InternalOrdNo,
	MA_SaleOrd.ContractCode,
	MA_SaleOrd.ProjectCode,
	MA_SaleOrd.TaxCommunicationGroup
	FROM MA_WMPreShippingDetails 
	INNER JOIN MA_WMPreShipping ON MA_WMPreShippingDetails.PreShippingID = MA_WMPreShipping.PreShippingID
	LEFT OUTER JOIN MA_SaleOrd ON MA_WMPreShippingDetails.CRRefID = MA_SaleOrd.SaleOrdId
    WHERE MA_WMPreShippingDetails.DeliveryDocumentGenerated = '0' AND MA_WMPreShippingDetails.Cancelled = '0' AND MA_WMPreShippingDetails.QtyToDeliver > 0.0
GO

PRINT 'Vista [dbo].[MA_VWMSaleOrdersPreShipping] creata con successo'
GO

