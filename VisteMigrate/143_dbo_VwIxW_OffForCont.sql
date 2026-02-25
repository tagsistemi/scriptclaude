-- Vista [dbo].[VwIxW_OffForCont] - Aggiornamento
-- Generato: 2026-02-23 21:30:43

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VwIxW_OffForCont')
BEGIN
    DROP VIEW [dbo].[VwIxW_OffForCont]
    PRINT 'Vista [dbo].[VwIxW_OffForCont] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VwIxW_OffForCont] AS  SELECT SuppQuotaId, GoodsAmount, ServiceAmounts, DiscountOnGoods AS TotSMerce, DiscountOnServices AS TotScServizi, Discounts AS TotImpSconto, Allowances AS TotImpAbbuoni, Advance AS TotImpAcconti, Discounts / (GoodsAmount + ServiceAmounts) * 100 AS UlterioreSconto FROM MA_SuppQuotasSummary WHERE SuppQuotaId IN (SELECT SuppQuotaId FROM MA_SuppQuotasSummary WHERE (GoodsAmount + ServiceAmounts <> 0))
GO

PRINT 'Vista [dbo].[VwIxW_OffForCont] creata con successo'
GO

