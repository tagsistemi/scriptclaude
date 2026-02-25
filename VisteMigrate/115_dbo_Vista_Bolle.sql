-- Vista [dbo].[Vista_Bolle] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_Bolle')
BEGIN
    DROP VIEW [dbo].[Vista_Bolle]
    PRINT 'Vista [dbo].[Vista_Bolle] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_Bolle]
AS
SELECT     dbo.MA_SaleDoc.DocumentType, dbo.MA_SaleDoc.DocNo, dbo.MA_SaleDoc.DocumentDate, dbo.MA_SaleDocDetail.Item, dbo.MA_SaleDocDetail.Job, 
                      dbo.MA_SaleDocDetail.Qty, dbo.MA_SaleDocDetail.UnitValue, dbo.MA_SaleDocDetail.TaxableAmount, dbo.MA_SaleDocDetail.TotalAmount
FROM         dbo.MA_SaleDoc INNER JOIN
                      dbo.MA_SaleDocDetail ON dbo.MA_SaleDoc.SaleDocId = dbo.MA_SaleDocDetail.SaleDocId
WHERE     (dbo.MA_SaleDoc.DocumentType = 3407873)
GO

PRINT 'Vista [dbo].[Vista_Bolle] creata con successo'
GO

