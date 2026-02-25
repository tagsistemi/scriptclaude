-- Vista [dbo].[MA_InventoryEntriesPhases] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_InventoryEntriesPhases')
BEGIN
    DROP VIEW [dbo].[MA_InventoryEntriesPhases]
    PRINT 'Vista [dbo].[MA_InventoryEntriesPhases] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_InventoryEntriesPhases] AS SELECT 
	MA_InventoryEntries.EntryId						AS EntryId, 
	MA_InventoryEntries.ReceiptPhase1				AS Receipted, 
	MA_InventoryEntries.CancelPhase1				AS Cancel, 
	MA_InventoryEntries.CustSuppType				AS CustSuppType, 
	MA_InventoryEntries.CustSupp					AS CustSupp, 
	MA_InventoryEntries.PostingDate					AS PostingDate, 
	MA_InventoryEntries.StoragePhase1				AS Storage, 
	MA_InventoryEntries.Specificator1Type			AS SpecificatorType, 
	MA_InventoryEntries.SpecificatorPhase1			AS Specificator, 
	MA_InventoryEntriesDetail.Line					AS Line, 
	MA_InventoryEntriesDetail.Item					AS Item, 
	MA_InventoryEntriesDetail.Department			AS Department, 
	1												AS Phase ,
	CASE MA_InventoryEntriesDetail.DocumentType
	     WHEN 3801088 THEN (SELECT DepartureDate FROM MA_SaleDoc where MA_SaleDoc.SaleDocId = MA_InventoryEntriesDetail.BoLId)
         WHEN 3801108 THEN (SELECT DepartureDate FROM MA_PurchaseDoc where MA_PurchaseDoc.PurchaseDocId = MA_InventoryEntriesDetail.BoLId)
		ELSE MA_InventoryEntries.PostingDate
	END AS DepartureDate
	FROM MA_InventoryEntries, MA_InventoryEntriesDetail
	WHERE  MA_InventoryEntries.EntryId = MA_InventoryEntriesDetail.EntryId 
		   
UNION ALL  SELECT 
	MA_InventoryEntries.EntryId						AS EntryId, 
	MA_InventoryEntries.ReceiptPhase2				AS Receipted, 
	MA_InventoryEntries.CancelPhase2				AS Cancel, 
	MA_InventoryEntries.CustSuppType				AS CustSuppType, 
	MA_InventoryEntries.CustSupp					AS CustSupp, 
	MA_InventoryEntries.PostingDate					AS PostingDate, 
	MA_InventoryEntries.StoragePhase2				AS Storage, 
	MA_InventoryEntries.Specificator2Type			AS SpecificatorType, 
	MA_InventoryEntries.SpecificatorPhase2			AS Specificator, 
	MA_InventoryEntriesDetail.Line					AS Line, 
	MA_InventoryEntriesDetail.Item					AS Item, 
	MA_InventoryEntriesDetail.Department			AS Department, 
	2												AS Phase ,
	CASE MA_InventoryEntriesDetail.DocumentType
	     WHEN 3801088 THEN (SELECT DepartureDate FROM MA_SaleDoc where MA_SaleDoc.SaleDocId = MA_InventoryEntriesDetail.BoLId)
         WHEN 3801108 THEN (SELECT DepartureDate FROM MA_PurchaseDoc where MA_PurchaseDoc.PurchaseDocId = MA_InventoryEntriesDetail.BoLId)
		ELSE MA_InventoryEntries.PostingDate
	END AS DepartureDate
	FROM MA_InventoryEntries, MA_InventoryEntriesDetail
	WHERE  MA_InventoryEntries.EntryId = MA_InventoryEntriesDetail.EntryId AND
		   MA_InventoryEntries.UsePhase2 = '1'
GO

PRINT 'Vista [dbo].[MA_InventoryEntriesPhases] creata con successo'
GO

