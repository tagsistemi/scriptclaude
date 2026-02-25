-- Vista [dbo].[MA_VTransactionReport] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VTransactionReport')
BEGIN
    DROP VIEW [dbo].[MA_VTransactionReport]
    PRINT 'Vista [dbo].[MA_VTransactionReport] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VTransactionReport] AS  
	
	SELECT -- Bills of Lading
	0									AS DocumentType, 
	-1									AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate			AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo		AS ExternalNumber, 
	MA_PurchaseDoc.DocNo				AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType			AS CustSuppType,
	MA_PurchaseDoc.Supplier				AS CustomerSupplier,
	MA_PurchaseDoc.Currency				AS Currency,
	MA_PurchaseDoc.FixingDate			AS FixingDate,
	MA_PurchaseDoc.FixingIsManual		AS FixingIsManual,
	MA_PurchaseDoc.Fixing				AS Fixing,
	MA_PurchaseDoc.PurchaseDocId		AS DocId,
	MA_PurchaseDoc.InvEntryId 			AS InvEntryId,
	MA_PurchaseDoc.ConformingStorage1	AS Storage,
	0									AS Phase
	FROM	MA_PurchaseDoc 
	WHERE	MA_PurchaseDoc.DocumentType = 9830400

	UNION ALL 

	SELECT -- Return to Suppliers
	1								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate,
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier ,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InventoryIDReturn	AS InvEntryId,
	MA_SaleDoc.StoragePhase1Return	AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	(MA_SaleDoc.DocumentType = 3407881)

	UNION ALL 

	SELECT -- Purchase Invoices w/o BoL
	2									AS DocumentType, 
	-1									AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate			AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo		AS ExternalNumber, 
	MA_PurchaseDoc.DocNo				AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType			AS CustSuppType,
	MA_PurchaseDoc.Supplier				AS CustomerSupplier,
	MA_PurchaseDoc.Currency				AS Currency,
	MA_PurchaseDoc.FixingDate			AS FixingDate,
	MA_PurchaseDoc.FixingIsManual		AS FixingIsManual,
	MA_PurchaseDoc.Fixing				AS Fixing,
	MA_PurchaseDoc.PurchaseDocId		AS DocId,
	MA_PurchaseDoc.InvEntryId 			AS InvEntryId,
	MA_PurchaseDoc.ConformingStorage1	AS Storage,
	0									AS Phase
	FROM	MA_PurchaseDoc 
	WHERE	MA_PurchaseDoc.DocumentType = 9830401 and
		not exists (
	 			select	PurchaseDocId from MA_PurchaseDocDetail 
				where 	MA_PurchaseDocDetail.PurchaseDocId = MA_PurchaseDoc.PurchaseDocId and
					BillOfLadingId <> 0
			   )

	UNION ALL 

	SELECT -- Purchase Invoices of previous BoL (single storage)
	3										AS DocumentType, 
	-1										AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate				AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo			AS ExternalNumber, 
	MA_PurchaseDoc.DocNo					AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType				AS CustSuppType,
	MA_PurchaseDoc.Supplier					AS CustomerSupplier,
	MA_PurchaseDoc.Currency					AS Currency,
	MA_PurchaseDoc.FixingDate				AS FixingDate,
	MA_PurchaseDoc.FixingIsManual			AS FixingIsManual,
	MA_PurchaseDoc.Fixing					AS Fixing,
	MA_PurchaseDoc.PurchaseDocId			AS DocId,
	MA_PurchaseDoc.AdjValueOnlyInvEntryId	AS InvEntryId, -- ???
	MA_PurchaseDoc.Storage1OnlyValue		AS Storage,
	0										AS Phase
	FROM	MA_PurchaseDoc 
	WHERE	MA_PurchaseDoc.DocumentType = 9830401 and
		MA_PurchaseDoc.AdjValueOnlyInvEntryId <> 0 and
		exists (
	 			select	PurchaseDocId from MA_PurchaseDocDetail 
				where 	MA_PurchaseDocDetail.PurchaseDocId = MA_PurchaseDoc.PurchaseDocId and
				BillOfLadingId <> 0
			)

	UNION ALL 

	SELECT -- Purchase Invoices of previous BoL (multiple storages)
	3										AS DocumentType, 
	-1										AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate				AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo			AS ExternalNumber, 
	MA_PurchaseDoc.DocNo					AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType				AS CustSuppType,
	MA_PurchaseDoc.Supplier					AS CustomerSupplier,
	MA_PurchaseDoc.Currency					AS Currency,
	MA_PurchaseDoc.FixingDate				AS FixingDate,
	MA_PurchaseDoc.FixingIsManual			AS FixingIsManual,
	MA_PurchaseDoc.Fixing					AS Fixing,
	MA_PurchaseDoc.PurchaseDocId			AS DocId,
	MA_PurchaseDocReferences.DocumentId		AS InvEntryId,
	MA_PurchaseDoc.ConformingStorage1		AS Storage,
	0										AS Phase
	FROM	MA_PurchaseDoc left join MA_PurchaseDocReferences 
	ON
	MA_PurchaseDoc.PurchaseDocId = MA_PurchaseDocReferences.PurchaseDocId and
	MA_PurchaseDocReferences.DocumentType = 6684676 and
	MA_PurchaseDocReferences.TypeReference = 'InvMultiSt'
	left join MA_InventoryEntries
	on
	MA_InventoryEntries.EntryId = MA_PurchaseDocReferences.DocumentId 
	WHERE	MA_PurchaseDoc.DocumentType = 9830401 and
		MA_PurchaseDoc.AdjValueOnlyInvEntryId = 0 and
		exists (
	 			select	PurchaseDocId from MA_PurchaseDocDetail 
				where 	MA_PurchaseDocDetail.PurchaseDocId = MA_PurchaseDoc.PurchaseDocId and
				BillOfLadingId <> 0
			) and
		(
		    MA_PurchaseDoc.ConformingStorage1 = MA_InventoryEntries.StoragePhase1 or
		    MA_PurchaseDocReferences.DocumentId is null
		)

	UNION ALL 

	SELECT -- Correction of Purchase Invoices (single storage)
	4									AS DocumentType, 
	-1									AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate			AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo		AS ExternalNumber, 
	MA_PurchaseDoc.DocNo				AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType			AS CustSuppType,
	MA_PurchaseDoc.Supplier				AS CustomerSupplier,
	MA_PurchaseDoc.Currency				AS Currency,
	MA_PurchaseDoc.FixingDate			AS FixingDate,
	MA_PurchaseDoc.FixingIsManual		AS FixingIsManual,
	MA_PurchaseDoc.Fixing				AS Fixing,
	MA_PurchaseDoc.PurchaseDocId		AS DocId,
	MA_PurchaseDoc.InvEntryId			AS InvEntryId,
	MA_PurchaseDoc.ConformingStorage1	AS Storage,
	0									AS Phase
	FROM	MA_PurchaseDoc 
	WHERE	MA_PurchaseDoc.DocumentType = 9830403 and
			MA_PurchaseDoc.InvEntryId <> 0

	UNION ALL 

	SELECT -- Correction of Purchase Invoices (multiple storage)
	4									AS DocumentType, 
	-1									AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate			AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo		AS ExternalNumber, 
	MA_PurchaseDoc.DocNo				AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType			AS CustSuppType,
	MA_PurchaseDoc.Supplier				AS CustomerSupplier,
	MA_PurchaseDoc.Currency				AS Currency,
	MA_PurchaseDoc.FixingDate			AS FixingDate,
	MA_PurchaseDoc.FixingIsManual		AS FixingIsManual,
	MA_PurchaseDoc.Fixing				AS Fixing,
	MA_PurchaseDoc.PurchaseDocId		AS DocId,
	MA_PurchaseDocReferences.DocumentId	AS InvEntryId,
	MA_PurchaseDoc.ConformingStorage1	AS Storage,
	0									AS Phase
	FROM	MA_PurchaseDoc left join MA_PurchaseDocReferences 
	ON
	MA_PurchaseDoc.PurchaseDocId = MA_PurchaseDocReferences.PurchaseDocId and
	MA_PurchaseDocReferences.DocumentType = 6684676 and
	MA_PurchaseDocReferences.TypeReference = 'InvMultiSt'
	left join MA_InventoryEntries
	on
	MA_InventoryEntries.EntryId = MA_PurchaseDocReferences.DocumentId
	WHERE	MA_PurchaseDoc.DocumentType = 9830403 and
			MA_PurchaseDoc.InvEntryId = 0 and
		(
		    MA_PurchaseDoc.ConformingStorage1 = MA_InventoryEntries.StoragePhase1 or
		    MA_PurchaseDocReferences.DocumentId is null
		)

	UNION ALL  

	SELECT 	-- Delivery Notes
	5								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InvEntryId 			AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407873

	UNION ALL  

	SELECT 	-- Return From Customers
	6								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InventoryIDReturn	AS InvEntryId,
	MA_SaleDoc.StoragePhase1Return	AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407877

	UNION ALL  

	SELECT 	-- Sale Invoices w/o DN
	7								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InvEntryId 			AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407874 and
		MA_SaleDoc.IsParagon = 0 and
		not exists (
	 			select	SaleDocId from MA_SaleDocDetail 
				where 	MA_SaleDocDetail.SaleDocId = MA_SaleDoc.SaleDocId and
					MA_SaleDocDetail.ReferenceDocumentId <> 0
			   )

	UNION ALL  

	SELECT 	-- Sale Invoices to previous DN
	8								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	0 								AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407874 and
		MA_SaleDoc.IsParagon = 0 and
		exists (
	 			select	SaleDocId from MA_SaleDocDetail 
				where 	MA_SaleDocDetail.SaleDocId = MA_SaleDoc.SaleDocId and
					MA_SaleDocDetail.ReferenceDocumentId <> 0
			)

	UNION ALL  

	SELECT 	-- Correction of Sale Invoices
	9								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InvEntryId			AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407882

	UNION ALL  

	SELECT 	-- Paragon w/o DN 
	10								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InvEntryId 			AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407886

	UNION ALL  

	SELECT 	-- Correction to Paragon 
	11								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InvEntryId 			AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407887

	UNION ALL  

	SELECT 	-- Sale Invoices to Paragon
	12								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	0 								AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407874 and
		MA_SaleDoc.IsParagon = 1

	UNION ALL  

	SELECT 	-- Accompanying Invoices
	13								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InvEntryId			AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407875

	UNION ALL

	SELECT 	-- Correction of Accompanying Invoices
	14								AS DocumentType, 
	-1								AS DocumentSubType, 
	MA_SaleDoc.DocumentDate			AS DocumentDate, 
	''								AS ExternalNumber, 
	MA_SaleDoc.DocNo				AS InternalNumber, 
	MA_SaleDoc.CustSuppType			AS CustSuppType,
	MA_SaleDoc.CustSupp				AS CustomerSupplier,
	MA_SaleDoc.Currency				AS Currency,
	MA_SaleDoc.FixingDate			AS FixingDate,
	MA_SaleDoc.FixingIsManual		AS FixingIsManual,
	MA_SaleDoc.Fixing				AS Fixing,
	MA_SaleDoc.SaleDocId			AS DocId,
	MA_SaleDoc.InvEntryId			AS InvEntryId,
	MA_SaleDoc.StoragePhase1		AS Storage,
	0								AS Phase
	FROM	MA_SaleDoc 
	WHERE	MA_SaleDoc.DocumentType = 3407884

	UNION ALL  

	SELECT 	-- Inventory Adjustments
	15									AS DocumentType, 
	-1									AS DocumentSubType, 
	MA_InventoryEntries.DocumentDate	AS DocumentDate, 
	''									AS ExternalNumber, 
	MA_InventoryEntries.DocNo			AS InternalNumber,
	3211264								AS CustSuppType,
	''									AS CustomerSupplier,
	MA_InventoryEntries.Currency		AS Currency,
	MA_InventoryEntries.FixingDate		AS FixingDate,
	MA_InventoryEntries.FixingIsManual	AS FixingIsManual,
	MA_InventoryEntries.Fixing			AS Fixing,
	MA_InventoryEntries.EntryId			AS DocId,
	MA_InventoryEntries.EntryId			AS InvEntryId,
	MA_InventoryEntries.StoragePhase1	AS Storage,
	0									AS Phase
	FROM	MA_InventoryEntries, MA_InventoryReasons
	WHERE	MA_InventoryReasons.Reason = MA_InventoryEntries.InvRsn and
		MA_InventoryReasons.IsInventoryAdjustement = 1

	UNION ALL  

	SELECT 	-- Storage Transfers (phase 1)
	16									AS DocumentType, 
	-1									AS DocumentSubType, 
	MA_InventoryEntries.DocumentDate	AS DocumentDate, 
	''									AS ExternalNumber, 
	MA_InventoryEntries.PreprintedDocNo	AS InternalNumber,
	3211264								AS CustSuppType,
	''									AS CustomerSupplier,
	MA_InventoryEntries.Currency		AS Currency,
	MA_InventoryEntries.FixingDate		AS FixingDate,
	MA_InventoryEntries.FixingIsManual	AS FixingIsManual,
	MA_InventoryEntries.Fixing			AS Fixing,
	MA_InventoryEntries.EntryId			AS DocId,
	MA_InventoryEntries.EntryId			AS InvEntryId,
	MA_InventoryEntries.StoragePhase1	AS Storage,
	1									AS Phase
	FROM	MA_InventoryEntries, MA_InventoryReasons
	WHERE	MA_InventoryReasons.Reason = MA_InventoryEntries.InvRsn and
		MA_InventoryReasons.IsStorageTransfer = 1

	UNION ALL  

	SELECT 	-- Storage Transfers (phase 2)
	16									AS DocumentType, 
	-1									AS DocumentSubType, 
	MA_InventoryEntries.DocumentDate	AS DocumentDate, 
	''									AS ExternalNumber, 
	MA_InventoryEntries.PreprintedDocNo	AS InternalNumber,
	3211264								AS CustSuppType,
	''									AS CustomerSupplier,
	MA_InventoryEntries.Currency		AS Currency,
	MA_InventoryEntries.FixingDate		AS FixingDate,
	MA_InventoryEntries.FixingIsManual	AS FixingIsManual,
	MA_InventoryEntries.Fixing			AS Fixing,
	MA_InventoryEntries.EntryId			AS DocId,
	MA_InventoryEntries.EntryId			AS InvEntryId,
	MA_InventoryEntries.StoragePhase2	AS Storage,
	2									AS Phase
	FROM	MA_InventoryEntries, MA_InventoryReasons
	WHERE	MA_InventoryReasons.Reason = MA_InventoryEntries.InvRsn and
		MA_InventoryReasons.IsStorageTransfer = 1

	UNION ALL 

	SELECT -- Purchase Invoices of previous BoL, price change on other storages
	17										AS DocumentType, 
	3										AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate				AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo			AS ExternalNumber, 
	MA_PurchaseDoc.DocNo					AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType				AS CustSuppType,
	MA_PurchaseDoc.Supplier					AS CustomerSupplier,
	MA_PurchaseDoc.Currency					AS Currency,
	MA_PurchaseDoc.FixingDate				AS FixingDate,
	MA_PurchaseDoc.FixingIsManual			AS FixingIsManual,
	MA_PurchaseDoc.Fixing					AS Fixing,
	MA_PurchaseDoc.PurchaseDocId			AS DocId,
	MA_PurchaseDocReferences.DocumentId		AS InvEntryId,
	MA_InventoryEntries.StoragePhase1		AS Storage,
	2										AS Phase
	FROM	MA_PurchaseDoc join MA_PurchaseDocReferences 
	ON
	MA_PurchaseDoc.PurchaseDocId = MA_PurchaseDocReferences.PurchaseDocId and
	MA_PurchaseDocReferences.DocumentType = 6684676 and
	MA_PurchaseDocReferences.TypeReference = 'InvMultiSt'
	join MA_InventoryEntries
	on
	MA_InventoryEntries.EntryId = MA_PurchaseDocReferences.DocumentId 
	WHERE	MA_PurchaseDoc.DocumentType = 9830401 and
		MA_PurchaseDoc.AdjValueOnlyInvEntryId = 0 and
		exists (
	 			select	PurchaseDocId from MA_PurchaseDocDetail 
				where 	MA_PurchaseDocDetail.PurchaseDocId = MA_PurchaseDoc.PurchaseDocId and
				BillOfLadingId <> 0
			) and
		MA_PurchaseDoc.ConformingStorage1 <> MA_InventoryEntries.StoragePhase1

	UNION ALL 

	SELECT -- Correction of Purchase Invoices, price change on other storages
	17									AS DocumentType, 
	4									AS DocumentSubType, 
	MA_PurchaseDoc.DocumentDate			AS DocumentDate, 
	MA_PurchaseDoc.SupplierDocNo		AS ExternalNumber, 
	MA_PurchaseDoc.DocNo				AS InternalNumber, 
	MA_PurchaseDoc.CustSuppType			AS CustSuppType,
	MA_PurchaseDoc.Supplier				AS CustomerSupplier,
	MA_PurchaseDoc.Currency				AS Currency,
	MA_PurchaseDoc.FixingDate			AS FixingDate,
	MA_PurchaseDoc.FixingIsManual		AS FixingIsManual,
	MA_PurchaseDoc.Fixing				AS Fixing,
	MA_PurchaseDoc.PurchaseDocId		AS DocId,
	MA_PurchaseDocReferences.DocumentId	AS InvEntryId,
	MA_InventoryEntries.StoragePhase1	AS Storage,
	2									AS Phase
	FROM	MA_PurchaseDoc join MA_PurchaseDocReferences 
	ON
	MA_PurchaseDoc.PurchaseDocId = MA_PurchaseDocReferences.PurchaseDocId and
	MA_PurchaseDocReferences.DocumentType = 6684676 and
	MA_PurchaseDocReferences.TypeReference = 'InvMultiSt'
	join MA_InventoryEntries
	on
	MA_InventoryEntries.EntryId = MA_PurchaseDocReferences.DocumentId
	WHERE	MA_PurchaseDoc.DocumentType = 9830403 and
			MA_PurchaseDoc.InvEntryId = 0 and
		    MA_PurchaseDoc.ConformingStorage1 <> MA_InventoryEntries.StoragePhase1
GO

PRINT 'Vista [dbo].[MA_VTransactionReport] creata con successo'
GO

