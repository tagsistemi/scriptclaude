-- Vista [dbo].[IM_PurchReqGenDocRefSuppQuota] - Creazione
-- Generato: 2026-02-23 21:30:36

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[IM_PurchReqGenDocRefSuppQuota] AS  
	SELECT 	IM_PurchReqGenDocRefPRDetails.DocNo, 
		IM_PurchReqGenDocRefPRDetails.DocId, 
		IM_PurchReqGenDocRefPRDetails.Item, 
		IM_PurchReqGenDocRefPRDetails.Description, 
		IM_PurchReqGenDocRefPRDetails.UoM, 
		IM_PurchReqGenDocRefPRDetails.Producer, 
		IM_PurchReqGenDocRefPRDetails.ProductCtg, 
		IM_PurchReqGenDocRefPRDetails.ProductSubCtg, 
		IM_PurchReqGenDocRefPRDetails.PurchaseRequestNo, 
		IM_PurchReqGenDocRefPRDetails.PurchaseRequestId, 
		IM_PurchReqGenDocRefPRDetails.Simulation, 
		IM_SuppQuotasDetailSummary.Supplier, 
		IM_SuppQuotasDetailSummary.DiscountFormula, 
		IM_SuppQuotasDetailSummary.SumQuantity, 
		IM_SuppQuotasDetailSummary.UnitValue, 
		IM_SuppQuotasDetailSummary.SumTaxableAmount, 
		IM_SuppQuotasDetailSummary.SumDiscountAmount, 
		IM_SuppQuotasDetailSummary.FurtherDiscount 
	FROM 	IM_PurchReqGenDocRefPRDetails LEFT OUTER JOIN IM_SuppQuotasDetailSummary ON 
		IM_PurchReqGenDocRefPRDetails.DocId 	= IM_SuppQuotasDetailSummary.SuppQuotaId AND 
		IM_PurchReqGenDocRefPRDetails.Item 	= IM_SuppQuotasDetailSummary.Item
GO

PRINT 'Vista [dbo].[IM_PurchReqGenDocRefSuppQuota] creata con successo'
GO

