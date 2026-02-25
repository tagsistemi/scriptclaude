-- Vista [dbo].[vistapermercepronta] - Aggiornamento
-- Generato: 2026-02-23 21:30:43

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'vistapermercepronta')
BEGIN
    DROP VIEW [dbo].[vistapermercepronta]
    PRINT 'Vista [dbo].[vistapermercepronta] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[vistapermercepronta]
AS
SELECT DISTINCT 
               dbo.MA_InventoryEntriesDetail.PostingDate, dbo.MA_InventoryEntriesDetail.Item, dbo.MA_SaleOrdDetails.Position, dbo.MA_SaleOrdDetails.Description, 
               dbo.MA_InventoryEntriesDetail.UoM, dbo.MA_InventoryEntriesDetail.Qty, dbo.MA_SaleOrdDetails.SaleOrdId, dbo.MA_InventoryEntriesDetail.OrderId, 
               dbo.MA_SaleOrdDetails.Customer, dbo.MA_InventoryEntriesDetail.EntryId, dbo.MA_InventoryEntries.InvRsn, dbo.MA_SaleOrdDetails.Qty AS QtaOrdine, 
               dbo.MA_SaleOrdDetails.DeliveredQty, dbo.MA_SaleOrdDetails.ExpectedDeliveryDate, dbo.MA_SaleOrdDetails.TaxableAmount, dbo.MA_SaleOrd.InternalOrdNo, 
               dbo.MA_SaleOrd.ExternalOrdNo, dbo.MA_SaleOrd.OrderDate, dbo.MA_SaleOrdDetails.Delivered, dbo.MA_InventoryEntriesDetail.Line, 
               dbo.MA_InventoryEntries.StoragePhase1, dbo.MA_SaleOrd.Job, dbo.MA_InventoryEntries.StoragePhase2, 1 AS Toaltreport, 
               dbo.MA_SaleOrdDetails.UnitValue
FROM  dbo.MA_SaleOrd INNER JOIN
               dbo.MA_SaleOrdDetails ON dbo.MA_SaleOrd.SaleOrdId = dbo.MA_SaleOrdDetails.SaleOrdId INNER JOIN
               dbo.MA_InventoryEntriesDetail INNER JOIN
               dbo.MA_InventoryEntries ON dbo.MA_InventoryEntriesDetail.EntryId = dbo.MA_InventoryEntries.EntryId ON 
               dbo.MA_SaleOrdDetails.Item = dbo.MA_InventoryEntriesDetail.Item AND dbo.MA_SaleOrdDetails.Job = dbo.MA_InventoryEntriesDetail.Job AND 
               dbo.MA_SaleOrdDetails.Position = dbo.MA_InventoryEntriesDetail.OrderLine
WHERE (LEFT(dbo.MA_InventoryEntries.InvRsn, 2) = 'AM') OR
               (LEFT(dbo.MA_InventoryEntries.InvRsn, 2) = 'CP')
GO

PRINT 'Vista [dbo].[vistapermercepronta] creata con successo'
GO

