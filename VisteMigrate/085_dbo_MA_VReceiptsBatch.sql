-- Vista [dbo].[MA_VReceiptsBatch] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VReceiptsBatch')
BEGIN
    DROP VIEW [dbo].[MA_VReceiptsBatch]
    PRINT 'Vista [dbo].[MA_VReceiptsBatch] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VReceiptsBatch] AS  SELECT 
      MA_ReceiptsBatch.ReceiptBatchId ,
      MA_ReceiptsBatch.IsFIFO,
      MA_ReceiptsBatch.Storage,
      MA_ReceiptsBatch.Item,
      MA_ReceiptsBatch.TotallyConsumedDate,
      MA_ReceiptsBatch.LoadDate,
      MA_ReceiptsBatchDetail.InvEntryId,
      MA_ReceiptsBatchDetail.InvEntrySubID,
      MA_ReceiptsBatchDetail.InvEntryType,
      MA_ReceiptsBatchDetail.PostingDate,
      MA_InventoryReasons.Reason,
      CASE
      WHEN MA_ReceiptsBatchDetail.Qty = 0 THEN 0
      WHEN (MA_ReceiptsBatchDetail.LineCost < 0) THEN (MA_ReceiptsBatchDetail.LineCost / MA_ReceiptsBatchDetail.Qty) * -1
      ELSE MA_ReceiptsBatchDetail.LineCost / MA_ReceiptsBatchDetail.Qty
      END AS UnitLineCost,
      CASE
      WHEN MA_ReceiptsBatchDetail.InvEntryType = 11796488 OR MA_ReceiptsBatchDetail.InvEntryType = 11796489 THEN MA_ReceiptsBatchDetail.LineCost * -1
      ELSE MA_ReceiptsBatchDetail.LineCost
      END   AS LineCost,
      CASE
      WHEN MA_ReceiptsBatchDetail.InvEntryType = 11796488 THEN MA_ReceiptsBatchDetail.Qty * -1
      ELSE MA_ReceiptsBatchDetail.Qty
      END   AS Qty
      FROM MA_ReceiptsBatch INNER JOIN
      MA_ReceiptsBatchDetail ON MA_ReceiptsBatch.ReceiptBatchId = MA_ReceiptsBatchDetail.ReceiptBatchId AND
                                           MA_ReceiptsBatch.Storage = MA_ReceiptsBatchDetail.Storage     INNER JOIN
      MA_InventoryEntries ON MA_ReceiptsBatchDetail.InvEntryId = MA_InventoryEntries.EntryId INNER JOIN
      MA_InventoryReasons ON MA_InventoryEntries.InvRsn = MA_InventoryReasons.Reason
GO

PRINT 'Vista [dbo].[MA_VReceiptsBatch] creata con successo'
GO

