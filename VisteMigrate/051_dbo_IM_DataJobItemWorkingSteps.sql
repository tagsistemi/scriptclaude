-- Vista [dbo].[IM_DataJobItemWorkingSteps] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_DataJobItemWorkingSteps')
BEGIN
    DROP VIEW [dbo].[IM_DataJobItemWorkingSteps]
    PRINT 'Vista [dbo].[IM_DataJobItemWorkingSteps] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_DataJobItemWorkingSteps]
AS
SELECT     DataJob.Component, DataJob.Job, DataJob.WorkingSteps, DataJob.JobComponentQty, DataJob.JobComponentTaxableAmount, DataJob.CorrectionsQty, 
                      DataJob.CorrectionsTaxableAmount, DataJob.PurchaseOrdQty, DataJob.PurchaseOrdQTaxableAmount, DataJob.PickingListQty, DataJob.PickingListTaxableAmount, 
                      DataJob.InventoryQty, DataJob.InventoryTaxableAmount, DataJob.PurchaseDocQty, DataJob.PurchaseDocTaxableAmount, DataJob.WorkingReportQty, 
                      DataJob.WorkingReportTaxableAmount, DataJob.DocumentDate, CASE COALESCE (JS.Currency, '') WHEN '' THEN '€' ELSE C.Symbol END AS Currency, 
                      COALESCE (J.ParentJob, '') AS ParentJob, CASE COALESCE (J.ParentJob, '') WHEN '' THEN '1' ELSE '2' END AS JobTypeOrder
