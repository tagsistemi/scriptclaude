-- Vista [dbo].[docviewtexigom] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'docviewtexigom')
BEGIN
    DROP VIEW [dbo].[docviewtexigom]
    PRINT 'Vista [dbo].[docviewtexigom] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[docviewtexigom]
AS
SELECT     TexigomSqlNet.dbo.MA_SaleDoc.DocumentType, TexigomSqlNet.dbo.MA_SaleDoc.DocumentDate, TexigomSqlNet.dbo.MA_SaleDoc.CustSupp, 
                      TexigomSqlNet.dbo.MA_CustSupp.CompanyName, TexigomSqlNet.dbo.MA_SaleDocSummary.TaxableAmount, 
                      TexigomSqlNet.dbo.MA_SaleDocSummary.TotalAmount, TexigomSqlNet.dbo.MA_CustSupp.CustSuppType, 
                      TexigomSqlNet.dbo.MA_CustSupp.TaxIdNumber
FROM         TexigomSqlNet.dbo.MA_SaleDoc INNER JOIN
                      TexigomSqlNet.dbo.MA_SaleDocSummary ON 
                      TexigomSqlNet.dbo.MA_SaleDoc.SaleDocId = TexigomSqlNet.dbo.MA_SaleDocSummary.SaleDocId INNER JOIN
                      TexigomSqlNet.dbo.MA_CustSupp ON TexigomSqlNet.dbo.MA_SaleDoc.CustSupp = TexigomSqlNet.dbo.MA_CustSupp.CustSupp
WHERE     (TexigomSqlNet.dbo.MA_SaleDoc.DocumentType = 3407874 OR
                      TexigomSqlNet.dbo.MA_SaleDoc.DocumentType = 3407875 OR
                      TexigomSqlNet.dbo.MA_SaleDoc.DocumentType = 3407876) AND (TexigomSqlNet.dbo.MA_CustSupp.CustSuppType = 3211264)
GO

PRINT 'Vista [dbo].[docviewtexigom] creata con successo'
GO

