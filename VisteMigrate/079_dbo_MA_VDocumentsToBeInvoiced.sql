-- Vista [dbo].[MA_VDocumentsToBeInvoiced] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VDocumentsToBeInvoiced')
BEGIN
    DROP VIEW [dbo].[MA_VDocumentsToBeInvoiced]
    PRINT 'Vista [dbo].[MA_VDocumentsToBeInvoiced] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VDocumentsToBeInvoiced] AS SELECT
	MA_SaleDoc.SaleDocId,
	MA_SaleDoc.CustSupp,
	MA_SaleDoc.InvoicingCustomer,
	MA_SaleDoc.Job,
	MA_SaleDoc.ContractCode,
	MA_SaleDoc.ProjectCode,
	MA_SaleDoc.TaxCommunicationGroup,
	MA_SaleDoc.ShippingReason,
	MA_SaleDoc.ProFormaInvoiceID,
	MA_SaleDoc.SendDocumentsTo,
	MA_SaleDoc.Currency,
	MA_SaleDoc.InvoicingTaxJournal,
	MA_SaleDoc.InvoicingAccTpl,
	MA_SaleDoc.InvoicingAccGroup,
	MA_SaleDoc.NoChangeExigibility,
	MA_SaleDoc.Salesperson,
	MA_SaleDoc.AreaManager,
	MA_SaleDoc.SalespersonPolicy,
	MA_SaleDoc.AreaManagerPolicy,
	MA_SaleDoc.SalespersonCommAuto,
	MA_SaleDoc.AreaManagerCommAuto,
	MA_SaleDoc.Area,
	MA_SaleDoc.SalespersonCommPercAuto,
	MA_SaleDoc.AreaManagerCommPercAuto,
	MA_SaleDoc.DiscountFormula,
	MA_SaleDoc.DepartureDate,
	MA_SaleDoc.InvRsn,
	MA_SaleDoc.ShipToAddress,
	MA_SaleDoc.CustSuppType,
	MA_SaleDoc.StubBook,
	MA_SaleDoc.DocumentDate,
	MA_SaleDoc.DocNo,
	MA_SaleDoc.DocumentType,
	MA_SaleDoc.Issued,
	MA_SaleDoc.InvoiceFollows,
	MA_SaleDoc.Summarized,
	MA_SaleDoc.CorrectionDocument,
	MA_SaleDoc.InvoiceTypes,
	MA_SaleDocDetail.SaleDocId	AS SaleDocIdDetail,
	MA_SaleDocDetail.SubId,
	MA_SaleDocDetail.Line,
	MA_SaleDocDetail.LineType,
	MA_SaleDocDetail.PerishablesType,
	MA_SaleDocDetail.DistributedDiscount,
	MA_SaleDocDetail.DistributedShipCharges,
	MA_SaleDocDetail.DistributedAdvanceAmount,
	MA_SaleDocDetail.DistributedAdvanceAmount2,
	MA_SaleDocDetail.DistributedAdvanceAmount3,
	MA_SaleDocDetail.DistributedAllowances,
	MA_SaleDoc.Payment,
	CASE 
	WHEN MA_SaleDocDetail.PerishablesType = 28966912 THEN (select MA_CustSupp.PaymentPeriShablesWithin60 from MA_CustSupp WHERE MA_SaleDoc.InvoicingCustomer = MA_CustSupp.CustSupp AND MA_CustSupp.CustSuppType = 3211264)
	WHEN MA_SaleDocDetail.PerishablesType = 28966913 THEN (select MA_CustSupp.PaymentPeriShablesOver60 from MA_CustSupp WHERE MA_SaleDoc.InvoicingCustomer = MA_CustSupp.CustSupp AND MA_CustSupp.CustSuppType = 3211264)
	WHEN MA_SaleDocDetail.PerishablesType = 28966914 THEN MA_SaleDoc.Payment
	END AS PaymentForBreak
	FROM MA_SaleDocDetail INNER JOIN
    MA_SaleDoc ON MA_SaleDocDetail.SaleDocId = MA_SaleDoc.SaleDocId
    WHERE (MA_SaleDoc.DocumentType = 3407873 OR MA_SaleDoc.DocumentType = 3407879) AND MA_SaleDocDetail.Invoiced = '0' AND MA_SaleDocDetail.NoInvoice = '0'
	AND MA_SaleDoc.Summarized = '0' AND MA_SaleDoc.Issued = '1' AND MA_SaleDoc.InvoiceFollows = '1'
GO

PRINT 'Vista [dbo].[MA_VDocumentsToBeInvoiced] creata con successo'
GO

