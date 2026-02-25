-- Vista [dbo].[scadordbase1] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'scadordbase1')
BEGIN
    DROP VIEW [dbo].[scadordbase1]
    PRINT 'Vista [dbo].[scadordbase1] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[scadordbase1]
AS
SELECT     dbo.scadordbase.Riga, dbo.scadordbase.Posiz, dbo.scadordbase.DataOrdine, dbo.scadordbase.ExpectedDeliveryDate, dbo.scadordbase.Imponibile, 
                      dbo.scadordbase.Totale, dbo.scadordbase.PurchaseOrdId, dbo.MA_PurchaseOrdPymtSched.DueDateDays, 
                      dbo.MA_PurchaseOrdPymtSched.InstallmentType, 
                      dbo.scadordbase.ExpectedDeliveryDate + dbo.MA_PurchaseOrdPymtSched.DueDateDays AS dtaprevpag, 
                      MONTH(dbo.scadordbase.ExpectedDeliveryDate + dbo.MA_PurchaseOrdPymtSched.DueDateDays) AS mese, 
                      YEAR(dbo.scadordbase.ExpectedDeliveryDate + dbo.MA_PurchaseOrdPymtSched.DueDateDays) AS anno, dbo.MA_PurchaseOrd.Supplier, 
                      dbo.MA_CustSupp.CompanyName, dbo.MA_CustSupp.CustSuppType, dbo.MA_PurchaseOrd.ExternalOrdNo, dbo.MA_PurchaseOrd.InternalOrdNo, 
                      dbo.MA_PurchaseOrd.Payment, dbo.MA_PaymentTerms.NoOfInstallments, 
                      (CASE dbo.MA_PurchaseOrdPymtSched.InstallmentType WHEN 2686981 THEN 'RB' ELSE 'RD' END) AS TPF
FROM         dbo.scadordbase INNER JOIN
                      dbo.MA_PurchaseOrdPymtSched ON dbo.scadordbase.PurchaseOrdId = dbo.MA_PurchaseOrdPymtSched.PurchaseOrdId INNER JOIN
                      dbo.MA_PurchaseOrd ON dbo.MA_PurchaseOrdPymtSched.PurchaseOrdId = dbo.MA_PurchaseOrd.PurchaseOrdId INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_PurchaseOrd.Supplier = dbo.MA_CustSupp.CustSupp INNER JOIN
                      dbo.MA_PaymentTerms ON dbo.MA_PurchaseOrd.Payment = dbo.MA_PaymentTerms.Payment
WHERE     (dbo.MA_CustSupp.CustSuppType = 3211265) AND (dbo.MA_PurchaseOrd.Notes NOT LIKE 'SB')
GO

PRINT 'Vista [dbo].[scadordbase1] creata con successo'
GO

