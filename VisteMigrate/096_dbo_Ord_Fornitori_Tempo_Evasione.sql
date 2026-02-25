-- Vista [dbo].[Ord_Fornitori_Tempo_Evasione] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Ord_Fornitori_Tempo_Evasione')
BEGIN
    DROP VIEW [dbo].[Ord_Fornitori_Tempo_Evasione]
    PRINT 'Vista [dbo].[Ord_Fornitori_Tempo_Evasione] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Ord_Fornitori_Tempo_Evasione]
AS
SELECT TOP (100) PERCENT dbo.MA_PurchaseOrd.InternalOrdNo AS NoOrd, dbo.MA_PurchaseOrd.Supplier AS CodiceFornitore, 
               dbo.MA_CustSupp.CompanyName AS RagioneSociale, dbo.MA_PurchaseOrd.Currency AS Valuta, dbo.MA_PurchaseOrdSummary.TaxableAmount AS Imponibile, 
               dbo.MA_SuppQuotas.QuotationNo AS NoRich, dbo.MA_SuppQuotas.QuotationDate AS DataRichiesta, dbo.MA_PurchaseOrd.OrderDate AS DataOrd, 
               dbo.MA_PurchaseOrdShipping.Carrier2 AS DataFirma, SUBSTRING(dbo.MA_PurchaseOrdShipping.Carrier2, 1, 2) AS giorno, 
               SUBSTRING(dbo.MA_PurchaseOrdShipping.Carrier2, 4, 2) AS mese, SUBSTRING(dbo.MA_PurchaseOrdShipping.Carrier2, 7, 2) AS anno
FROM  dbo.MA_CustSupp INNER JOIN
               dbo.MA_PurchaseOrdShipping INNER JOIN
               dbo.MA_PurchaseOrd ON dbo.MA_PurchaseOrdShipping.PurchaseOrdId = dbo.MA_PurchaseOrd.PurchaseOrdId ON 
               dbo.MA_CustSupp.CustSupp = dbo.MA_PurchaseOrd.Supplier LEFT OUTER JOIN
               dbo.MA_SuppQuotas INNER JOIN
               dbo.MA_PurchaseOrdReferences ON dbo.MA_SuppQuotas.QuotationNo = dbo.MA_PurchaseOrdReferences.DocumentNumber ON 
               dbo.MA_PurchaseOrd.PurchaseOrdId = dbo.MA_PurchaseOrdReferences.PurchaseOrdId LEFT OUTER JOIN
               dbo.MA_PurchaseOrdSummary ON dbo.MA_PurchaseOrd.PurchaseOrdId = dbo.MA_PurchaseOrdSummary.PurchaseOrdId
WHERE (dbo.MA_CustSupp.CustSuppType = 3211265)
ORDER BY DataOrd
GO

PRINT 'Vista [dbo].[Ord_Fornitori_Tempo_Evasione] creata con successo'
GO

