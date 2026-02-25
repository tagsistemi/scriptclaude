-- Vista [dbo].[Vista_costoimballoordini] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_costoimballoordini')
BEGIN
    DROP VIEW [dbo].[Vista_costoimballoordini]
    PRINT 'Vista [dbo].[Vista_costoimballoordini] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_costoimballoordini]
AS
SELECT DISTINCT 
                      TOP (100) PERCENT dbo.MA_SaleOrd.InternalOrdNo, dbo.MA_SaleOrd.OrderDate, dbo.MA_SaleOrd.Customer, dbo.MA_CustSupp.CompanyName, 
                      dbo.MA_SaleOrdSummary.TaxableAmount, dbo.MA_SaleOrdSummary.PackagingCharges, dbo.MA_SaleOrdSummary.AdditionalCharges
FROM         dbo.MA_SaleOrd INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleOrd.CustSuppType = dbo.MA_CustSupp.CustSuppType AND 
                      dbo.MA_SaleOrd.Customer = dbo.MA_CustSupp.CustSupp INNER JOIN
                      dbo.MA_SaleOrdSummary ON dbo.MA_SaleOrd.SaleOrdId = dbo.MA_SaleOrdSummary.SaleOrdId
WHERE     (dbo.MA_SaleOrdSummary.PackagingCharges > 0) OR
                      (dbo.MA_SaleOrdSummary.AdditionalCharges > 0)
ORDER BY dbo.MA_SaleOrd.Customer, dbo.MA_SaleOrd.InternalOrdNo
GO

PRINT 'Vista [dbo].[Vista_costoimballoordini] creata con successo'
GO

