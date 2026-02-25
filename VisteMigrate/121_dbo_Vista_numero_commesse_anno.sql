-- Vista [dbo].[Vista_numero_commesse_anno] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_numero_commesse_anno')
BEGIN
    DROP VIEW [dbo].[Vista_numero_commesse_anno]
    PRINT 'Vista [dbo].[Vista_numero_commesse_anno] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_numero_commesse_anno]
AS
SELECT     dbo.MA_SaleOrd.SaleOrdId, dbo.MA_SaleOrd.Job, dbo.MA_SaleOrdSummary.TaxableAmount, dbo.MA_SaleOrd.OrderDate
FROM         dbo.MA_SaleOrd INNER JOIN
                      dbo.MA_SaleOrdSummary ON dbo.MA_SaleOrd.SaleOrdId = dbo.MA_SaleOrdSummary.SaleOrdId
WHERE     (dbo.MA_SaleOrd.OrderDate > CONVERT(DATETIME, '2010-12-31 00:00:00', 102)) AND (dbo.MA_SaleOrd.OrderDate < CONVERT(DATETIME, 
                      '2012-01-01 00:00:00', 102)) AND (dbo.MA_SaleOrdSummary.TaxableAmount < 100)
GO

PRINT 'Vista [dbo].[Vista_numero_commesse_anno] creata con successo'
GO

