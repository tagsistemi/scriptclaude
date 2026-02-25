-- Vista [dbo].[VIEW_ORDFOR_CENTRI_ORIGINALE] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VIEW_ORDFOR_CENTRI_ORIGINALE')
BEGIN
    DROP VIEW [dbo].[VIEW_ORDFOR_CENTRI_ORIGINALE]
    PRINT 'Vista [dbo].[VIEW_ORDFOR_CENTRI_ORIGINALE] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VIEW_ORDFOR_CENTRI_ORIGINALE]
AS
SELECT DISTINCT 
                      dbo.MA_PurchaseOrd.OrderDate, dbo.MA_PurchaseOrd.InternalOrdNo, dbo.MA_PurchaseOrd.Supplier, dbo.MA_PurchaseOrd.ExpectedDeliveryDate, 
                      dbo.MA_PurchaseOrd.Payment, dbo.MA_PaymentTerms.Description AS DescriCondPag, dbo.MA_PurchaseOrdSummary.TotalAmount, 
                      dbo.MA_PurchaseOrdDetails.CostCenter, dbo.MA_CustSupp.CompanyName, dbo.MA_CostCenters.Description AS DescriCentro, 
                      dbo.MA_PurchaseOrdSummary.TaxableAmount, dbo.MA_CostCenters.GroupCode, 'Note' AS Notes
FROM         dbo.MA_PurchaseOrd INNER JOIN
                      dbo.MA_PurchaseOrdDetails ON dbo.MA_PurchaseOrd.PurchaseOrdId = dbo.MA_PurchaseOrdDetails.PurchaseOrdId INNER JOIN
                      dbo.MA_PurchaseOrdSummary ON dbo.MA_PurchaseOrd.PurchaseOrdId = dbo.MA_PurchaseOrdSummary.PurchaseOrdId INNER JOIN
                      dbo.MA_PaymentTerms ON dbo.MA_PurchaseOrd.Payment = dbo.MA_PaymentTerms.Payment INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_PurchaseOrd.CustSuppType = dbo.MA_CustSupp.CustSuppType AND 
                      dbo.MA_PurchaseOrd.Supplier = dbo.MA_CustSupp.CustSupp INNER JOIN
                      dbo.MA_CostCenters ON dbo.MA_PurchaseOrdDetails.CostCenter = dbo.MA_CostCenters.CostCenter
WHERE     (dbo.MA_PurchaseOrdDetails.CostCenter <> '')
GO

PRINT 'Vista [dbo].[VIEW_ORDFOR_CENTRI_ORIGINALE] creata con successo'
GO

