-- Vista [dbo].[IM_CLCLComponents] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_CLCLComponents')
BEGIN
    DROP VIEW [dbo].[IM_CLCLComponents]
    PRINT 'Vista [dbo].[IM_CLCLComponents] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_CLCLComponents] AS  
	SELECT 	IM_ComponentsLists.ComponentsList, 
	       	IM_ComponentsLists.Description, 
		IM_CLComponents.ComponentType, 
		IM_CLComponents.Component, 
		IM_CLComponents.Description AS ComponentDescription, 
		IM_CLComponents.CostingType 
	FROM IM_ComponentsLists LEFT OUTER JOIN IM_CLComponents ON 
	IM_ComponentsLists.ComponentsList = IM_CLComponents.ComponentsList
GO

PRINT 'Vista [dbo].[IM_CLCLComponents] creata con successo'
GO

