-- Vista [dbo].[MA_VInvEntriesDetail] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VInvEntriesDetail')
BEGIN
    DROP VIEW [dbo].[MA_VInvEntriesDetail]
    PRINT 'Vista [dbo].[MA_VInvEntriesDetail] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VInvEntriesDetail] AS SELECT
	MA_InventoryEntries.InvRsn,
	MA_InventoryEntries.StubBook,
	MA_InventoryEntries.PostingDate,
	MA_InventoryEntries.CustSuppType,
    MA_InventoryEntries.CustSupp,
	MA_InventoryEntries.PreprintedDocNo,
	MA_InventoryEntries.DocNo,
    MA_InventoryEntries.DocumentDate,
	MA_InventoryEntries.Currency,
	MA_InventoryEntries.FixingDate,
    MA_InventoryEntries.FixingIsManual,
	MA_InventoryEntries.Fixing,
	MA_InventoryEntries.EntryId,
	MA_InventoryEntries.StoragePhase1,
	MA_InventoryEntries.StoragePhase2,
	MA_InventoryEntries.AutomaticInvValueOnly,
	MA_InventoryReasons.Description,
	MA_InventoryReasons.LineCostOrigin,
	MA_InventoryEntriesDetail.Line,
	MA_InventoryEntriesDetail.Item,
	MA_InventoryEntriesDetail.Lot,
	MA_InventoryEntriesDetail.UoM,
	MA_InventoryEntriesDetail.Qty,
	MA_InventoryEntriesDetail.BaseUomQty,
	MA_InventoryEntriesDetail.UnitValue,
	MA_InventoryEntriesDetail.LineAmount,
	MA_InventoryEntriesDetail.DiscountFormula,
	MA_InventoryEntriesDetail.VariationInvEntryID,
	MA_InventoryEntriesDetail.VariationInvEntrySubID,
	MA_InventoryEntriesDetail.LineCost,
	MA_InventoryEntriesDetail.SubId,
	MA_InventoryEntriesDetail.EntryTypeForLFBatchEval,
	MA_InventoryEntriesDetail.BoLId,
	MA_InventoryEntriesDetail.BoLSubID,
	MA_InventoryEntriesDetail.DocumentType,
	MA_InventoryEntriesDetail.ActionOnLifoFifo,
	MA_InventoryEntriesDetail.LifoFifo_LineSource,
	MA_InventoryEntriesDetail.OrderForProcedure
	FROM [dbo].[MA_InventoryEntries] INNER JOIN
    [dbo].[MA_InventoryReasons] ON MA_InventoryEntries.InvRsn = MA_InventoryReasons.Reason INNER JOIN
    [dbo].[MA_InventoryEntriesDetail] ON MA_InventoryEntriesDetail.EntryId = MA_InventoryEntries.EntryId
GO

PRINT 'Vista [dbo].[MA_VInvEntriesDetail] creata con successo'
GO

