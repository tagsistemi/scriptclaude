-- Vista [dbo].[IM_SuppQuotasSummary] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_SuppQuotasSummary')
BEGIN
    DROP VIEW [dbo].[IM_SuppQuotasSummary]
    PRINT 'Vista [dbo].[IM_SuppQuotasSummary] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_SuppQuotasSummary] AS  
	SELECT 	MA_SuppQuotasSummary.SuppQuotaId, 
		MA_SuppQuotasSummary.GoodsAmount, 
		MA_SuppQuotasSummary.ServiceAmounts, 
		MA_SuppQuotasSummary.DiscountOnGoods, 
		MA_SuppQuotasSummary.DiscountOnServices, 
		MA_SuppQuotasSummary.Discounts, 
		MA_SuppQuotasSummary.Allowances, 
		MA_SuppQuotasSummary.Advance, 
		MA_SuppQuotasSummary.Discounts / (MA_SuppQuotasSummary.GoodsAmount + MA_SuppQuotasSummary.ServiceAmounts) * 100 AS FurtherDiscount
	FROM MA_SuppQuotasSummary 
	WHERE MA_SuppQuotasSummary.SuppQuotaId IN 
		(SELECT MA_SuppQuotasSummary.SuppQuotaId 
		 FROM 	MA_SuppQuotasSummary 
		 WHERE (MA_SuppQuotasSummary.GoodsAmount + MA_SuppQuotasSummary.ServiceAmounts <> 0))
GO

PRINT 'Vista [dbo].[IM_SuppQuotasSummary] creata con successo'
GO

