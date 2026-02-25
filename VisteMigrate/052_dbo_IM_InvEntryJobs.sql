-- Vista [dbo].[IM_InvEntryJobs] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_InvEntryJobs')
BEGIN
    DROP VIEW [dbo].[IM_InvEntryJobs]
    PRINT 'Vista [dbo].[IM_InvEntryJobs] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_InvEntryJobs] AS  
	SELECT 	MA_InventoryEntriesPhases.Storage, 
		MA_InventoryEntriesDetail.Line, 
		MA_InventoryEntriesDetail.Item, 
		MA_InventoryEntriesPhases.EntryId, 
		MA_InventoryEntries.PostingDate, 
		MA_InventoryEntries.InvRsn, 
		MA_InventoryEntriesDetail.Qty, 
		MA_InventoryEntriesPhases.Receipted, 
		MA_InventoryEntriesPhases.CustSuppType, 
		MA_InventoryEntriesPhases.Cancel, 
		MA_InventoryEntriesDetail.UnitValue, 
		MA_InventoryEntriesDetail.DiscountFormula, 
		MA_InventoryEntriesDetail.DiscountAmount, 
		MA_InventoryEntriesDetail.LineAmount, 
		MA_InventoryEntriesDetail.Job, 
		MA_Jobs.Customer AS CliFor, 
		MA_InventoryEntriesPhases.SpecificatorType, 
		MA_InventoryEntriesPhases.Specificator, 
		MA_InventoryEntriesPhases.Phase, 
		MA_InventoryEntriesDetail.UoM 

	FROM MA_InventoryEntriesPhases 
	
	LEFT OUTER JOIN MA_InventoryEntriesDetail ON 
		MA_InventoryEntriesPhases.Line 		= MA_InventoryEntriesDetail.Line AND 
		MA_InventoryEntriesPhases.EntryId 	= MA_InventoryEntriesDetail.EntryId 
	LEFT OUTER JOIN MA_InventoryEntries 	ON 
		MA_InventoryEntriesPhases.EntryId 	= MA_InventoryEntries.EntryId 
	LEFT OUTER JOIN MA_Jobs ON 
		MA_InventoryEntriesDetail.Job 		= MA_Jobs.Job
GO

PRINT 'Vista [dbo].[IM_InvEntryJobs] creata con successo'
GO

