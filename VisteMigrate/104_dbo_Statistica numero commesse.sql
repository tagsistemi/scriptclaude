-- Vista [dbo].[Statistica numero commesse] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Statistica numero commesse')
BEGIN
    DROP VIEW [dbo].[Statistica numero commesse]
    PRINT 'Vista [dbo].[Statistica numero commesse] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Statistica numero commesse]
AS
SELECT     dbo.MA_SaleOrd.OrderDate, dbo.MA_SaleOrd.InternalOrdNo, dbo.MA_SaleOrd.Currency, dbo.MA_SaleOrd.SaleOrdId, 
                      dbo.MA_SaleOrdSummary.TaxableAmount AS Expr1, YEAR(dbo.MA_SaleOrd.OrderDate) AS anno, dbo.MA_SaleOrd.InvRsn
FROM         dbo.MA_SaleOrd INNER JOIN
                      dbo.MA_SaleOrdSummary ON dbo.MA_SaleOrd.SaleOrdId = dbo.MA_SaleOrdSummary.SaleOrdId
WHERE     (YEAR(dbo.MA_SaleOrd.OrderDate) = 2014) AND (dbo.MA_SaleOrdSummary.TaxableAmount > 250) AND (LEFT(dbo.MA_SaleOrd.InvRsn, 3) = 'VEN' OR
                      LEFT(dbo.MA_SaleOrd.InvRsn, 2) = 'FO')
GO

PRINT 'Vista [dbo].[Statistica numero commesse] creata con successo'
GO

