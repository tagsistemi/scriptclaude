-- Vista [dbo].[artcommessew] - Aggiornamento
-- Generato: 2026-02-23 21:30:32

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'artcommessew')
BEGIN
    DROP VIEW [dbo].[artcommessew]
    PRINT 'Vista [dbo].[artcommessew] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[artcommessew]
AS
SELECT     dbo.MA_InventoryEntriesDetail.Item, dbo.MA_InventoryEntriesDetail.Job, dbo.MA_InventoryEntries.InvRsn, dbo.MA_InventoryEntriesDetail.Qty, 
                      dbo.MA_InventoryEntriesDetail.UoM, dbo.MA_InventoryEntriesDetail.CostCenter, dbo.MA_InventoryReasons.Description, 
                      dbo.MA_InventoryEntriesDetail.EntryId, dbo.MA_InventoryEntries.StoragePhase1, dbo.MA_InventoryEntriesDetail.PostingDate, 
                      dbo.MA_InventoryEntries.StoragePhase2, dbo.MA_InventoryReasons.Action, dbo.MA_Items.CommodityCtg, 
                      { fn YEAR(dbo.MA_InventoryEntries.PostingDate) } AS ESERCIZIOMOV, dbo.MA_Items.Description AS descriart, 
                      dbo.MA_CommodityCtg.Description AS descricat, dbo.MA_InventoryEntries.Currency, dbo.MA_InventoryEntriesDetail.Discount1, 
                      dbo.MA_InventoryEntriesDetail.Discount2, dbo.MA_InventoryEntriesDetail.DiscountFormula, dbo.MA_InventoryEntriesDetail.Lot, 
                      dbo.MA_Items.ItemType
FROM         dbo.MA_InventoryEntries INNER JOIN
                      dbo.MA_InventoryEntriesDetail ON dbo.MA_InventoryEntries.EntryId = dbo.MA_InventoryEntriesDetail.EntryId INNER JOIN
                      dbo.MA_InventoryReasons ON dbo.MA_InventoryEntries.InvRsn = dbo.MA_InventoryReasons.Reason INNER JOIN
                      dbo.MA_Items ON dbo.MA_InventoryEntriesDetail.Item = dbo.MA_Items.Item INNER JOIN
                      dbo.MA_CommodityCtg ON dbo.MA_Items.CommodityCtg = dbo.MA_CommodityCtg.Category
GO

PRINT 'Vista [dbo].[artcommessew] creata con successo'
GO

