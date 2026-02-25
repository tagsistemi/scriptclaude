-- Vista [dbo].[ordforcommesse] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'ordforcommesse')
BEGIN
    DROP VIEW [dbo].[ordforcommesse]
    PRINT 'Vista [dbo].[ordforcommesse] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[ordforcommesse]
AS
SELECT dbo.MA_PurchaseOrdDetails.Line, dbo.MA_PurchaseOrdDetails.Position, dbo.MA_PurchaseOrd.Supplier, dbo.MA_PurchaseOrdDetails.Job, dbo.MA_PurchaseOrdDetails.Item, dbo.MA_PurchaseOrdDetails.Description, 
                  dbo.MA_PurchaseOrdDetails.UoM, dbo.MA_PurchaseOrdDetails.Qty, dbo.MA_PurchaseOrdDetails.UnitValue, dbo.MA_PurchaseOrdDetails.TaxableAmount, dbo.MA_PurchaseOrdDetails.TaxCode, 
                  dbo.MA_PurchaseOrdDetails.TotalAmount, dbo.MA_PurchaseOrdDetails.LineType, dbo.MA_PurchaseOrd.InternalOrdNo, dbo.MA_PurchaseOrd.ExternalOrdNo, dbo.MA_PurchaseOrd.CustSuppType, 
                  dbo.MA_CustSupp.CompanyName, dbo.MA_PurchaseOrdDetails.CostCenter, dbo.MA_PurchaseOrd.OrderDate, dbo.MA_PurchaseOrdDetails.DeliveredQty, dbo.MA_PurchaseOrd.Cancelled
FROM     dbo.MA_PurchaseOrd INNER JOIN
                  dbo.MA_PurchaseOrdDetails ON dbo.MA_PurchaseOrd.PurchaseOrdId = dbo.MA_PurchaseOrdDetails.PurchaseOrdId INNER JOIN
                  dbo.MA_CustSupp ON dbo.MA_PurchaseOrd.CustSuppType = dbo.MA_CustSupp.CustSuppType AND dbo.MA_PurchaseOrd.Supplier = dbo.MA_CustSupp.CustSupp
WHERE  (dbo.MA_PurchaseOrd.Cancelled = '0')
GO

PRINT 'Vista [dbo].[ordforcommesse] creata con successo'
GO

