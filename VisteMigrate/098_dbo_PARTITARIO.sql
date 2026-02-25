-- Vista [dbo].[PARTITARIO] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'PARTITARIO')
BEGIN
    DROP VIEW [dbo].[PARTITARIO]
    PRINT 'Vista [dbo].[PARTITARIO] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[PARTITARIO]
AS
SELECT     dbo.MA_PyblsRcvblsDetails.InstallmentNo, dbo.MA_PyblsRcvblsDetails.InstallmentType, dbo.MA_PyblsRcvblsDetails.InstallmentDate, 
                      dbo.MA_PyblsRcvblsDetails.OpenedAdmCases, dbo.MA_PyblsRcvblsDetails.OpeningDate, dbo.MA_PyblsRcvblsDetails.PayableAmountInBaseCurr, 
                      dbo.MA_PyblsRcvblsDetails.CustSupp, dbo.MA_PyblsRcvblsDetails.DebitCreditSign, dbo.MA_PyblsRcvblsDetails.Amount, 
                      dbo.MA_PyblsRcvblsDetails.Currency, dbo.MA_PyblsRcvblsDetails.FixingDate, dbo.MA_PyblsRcvblsDetails.FixingIsManual, 
                      dbo.MA_PyblsRcvblsDetails.Fixing, dbo.MA_PyblsRcvblsDetails.Closed, dbo.MA_PyblsRcvblsDetails.Notes, dbo.MA_PyblsRcvbls.Payment, 
                      dbo.MA_PyblsRcvbls.Settled, dbo.MA_PyblsRcvbls.DocNo, dbo.MA_PyblsRcvbls.DocumentDate, dbo.MA_PyblsRcvbls.CreditNote, 
                      dbo.MA_PyblsRcvbls.TotalAmount, dbo.MA_PyblsRcvbls.Blocked, dbo.MA_Currencies.Description AS [MA_Currencies.Description], 
                      dbo.MA_PaymentTerms.Description AS [MA_PaymentTerms.Description], dbo.MA_PyblsRcvblsDetails.CustSuppType, 
                      dbo.MA_PyblsRcvbls.PymtSchedId, dbo.MA_CustSupp.CompanyName, dbo.MA_CustSupp.CompanyName AS Ragione, dbo.MA_CustSupp.Address, 
                      dbo.MA_CustSupp.ZIPCode, dbo.MA_CustSupp.City, dbo.MA_CustSupp.County, dbo.MA_CustSupp.Telephone1, 
                      dbo.MA_CustSupp.Telephone1 AS Telefono, dbo.MA_CustSupp.Telephone2, dbo.MA_CustSupp.Fax, dbo.MA_CustSupp.Internet, 
                      dbo.MA_CustSupp.ContactPerson, dbo.MA_PyblsRcvblsDetails.DocumentId, dbo.MA_PyblsRcvbls.Group1, dbo.MA_PyblsRcvbls.Group2, 
                      dbo.MA_PyblsRcvbls.JournalEntryId, dbo.MA_JournalEntriesTax.TaxJournal, dbo.MA_CustSupp.Notes AS Expr1
FROM         dbo.MA_CustSupp INNER JOIN
                      dbo.MA_PaymentTerms RIGHT OUTER JOIN
                      dbo.MA_Currencies RIGHT OUTER JOIN
                      dbo.MA_PyblsRcvblsDetails LEFT OUTER JOIN
                      dbo.MA_PyblsRcvbls ON dbo.MA_PyblsRcvblsDetails.PymtSchedId = dbo.MA_PyblsRcvbls.PymtSchedId ON 
                      dbo.MA_Currencies.Currency = dbo.MA_PyblsRcvblsDetails.Currency ON dbo.MA_PaymentTerms.Payment = dbo.MA_PyblsRcvbls.Payment ON 
                      dbo.MA_CustSupp.CustSupp = dbo.MA_PyblsRcvblsDetails.CustSupp AND 
                      dbo.MA_CustSupp.CustSuppType = dbo.MA_PyblsRcvblsDetails.CustSuppType LEFT OUTER JOIN
                      dbo.MA_JournalEntriesTax ON dbo.MA_PyblsRcvbls.JournalEntryId = dbo.MA_JournalEntriesTax.JournalEntryId
GO

PRINT 'Vista [dbo].[PARTITARIO] creata con successo'
GO

