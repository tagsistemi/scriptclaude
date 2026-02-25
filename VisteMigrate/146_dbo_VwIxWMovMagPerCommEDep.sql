-- Vista [dbo].[VwIxWMovMagPerCommEDep] - Creazione
-- Generato: 2026-02-23 21:30:43

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[VwIxWMovMagPerCommEDep] AS  SELECT MA_InventoryEntriesPhases.Storage, MA_InventoryEntriesDetail.Line, MA_InventoryEntriesDetail.Item, MA_InventoryEntriesPhases.EntryId, MA_InventoryEntries.PostingDate, MA_InventoryEntries.InvRsn, MA_InventoryEntriesDetail.Qty, MA_InventoryEntriesPhases.Receipted, MA_InventoryEntriesPhases.CustSuppType, MA_InventoryEntriesPhases.Cancel, MA_InventoryEntriesDetail.UnitValue, MA_InventoryEntriesDetail.DiscountFormula, MA_InventoryEntriesDetail.DiscountAmount, MA_InventoryEntriesDetail.LineAmount, MA_InventoryEntriesDetail.Job, MA_Jobs.Customer AS CliFor, MA_InventoryEntriesPhases.SpecificatorType, MA_InventoryEntriesPhases.Specificator, MA_InventoryEntriesPhases.Phase, MA_InventoryEntriesDetail.UoM FROM MA_InventoryEntriesPhases LEFT OUTER JOIN MA_InventoryEntriesDetail ON MA_InventoryEntriesPhases.Line = MA_InventoryEntriesDetail.Line AND MA_InventoryEntriesPhases.EntryId = MA_InventoryEntriesDetail.EntryId LEFT OUTER JOIN MA_InventoryEntries ON MA_InventoryEntriesPhases.EntryId = MA_InventoryEntries.EntryId LEFT OUTER JOIN MA_Jobs ON MA_InventoryEntriesDetail.Job = MA_Jobs.Job
GO

PRINT 'Vista [dbo].[VwIxWMovMagPerCommEDep] creata con successo'
GO

