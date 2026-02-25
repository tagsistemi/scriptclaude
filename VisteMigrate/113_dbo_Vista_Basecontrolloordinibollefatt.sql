-- Vista [dbo].[Vista_Basecontrolloordinibollefatt] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_Basecontrolloordinibollefatt')
BEGIN
    DROP VIEW [dbo].[Vista_Basecontrolloordinibollefatt]
    PRINT 'Vista [dbo].[Vista_Basecontrolloordinibollefatt] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_Basecontrolloordinibollefatt]
AS
SELECT     dbo.MA_SaleOrdDetails.Job, dbo.MA_SaleOrdDetails.Item, dbo.MA_SaleOrdDetails.UoM, dbo.MA_SaleOrdDetails.Qty, 
                      dbo.MA_SaleDocDetail.Qty AS QtyBolla, dbo.MA_SaleOrdDetails.UnitValue AS ValoreUnitarioOrdine, 
                      dbo.MA_SaleOrdDetails.TaxableAmount AS TotaleRigaOrdine, dbo.MA_SaleDocDetail.UnitValue AS ValoreUnitarioBolla, 
                      dbo.MA_SaleDocDetail.TaxableAmount AS TotaleRigaBolla, dbo.MA_SaleOrdDetails.UnitValue - dbo.MA_SaleDocDetail.UnitValue AS diff, 
                      dbo.MA_SaleOrdDetails.Customer, dbo.MA_CustSupp.CompanyName, dbo.MA_CustSupp.CustSuppType, dbo.MA_SaleDoc.DocumentType, 
                      dbo.MA_SaleDoc.DocNo AS NrBolla, dbo.MA_SaleDoc.Summarized, dbo.MA_SaleDoc.SaleDocId, dbo.MA_SaleDoc.DocumentDate, 
                      dbo.MA_SaleDocDetail.Job AS commessabolla, dbo.Vista_Fatture.DocNo AS nrfattura, dbo.Vista_Fatture.DocumentDate AS datafattura, 
                      dbo.Vista_Fatture.TotalAmount AS TotaleRigaFattura, dbo.Vista_Fatture.UnitValue AS ValoreUnitarioRigaFattura
FROM         dbo.MA_SaleOrdDetails INNER JOIN
                      dbo.MA_SaleDocDetail ON dbo.MA_SaleOrdDetails.Item = dbo.MA_SaleDocDetail.Item AND 
                      dbo.MA_SaleOrdDetails.Job = dbo.MA_SaleDocDetail.Job AND dbo.MA_SaleOrdDetails.UnitValue <> dbo.MA_SaleDocDetail.UnitValue INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleOrdDetails.Customer = dbo.MA_CustSupp.CustSupp INNER JOIN
                      dbo.MA_SaleDoc ON dbo.MA_SaleDocDetail.SaleDocId = dbo.MA_SaleDoc.SaleDocId LEFT OUTER JOIN
                      dbo.Vista_Fatture ON dbo.MA_SaleDocDetail.Item = dbo.Vista_Fatture.Item AND dbo.MA_SaleDocDetail.Job = dbo.Vista_Fatture.Job
WHERE     (dbo.MA_CustSupp.CustSuppType = 3211264) AND (dbo.MA_SaleDoc.DocumentType = 3407873)
GO

PRINT 'Vista [dbo].[Vista_Basecontrolloordinibollefatt] creata con successo'
GO

