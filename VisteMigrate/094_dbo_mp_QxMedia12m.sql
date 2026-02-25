-- Vista [dbo].[mp_QxMedia12m] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'mp_QxMedia12m')
BEGIN
    DROP VIEW [dbo].[mp_QxMedia12m]
    PRINT 'Vista [dbo].[mp_QxMedia12m] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[mp_QxMedia12m]
AS
SELECT     TOP (100) PERCENT MAX(YEAR(dbo.MA_InventoryEntries.DocumentDate)) AS Anno, MAX(MONTH(dbo.MA_InventoryEntries.DocumentDate)) AS Mese, 
                      dbo.MA_InventoryEntries.StoragePhase1 AS Depo, MAX(dbo.MA_Items.OldItem) AS OldArt, SUM(dbo.MA_InventoryEntriesDetail.Qty) AS QtyMese, 
                      SUM(dbo.MA_InventoryEntriesDetail.Qty) / 12 AS Media12mesi_aa, dbo.MA_InventoryEntriesDetail.Item AS Articolo, MAX(1) AS Div
FROM         dbo.MA_InventoryEntriesDetail INNER JOIN
                      dbo.MA_InventoryEntries ON dbo.MA_InventoryEntriesDetail.EntryId = dbo.MA_InventoryEntries.EntryId INNER JOIN
                      dbo.MA_Items ON dbo.MA_InventoryEntriesDetail.Item = dbo.MA_Items.Item
WHERE     (dbo.MA_InventoryEntriesDetail.InvRsn = 'SMP01') OR
                      (dbo.MA_InventoryEntriesDetail.InvRsn = 'SMP02') OR
                      (dbo.MA_InventoryEntriesDetail.InvRsn = 'SMP04') OR
                      (dbo.MA_InventoryEntriesDetail.InvRsn = 'RI-NEG')
GROUP BY dbo.MA_InventoryEntriesDetail.Item, dbo.MA_InventoryEntries.StoragePhase1
GO

PRINT 'Vista [dbo].[mp_QxMedia12m] creata con successo'
GO