FROM         (SELECT     Component, Job, WorkingStep AS WorkingSteps, Qty AS JobComponentQty, TaxableAmount AS JobComponentTaxableAmount, 0 AS CorrectionsQty, 
                                              0 AS CorrectionsTaxableAmount, 0 AS PurchaseOrdQty, 0 AS PurchaseOrdQTaxableAmount, 0 AS PickingListQty, 0 AS PickingListTaxableAmount, 
                                              0 AS InventoryQty, 0 AS InventoryTaxableAmount, 0 AS PurchaseDocQty, 0 AS PurchaseDocTaxableAmount, 0 AS WorkingReportQty, 
                                              0 AS WorkingReportTaxableAmount, '31-12-1799' AS DocumentDate
                       FROM          dbo.IM_JobsComponents AS JC
                       UNION ALL
                       SELECT     JCD.Component, JCD.Job, JCD.WorkingStep, 0 AS Expr1, 0 AS Expr2, JCD.QtyToCorrect, JCD.TotCostAmount, 0 AS Expr3, 0 AS Expr4, 0 AS Expr5, 
                                             0 AS Expr6, 0 AS Expr7, 0 AS Expr8, 0 AS Expr9, 0 AS Expr10, 0 AS Expr11, 0 AS Expr12, JC.CreationDate
                       FROM         dbo.IM_JobCorrectionsDetails AS JCD LEFT OUTER JOIN
                                             dbo.IM_JobCorrections AS JC ON JC.JCId = JCD.JCId
                       WHERE     (JCD.Job <> '')
                       UNION ALL
                       SELECT     POD.Item, POD.Job, POD.IM_JobWorkingStep, 0 AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, POD.Qty - POD.DeliveredQty AS Expr5, 
                                             (POD.TaxableAmount / POD.Qty) * (POD.Qty - POD.DeliveredQty) AS Expr6, 0 AS Expr7, 0 AS Expr8, 0 AS Expr9, 0 AS Expr10, 0 AS Expr11, 0 AS Expr12, 
                                             0 AS Expr13, 0 AS Expr14, PO.OrderDate
                       FROM         dbo.MA_PurchaseOrdDetails AS POD LEFT OUTER JOIN
                                             dbo.MA_PurchaseOrd AS PO ON PO.PurchaseOrdId = POD.PurchaseOrdId
                       WHERE     (POD.LineType IN (03538946, 03538947)) AND (POD.Qty - POD.DeliveredQty > 0) AND (POD.Job <> '')
                       UNION ALL
                       SELECT     Item, Job, IM_JobWorkingStep, 0 AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, 0 AS Expr5, 0 AS Expr6, Qty - DeliveredQty AS Expr7, (TaxableAmount / Qty)
                                              * (Qty - DeliveredQty) AS Expr8, 0 AS Expr9, 0 AS Expr10, 0 AS Expr11, 0 AS Expr12, 0 AS Expr13, 0 AS Expr14, DocumentDate
                       FROM         dbo.MA_SaleDocDetail AS SDD
                       WHERE     (DocumentType = 3407872) AND (LineType IN (03538946, 03538947)) AND (Qty - DeliveredQty > 0) AND (Job <> '')
                       UNION ALL
                       SELECT     IED.Item, IED.Job, IED.IM_JobWorkingStep, 0 AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, 0 AS Expr5, 0 AS Expr6, 0 AS Expr7, 0 AS Expr8, IED.Qty, 
                                             IED.LineAmount, 0 AS Expr9, 0 AS Expr10, 0 AS Expr11, 0 AS Expr12, IED.PostingDate
                       FROM         dbo.MA_InventoryEntriesDetail AS IED LEFT OUTER JOIN
                                             dbo.IM_InvRsnPolicies AS IRP ON IED.InvRsn = IRP.InvRsn
                       WHERE     (IED.Job <> '') AND (IRP.CostActionOnEconomicAnalysis = 06291457)
		       
                       UNION ALL
                       SELECT     IED.Item, IED.Job, IED.IM_JobWorkingStep, 0 AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, 0 AS Expr5, 0 AS Expr6, 0 AS Expr7, 0 AS Expr8, 
                                             - IED.Qty AS Expr13, - IED.LineAmount AS Expr14, 0 AS Expr9, 0 AS Expr10, 0 AS Expr11, 0 AS Expr12, IED.PostingDate
                       FROM         dbo.MA_InventoryEntriesDetail AS IED LEFT OUTER JOIN
                                             dbo.IM_InvRsnPolicies AS IRP ON IED.InvRsn = IRP.InvRsn
                       WHERE     (IED.Job <> '') AND (IRP.CostActionOnEconomicAnalysis = 06291458)
		       
                       UNION ALL
                       SELECT     PDD.Item, PDD.Job, PDD.IM_JobWorkingStep, 0 AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, 0 AS Expr5, 0 AS Expr6, 0 AS Expr7, 0 AS Expr8, 0 AS Expr9,
                                              0 AS Expr10, PDD.Qty, PDD.TaxableAmount, 0 AS Expr11, 0 AS Expr12, PD.DocumentDate
                       FROM         dbo.MA_PurchaseDocDetail AS PDD LEFT OUTER JOIN
                                             dbo.MA_PurchaseDoc AS PD ON PDD.PurchaseDocId = PD.PurchaseDocId LEFT OUTER JOIN
                                             dbo.IM_InvRsnPolicies AS IRP ON PD.ConfInvRsn = IRP.InvRsn
                       WHERE     (PD.DocumentType = 9830401) AND (PDD.Job <> '') AND (IRP.CostActionOnEconomicAnalysis = 06291457) AND (PDD.LineType = 03538946)
                       UNION ALL
                       SELECT     Component, Job, WorkingStep, 0 AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, 0 AS Expr5, 0 AS Expr6, 0 AS Expr7, 0 AS Expr8, 0 AS Expr9, 0 AS Expr10, 
                                             0 AS Expr11, 0 AS Expr12, Quantity, TotalAmount, WorkingReportDate
                       FROM         dbo.IM_WorkingReportsActualities AS WRA
                       WHERE     (ComponentType = 13238276) AND (IsOnJobEconomicAnalysis = 1) AND (Job <> '')) AS DataJob LEFT OUTER JOIN
                      dbo.MA_Jobs AS J ON DataJob.Job = J.Job AND J.ParentJob IS NOT NULL LEFT OUTER JOIN
                      dbo.IM_JobsSummary AS JS ON JS.Job = J.Job LEFT OUTER JOIN
                      dbo.MA_Currencies AS C ON JS.Currency = C.Currency
GO

PRINT 'Vista [dbo].[IM_DataJobItemWorkingSteps] creata con successo'
GO

