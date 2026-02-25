-- Vista [dbo].[vistabasevalcostovendita] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'vistabasevalcostovendita')
BEGIN
    DROP VIEW [dbo].[vistabasevalcostovendita]
    PRINT 'Vista [dbo].[vistabasevalcostovendita] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[vistabasevalcostovendita]
AS
SELECT     dbo.MA_InventoryEntries.InvRsn, dbo.MA_InventoryEntries.PostingDate, dbo.MA_InventoryEntries.DocNo, dbo.MA_InventoryEntries.DocumentDate, 
                      dbo.MA_InventoryEntriesDetail.OrderLine, dbo.MA_InventoryEntriesDetail.OrderId, dbo.MA_InventoryEntriesDetail.Job, 
                      dbo.MA_SaleOrdDetails.TaxableAmount, dbo.MA_InventoryEntriesDetail.Qty, dbo.MA_SaleOrdDetails.Qty AS qtaordine, 
                      dbo.MA_InventoryEntriesDetail.UnitValue AS valoreunitariomovimento, 
                      dbo.MA_SaleOrdDetails.TaxableAmount / dbo.MA_SaleOrdDetails.Qty AS valorevendita, dbo.MA_InventoryEntries.Currency, 
                      dbo.MA_SaleOrd.Currency AS valutaordine, dbo.MA_InventoryEntriesDetail.Item
FROM         dbo.MA_InventoryEntriesDetail INNER JOIN
                      dbo.MA_InventoryEntries ON dbo.MA_InventoryEntriesDetail.EntryId = dbo.MA_InventoryEntries.EntryId INNER JOIN
                      dbo.MA_SaleOrdDetails ON dbo.MA_InventoryEntriesDetail.OrderLine = dbo.MA_SaleOrdDetails.Line AND 
                      dbo.MA_InventoryEntriesDetail.Job = dbo.MA_SaleOrdDetails.Job INNER JOIN
                      dbo.MA_SaleOrd ON dbo.MA_SaleOrdDetails.SaleOrdId = dbo.MA_SaleOrd.SaleOrdId
WHERE     (dbo.MA_InventoryEntries.InvRsn = 'CPEUR') AND (dbo.MA_SaleOrd.Currency = 'EURO')
GO

PRINT 'Vista [dbo].[vistabasevalcostovendita] creata con successo'
GO

