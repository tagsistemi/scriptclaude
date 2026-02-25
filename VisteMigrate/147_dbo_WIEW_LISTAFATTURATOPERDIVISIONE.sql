-- Vista [dbo].[WIEW_LISTAFATTURATOPERDIVISIONE] - Aggiornamento
-- Generato: 2026-02-23 21:30:43

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'WIEW_LISTAFATTURATOPERDIVISIONE')
BEGIN
    DROP VIEW [dbo].[WIEW_LISTAFATTURATOPERDIVISIONE]
    PRINT 'Vista [dbo].[WIEW_LISTAFATTURATOPERDIVISIONE] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[WIEW_LISTAFATTURATOPERDIVISIONE]
AS
SELECT     dbo.MA_CustSupp.CompanyName, dbo.MA_SaleDoc.DocumentType, dbo.MA_SaleDoc.DocNo, dbo.MA_SaleDoc.DocumentDate, 
                      dbo.MA_SaleDoc.TaxJournal, dbo.MA_SaleDocSummary.TaxableAmount, dbo.MA_SaleDocSummary.TaxAmount, 
                      dbo.MA_SaleDocSummary.TotalAmount, dbo.MA_SaleDoc.CustSupp
FROM         dbo.MA_SaleDoc INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleDoc.CustSuppType = dbo.MA_CustSupp.CustSuppType AND 
                      dbo.MA_SaleDoc.CustSupp = dbo.MA_CustSupp.CustSupp INNER JOIN
                      dbo.MA_SaleDocSummary ON dbo.MA_SaleDoc.SaleDocId = dbo.MA_SaleDocSummary.SaleDocId
WHERE     (dbo.MA_SaleDoc.DocumentType = 3407874) OR
                      (dbo.MA_SaleDoc.DocumentType = 3407876)
GO

PRINT 'Vista [dbo].[WIEW_LISTAFATTURATOPERDIVISIONE] creata con successo'
GO

