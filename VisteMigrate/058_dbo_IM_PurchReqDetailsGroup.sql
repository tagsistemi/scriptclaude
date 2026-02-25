-- Vista [dbo].[IM_PurchReqDetailsGroup] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_PurchReqDetailsGroup')
BEGIN
    DROP VIEW [dbo].[IM_PurchReqDetailsGroup]
    PRINT 'Vista [dbo].[IM_PurchReqDetailsGroup] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_PurchReqDetailsGroup] AS  
	SELECT 	Item, 
		Description, 
		Uom, 
		Producer, 
		ProductCtg, 
		ProductSubCtg, 
		PurchaseRequestNo, 
		PurchaseRequestId, 
		Simulation 
	FROM 	IM_PurchReqDetails 
	GROUP BY 	Item, 
			Description, 
			Uom, 
			Producer, 
			ProductCtg, 
			ProductSubCtg, 
			PurchaseRequestId, 
			PurchaseRequestNo, 
			Simulation
GO

PRINT 'Vista [dbo].[IM_PurchReqDetailsGroup] creata con successo'
GO

