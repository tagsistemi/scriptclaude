-- Vista [dbo].[VwIxW_OffForRighe] - Aggiornamento
-- Generato: 2026-02-23 21:30:43

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VwIxW_OffForRighe')
BEGIN
    DROP VIEW [dbo].[VwIxW_OffForRighe]
    PRINT 'Vista [dbo].[VwIxW_OffForRighe] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VwIxW_OffForRighe] AS  SELECT Supplier, SuppQuotaId, Item, DiscountFormula, UnitValue,  SUM(Qty)  AS SumQuantita,  SUM(TaxableAmount)  AS SumImponibile,  SUM(DiscountAmount)  AS SumImpSconto FROM MA_SuppQuotasDetail GROUP BY Supplier, SuppQuotaId, Item, DiscountFormula, UnitValue
GO

PRINT 'Vista [dbo].[VwIxW_OffForRighe] creata con successo'
GO

