-- Vista [dbo].[mp_QVendAgReg] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'mp_QVendAgReg')
BEGIN
    DROP VIEW [dbo].[mp_QVendAgReg]
    PRINT 'Vista [dbo].[mp_QVendAgReg] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[mp_QVendAgReg]
AS
SELECT     dbo.MA_SaleDoc.CustSupp, dbo.MA_SaleDoc.DocumentType, dbo.MA_SaleDoc.DocNo, dbo.MA_SaleDoc.DocumentDate, 
                      dbo.MA_SaleDoc.CustSuppType, dbo.MA_SaleDoc.DepartureDate, dbo.MA_SaleDoc.Issued, dbo.MA_SaleDoc.Payment, 
                      dbo.MA_SaleDoc.PostedToAccounting, dbo.MA_SaleDoc.PostedToInventory, dbo.MA_SaleDoc.Printed, dbo.MA_SaleDoc.SaleDocId, 
                      dbo.MA_SaleDoc.Salesperson, dbo.MA_SalesPeople.Name, dbo.MA_SaleDocSummary.TotalAmount, dbo.MA_CustSupp.CompanyName, 
                      dbo.MA_CustSupp.Region, dbo.MA_SaleDoc.TaxJournal, dbo.MA_SaleDocSummary.TaxableAmount, dbo.MA_SaleDoc.IncludedInTurnover
FROM         dbo.MA_SaleDoc INNER JOIN
                      dbo.MA_SaleDocSummary ON dbo.MA_SaleDoc.SaleDocId = dbo.MA_SaleDocSummary.SaleDocId INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_SaleDoc.CustSuppType = dbo.MA_CustSupp.CustSuppType AND 
                      dbo.MA_SaleDoc.CustSupp = dbo.MA_CustSupp.CustSupp LEFT OUTER JOIN
                      dbo.MA_SalesPeople ON dbo.MA_SaleDoc.Salesperson = dbo.MA_SalesPeople.Salesperson
GO

PRINT 'Vista [dbo].[mp_QVendAgReg] creata con successo'
GO

