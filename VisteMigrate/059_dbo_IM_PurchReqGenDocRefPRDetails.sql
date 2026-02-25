-- Vista [dbo].[IM_PurchReqGenDocRefPRDetails] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_PurchReqGenDocRefPRDetails')
BEGIN
    DROP VIEW [dbo].[IM_PurchReqGenDocRefPRDetails]
    PRINT 'Vista [dbo].[IM_PurchReqGenDocRefPRDetails] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_PurchReqGenDocRefPRDetails] AS  
	SELECT 	IM_PurchReqGenDocRef.DocType, 
		IM_PurchReqGenDocRef.DocNo, 
		IM_PurchReqGenDocRef.DocId, 
		IM_PurchReqGenDocRef.DocDate, 
		IM_PurchReqDetailsGroup.Item, 
		IM_PurchReqDetailsGroup.Description, 
		IM_PurchReqDetailsGroup.UoM, 
		IM_PurchReqDetailsGroup.Producer, 
		IM_PurchReqDetailsGroup.ProductCtg, 
		IM_PurchReqDetailsGroup.ProductSubCtg, 
		IM_PurchReqDetailsGroup.PurchaseRequestNo, 
		IM_PurchReqDetailsGroup.PurchaseRequestId, 
		IM_PurchReqDetailsGroup.Simulation 
	FROM IM_PurchReqDetailsGroup LEFT OUTER JOIN IM_PurchReqGenDocRef ON 
		IM_PurchReqGenDocRef.PurchaseRequestId = IM_PurchReqDetailsGroup.PurchaseRequestId 
	WHERE IM_PurchReqGenDocRef.DocType = 17760256
GO

PRINT 'Vista [dbo].[IM_PurchReqGenDocRefPRDetails] creata con successo'
GO

