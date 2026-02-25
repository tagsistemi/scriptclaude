-- Vista [dbo].[MA_VPaymentScheduleSplitTax] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VPaymentScheduleSplitTax')
BEGIN
    DROP VIEW [dbo].[MA_VPaymentScheduleSplitTax]
    PRINT 'Vista [dbo].[MA_VPaymentScheduleSplitTax] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VPaymentScheduleSplitTax] AS  
	SELECT 
		MA_PyblsRcvbls.DocNo,
		MA_PyblsRcvblsDetails.InstallmentNo,
		MA_PyblsRcvblsDetails.Amount,
		MA_PyblsRcvblsDetails.CustSuppType,
		MA_PyblsRcvblsDetails.CustSupp,
		CASE MA_PyblsRcvblsDetails.Currency WHEN '' THEN (SELECT TOP 1 Currency FROM MA_CurrencyParameters) ELSE MA_PyblsRcvblsDetails.Currency END AS Currency,
		MA_PyblsRcvblsDetails.PymtSchedId,
		MA_PyblsRcvblsDetails.InstallmentDate,
		MA_PyblsRcvblsDetails.JournalEntryId,
		MA_PyblsRcvblsDetails.PaymentTerm,
		MA_PyblsRcvblsDetails.DebitCreditSign,
		MA_PyblsRcvblsDetails.BillCode,
		MA_PyblsRcvblsDetails.CompensationNo,
		MA_Bills.CollectionDate,
		MA_Bills.TransferDate
	FROM MA_PyblsRcvblsDetails 
	Inner Join MA_PyblsRcvbls on MA_PyblsRcvblsDetails.PymtSchedId = MA_PyblsRcvbls.PymtSchedId
	Left Outer Join MA_Bills on MA_PyblsRcvblsDetails.BillCode = MA_Bills.BillCode
	Where 
		MA_PyblsRcvblsDetails.InstallmentType = 5505025 And 
		MA_PyblsRcvblsDetails.AmountType = 6356995 And 
		MA_PyblsRcvblsDetails.PaymentTerm != 2686996
GO

PRINT 'Vista [dbo].[MA_VPaymentScheduleSplitTax] creata con successo'
GO

