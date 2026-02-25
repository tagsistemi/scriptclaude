-- Vista [dbo].[docviewoikos] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'docviewoikos')
BEGIN
    DROP VIEW [dbo].[docviewoikos]
    PRINT 'Vista [dbo].[docviewoikos] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[docviewoikos]
AS
SELECT     OikosNet.dbo.MA_SaleDoc.DocumentType, OikosNet.dbo.MA_SaleDoc.DocumentDate, OikosNet.dbo.MA_SaleDoc.CustSupp, 
                      OikosNet.dbo.MA_CustSupp.CompanyName, OikosNet.dbo.MA_SaleDocSummary.TaxableAmount, OikosNet.dbo.MA_SaleDocSummary.TotalAmount, 
                      OikosNet.dbo.MA_CustSupp.CustSuppType, OikosNet.dbo.MA_CustSupp.TaxIdNumber
FROM         OikosNet.dbo.MA_SaleDoc INNER JOIN
                      OikosNet.dbo.MA_SaleDocSummary ON OikosNet.dbo.MA_SaleDoc.SaleDocId = OikosNet.dbo.MA_SaleDocSummary.SaleDocId INNER JOIN
                      OikosNet.dbo.MA_CustSupp ON OikosNet.dbo.MA_SaleDoc.CustSupp = OikosNet.dbo.MA_CustSupp.CustSupp
WHERE     (OikosNet.dbo.MA_SaleDoc.DocumentType = 3407874 OR
                      OikosNet.dbo.MA_SaleDoc.DocumentType = 3407875 OR
                      OikosNet.dbo.MA_SaleDoc.DocumentType = 3407876) AND (OikosNet.dbo.MA_CustSupp.CustSuppType = 3211264)
GO

PRINT 'Vista [dbo].[docviewoikos] creata con successo'
GO

