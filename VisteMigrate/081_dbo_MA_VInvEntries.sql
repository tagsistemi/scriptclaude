-- Vista [dbo].[MA_VInvEntries] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VInvEntries')
BEGIN
    DROP VIEW [dbo].[MA_VInvEntries]
    PRINT 'Vista [dbo].[MA_VInvEntries] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VInvEntries] AS SELECT
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
	MA_InventoryEntries.Specificator1Type,
	MA_InventoryEntries.SpecificatorPhase1,
	MA_InventoryEntries.StoragePhase2,
	MA_InventoryEntries.Specificator2Type,
	MA_InventoryEntries.SpecificatorPhase2,
	MA_InventoryEntries.Notes,
	MA_InventoryReasons.Description,
	MA_InventoryReasons.LineCostOrigin
	FROM MA_InventoryEntries INNER JOIN
    MA_InventoryReasons ON MA_InventoryEntries.InvRsn = MA_InventoryReasons.Reason
GO

PRINT 'Vista [dbo].[MA_VInvEntries] creata con successo'
GO

