-- Vista [dbo].[IM_SuppQuotasDetails] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_SuppQuotasDetails')
BEGIN
    DROP VIEW [dbo].[IM_SuppQuotasDetails]
    PRINT 'Vista [dbo].[IM_SuppQuotasDetails] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_SuppQuotasDetails] AS  
	SELECT 	MA_SuppQuotasDetail.Supplier, 
		MA_SuppQuotasDetail.SuppQuotaId, 
		MA_SuppQuotasDetail.Item, 
		MA_SuppQuotasDetail.DiscountFormula, 
		MA_SuppQuotasDetail.UnitValue,  
		SUM(MA_SuppQuotasDetail.Qty)  			AS SumQuantity,  
		SUM(MA_SuppQuotasDetail.TaxableAmount) 	AS SumTaxableAmount,  
		SUM(MA_SuppQuotasDetail.DiscountAmount) AS SumDiscountAmount 
	FROM MA_SuppQuotasDetail 
	GROUP BY MA_SuppQuotasDetail.Supplier, 
		MA_SuppQuotasDetail.SuppQuotaId, 
		MA_SuppQuotasDetail.Item, 
		MA_SuppQuotasDetail.DiscountFormula, 
		MA_SuppQuotasDetail.UnitValue
GO

PRINT 'Vista [dbo].[IM_SuppQuotasDetails] creata con successo'
GO

