-- Vista [dbo].[IM_JobsDetailsCategories] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_JobsDetailsCategories')
BEGIN
    DROP VIEW [dbo].[IM_JobsDetailsCategories]
    PRINT 'Vista [dbo].[IM_JobsDetailsCategories] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_JobsDetailsCategories] AS  
	SELECT 	IM_JobsDetails.Job, 
		IM_JobsDetails.Section, 
		IM_JobsDetails.Line, 
		IM_JobsDetails.ComponentType, 
		IM_JobsDetails.Component, 
		IM_JobsDetails.BaseUoM, 
		IM_JobsDetails.Description, 
		IM_JobsDetails.Quantity, 
		IM_JobsDetails.UnitTime, 
		IM_JobsDetails.TotalTime, 
		IM_JobsDetails.FunctionalCtg, 
		IM_JobsDetails.JobQuotationId, 
		IM_JobsDetails.JobQuotationSection, 
		IM_JobsDetails.JobQuotationLine, 
		IM_JobsDetails.InstalledQty, 
		IM_JobsDetails.AssignedQty, 
		IM_JobsDetails.IsOATAMB, 
		IM_JobsDetails.Price, 
		MA_Items.ProductCtg
	FROM IM_JobsDetails LEFT OUTER JOIN MA_Items 
	ON IM_JobsDetails.Component = MA_Items.Item
GO

PRINT 'Vista [dbo].[IM_JobsDetailsCategories] creata con successo'
GO

