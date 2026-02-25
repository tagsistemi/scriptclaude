-- Vista [dbo].[Vista_ExportFatture] - Creazione
-- Generato: 2026-02-23 21:30:41

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[Vista_ExportFatture]
AS
SELECT     TOP (100) PERCENT dbo.MA_SaleDoc.CustSupp, dbo.MA_SaleDoc.CustSuppType, dbo.MA_CustSupp.CompanyName, dbo.MA_CustSupp.TaxIdNumber, 
                      dbo.MA_SaleDoc.DocNo, dbo.MA_SaleDoc.DocumentDate, dbo.MA_CustSupp.Language, dbo.MA_SaleDoc.Payment, dbo.MA_SaleDoc.CustomerBank, 
                      dbo.MA_SaleDoc.CompanyBank, dbo.MA_SaleDoc.AccTpl, dbo.MA_SaleDocSummary.TaxableAmount, dbo.MA_SaleDocSummary.TaxAmount, 
                      dbo.MA_SaleDocSummary.TotalAmount, dbo.MA_SaleDoc.DocumentType, dbo.MA_SaleDoc.Currency, dbo.MA_CustSupp.CustSuppKind, 
                      RIGHT(dbo.MA_SaleDoc.DocNo, 3) AS divisione, dbo.MA_SaleDoc.esportata, dbo.MA_SaleDoc.Printed, dbo.MA_SaleDoc.SaleDocId, 
                      dbo.MA_SaleDoc.InvoicingAccGroup, dbo.MA_SaleDoc.EspNet, dbo.MA_SaleDoc.TaxJournal
FROM         dbo.MA_SaleDoc INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleDoc.CustSupp = dbo.MA_CustSupp.CustSupp AND 
                      dbo.MA_SaleDoc.CustSuppType = dbo.MA_CustSupp.CustSuppType INNER JOIN
                      dbo.MA_SaleDocSummary ON dbo.MA_SaleDoc.SaleDocId = dbo.MA_SaleDocSummary.SaleDocId
WHERE     (dbo.MA_SaleDoc.DocumentType = 3407874) OR
                      (dbo.MA_SaleDoc.DocumentType = 3407876)
ORDER BY dbo.MA_SaleDoc.DocNo
GO

PRINT 'Vista [dbo].[Vista_ExportFatture] creata con successo'
GO

