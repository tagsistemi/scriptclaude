-- Vista [dbo].[IM_PyblsRcvblsJobIncidenceDocs] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_PyblsRcvblsJobIncidenceDocs')
BEGIN
    DROP VIEW [dbo].[IM_PyblsRcvblsJobIncidenceDocs]
    PRINT 'Vista [dbo].[IM_PyblsRcvblsJobIncidenceDocs] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_PyblsRcvblsJobIncidenceDocs] AS
SELECT
	YEAR(MA_PyblsRcvblsDetails.InstallmentDate) AS InstallmentYear,
	MONTH(MA_PyblsRcvblsDetails.InstallmentDate) AS InstallmentMonth,
	MA_SaleDoc.DocNo, 
	MA_SaleDoc.DocumentType,
	MA_PyblsRcvblsDetails.PymtSchedId,
	MA_PyblsRcvblsDetails.InstallmentNo,
	MA_PyblsRcvblsDetails.DocumentId,
	MA_PyblsRcvblsDetails.InstallmentDate,
	IM_PyblsRcvblsJobIncidence.Job,
	MA_PyblsRcvblsDetails.InstallmentType,
	IM_PyblsRcvblsJobIncidence.JobIncidence,
	MA_PyblsRcvblsDetails.CustSuppType,
	MA_PyblsRcvblsDetails.CustSupp,
	MA_PyblsRcvblsDetails.PayableAmountInBaseCurr,
	MA_PyblsRcvblsDetails.DebitCreditSign,
	MA_Jobs.Disabled
FROM MA_PyblsRcvblsDetails INNER JOIN IM_PyblsRcvblsJobIncidence ON MA_PyblsRcvblsDetails.PymtSchedId = IM_PyblsRcvblsJobIncidence.PymtSchedId
	INNER JOIN MA_Jobs ON IM_PyblsRcvblsJobIncidence.Job = MA_Jobs.Job
	LEFT OUTER JOIN MA_SaleDoc ON MA_PyblsRcvblsDetails.DocumentId = MA_SaleDoc.SaleDocId
WHERE  MA_PyblsRcvblsDetails.DocumentType = 3801088 AND MA_PyblsRcvblsDetails.Closed = 0 AND MA_PyblsRcvblsDetails.InstallmentType = 5505024
UNION ALL
SELECT
	YEAR(MA_PyblsRcvblsDetails.InstallmentDate) AS InstallmentYear,
	MONTH(MA_PyblsRcvblsDetails.InstallmentDate) AS InstallmentMonth,
	MA_PurchaseDoc.DocNo, 
	MA_PurchaseDoc.DocumentType,
	MA_PyblsRcvblsDetails.PymtSchedId,
	MA_PyblsRcvblsDetails.InstallmentNo,
	MA_PyblsRcvblsDetails.DocumentId,
	MA_PyblsRcvblsDetails.InstallmentDate,
	IM_PyblsRcvblsJobIncidence.Job,
	MA_PyblsRcvblsDetails.InstallmentType,
	IM_PyblsRcvblsJobIncidence.JobIncidence,
	MA_PyblsRcvblsDetails.CustSuppType,
	MA_PyblsRcvblsDetails.CustSupp,
	MA_PyblsRcvblsDetails.PayableAmountInBaseCurr,
	MA_PyblsRcvblsDetails.DebitCreditSign,
	MA_Jobs.Disabled
FROM  MA_PyblsRcvblsDetails INNER JOIN IM_PyblsRcvblsJobIncidence ON MA_PyblsRcvblsDetails.PymtSchedId = IM_PyblsRcvblsJobIncidence.PymtSchedId
	INNER JOIN MA_Jobs ON IM_PyblsRcvblsJobIncidence.Job = MA_Jobs.Job
	LEFT OUTER JOIN MA_PurchaseDoc ON MA_PyblsRcvblsDetails.DocumentId = MA_PurchaseDoc.PurchaseDocId
WHERE  MA_PyblsRcvblsDetails.DocumentType = 3801108  AND MA_PyblsRcvblsDetails.Closed = 0 AND MA_PyblsRcvblsDetails.InstallmentType = 5505024
GO

PRINT 'Vista [dbo].[IM_PyblsRcvblsJobIncidenceDocs] creata con successo'
GO

