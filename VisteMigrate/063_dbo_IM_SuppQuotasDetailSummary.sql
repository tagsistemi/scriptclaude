-- Vista [dbo].[IM_SuppQuotasDetailSummary] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_SuppQuotasDetailSummary')
BEGIN
    DROP VIEW [dbo].[IM_SuppQuotasDetailSummary]
    PRINT 'Vista [dbo].[IM_SuppQuotasDetailSummary] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_SuppQuotasDetailSummary] AS  
	SELECT 	IM_SuppQuotasDetails.Item, 
		IM_SuppQuotasDetails.Supplier, 
		IM_SuppQuotasDetails.SuppQuotaId, 
		IM_SuppQuotasDetails.DiscountFormula, 
		IM_SuppQuotasDetails.SumQuantity, 
		IM_SuppQuotasDetails.UnitValue, 
		IM_SuppQuotasDetails.SumTaxableAmount, 
		IM_SuppQuotasDetails.SumDiscountAmount,
		IM_SuppQuotasSummary.FurtherDiscount 
	FROM IM_SuppQuotasDetails LEFT OUTER JOIN IM_SuppQuotasSummary ON 
	IM_SuppQuotasDetails.SuppQuotaId = IM_SuppQuotasSummary.SuppQuotaId
GO

PRINT 'Vista [dbo].[IM_SuppQuotasDetailSummary] creata con successo'
GO

