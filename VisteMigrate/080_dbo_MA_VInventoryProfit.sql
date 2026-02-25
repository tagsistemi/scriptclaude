-- Vista [dbo].[MA_VInventoryProfit] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VInventoryProfit')
BEGIN
    DROP VIEW [dbo].[MA_VInventoryProfit]
    PRINT 'Vista [dbo].[MA_VInventoryProfit] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VInventoryProfit] AS  SELECT 
	-- Bill of Lading
	0									  	AS DocumentType, 
	MA_PurchaseDoc.PurchaseDocId		  	AS DocId,
	MA_PurchaseDoc.InvEntryId 				AS InvEntryId,
	MA_PurchaseDoc.DocumentDate				AS DocumentDate, 
	'17991231'								AS OriginalDocumentDate, 
	MA_PurchaseDoc.SupplierDocNo			AS ExternalNumber, 
	MA_PurchaseDoc.DocNo					AS InternalNumber, 
	'  '									AS OriginalDocumentNumber, 
	MA_PurchaseDoc.Supplier					AS CustomerSupplier ,
	MA_PurchaseDoc.Currency					AS Currency,
	MA_PurchaseDoc.FixingDate				AS FixingDate,
	MA_PurchaseDoc.FixingIsManual			AS FixingIsManual,
	MA_PurchaseDoc.Fixing					AS Fixing
		FROM	MA_PurchaseDoc 
		WHERE	MA_PurchaseDoc.DocumentType = 9830400 -- E_PURCHASE_DOCUMENT_TYPE_BILL_OF_LADING

	UNION ALL SELECT 
	-- Return to Supplier
	1										AS DocumentType, 
	MA_SaleDoc.SaleDocId					AS DocId,
	MA_SaleDoc.InventoryIDReturn			AS InvEntryId,
	MA_SaleDoc.DocumentDate					AS DocumentDate, 
	'17991231'								AS OriginalDocumentDate, 
	'  '									AS ExternalNumber, 
	MA_SaleDoc.DocNo						AS InternalNumber, 
	'  '									AS OriginalDocumentNumber, 
	MA_SaleDoc.CustSupp						AS CustomerSupplier ,
	MA_SaleDoc.Currency						AS Currency,
	MA_SaleDoc.FixingDate					AS FixingDate,
	MA_SaleDoc.FixingIsManual				AS FixingIsManual,
	MA_SaleDoc.Fixing						AS Fixing
		FROM	MA_SaleDoc 
		WHERE	MA_SaleDoc.DocumentType = 3407881 -- E_DOCUMENT_TYPE_RETURN_TO_SUPPLIER
				 
	UNION ALL SELECT 	
	-- Purchase Invoice w/o BoL			 
	2										AS DocumentType, 
	MA_PurchaseDoc.PurchaseDocId			AS DocId,
	MA_PurchaseDoc.InvEntryId 				AS InvEntryId,
	MA_PurchaseDoc.DocumentDate				AS DocumentDate, 
	'17991231'								AS OriginalDocumentDate, 
	MA_PurchaseDoc.SupplierDocNo			AS ExternalNumber, 
	MA_PurchaseDoc.DocNo					AS InternalNumber, 
	'  '									AS OriginalDocumentNumber, 
	MA_PurchaseDoc.Supplier					AS CustomerSupplier ,
	MA_PurchaseDoc.Currency					AS Currency,
	MA_PurchaseDoc.FixingDate				AS FixingDate,
	MA_PurchaseDoc.FixingIsManual			AS FixingIsManual,
	MA_PurchaseDoc.Fixing					AS Fixing
		FROM MA_PurchaseDoc, MA_PurchaseDocDetail
		WHERE MA_PurchaseDoc.DocumentType = 9830401 AND -- E_PURCHASE_DOCUMENT_TYPE_INVOICE
			  MA_PurchaseDoc.PurchaseDocId = MA_PurchaseDocDetail.PurchaseDocId AND 
			  MA_PurchaseDocDetail.BillOfLadingId = 0 AND
			  MA_PurchaseDocDetail.Line = 1
		GROUP BY MA_PurchaseDoc.PurchaseDocId, MA_PurchaseDoc.InvEntryId, MA_PurchaseDoc.DocumentDate, MA_PurchaseDoc.DocNo, MA_PurchaseDoc.Supplier, MA_PurchaseDoc.SupplierDocNo,
				 MA_PurchaseDoc.Currency,MA_PurchaseDoc.FixingDate,MA_PurchaseDoc.FixingIsManual,MA_PurchaseDoc.Fixing
		
	UNION ALL SELECT 	
	-- Purchase Invoice w/ BoL	
	3										AS DocumentType, 
	MA_PurchaseDoc.PurchaseDocId			AS DocId,
	MA_PurchaseDoc.AdjValueOnlyInvEntryId 	AS InvEntryId,			-- @@@TODO add also InvMultiSt
	MA_PurchaseDoc.DocumentDate				AS DocumentDate, 
	(SELECT TOP 1 MA_PurchaseDoc.DocumentDate FROM MA_PurchaseDoc 
	WHERE MA_PurchaseDoc.PurchaseDocId = MA_PurchaseDocDetail.BillOfLadingId AND 
	MA_PurchaseDocDetail.BillOfLadingId <> 0 Order By MA_PurchaseDocDetail.BillOfLadingId desc) as OriginalDocumentDate,
	MA_PurchaseDoc.SupplierDocNo			AS ExternalNumber, 
	MA_PurchaseDoc.DocNo					AS InternalNumber, 
	'  '									AS OriginalDocumentNumber, 
	MA_PurchaseDoc.Supplier					AS CustomerSupplier ,
	MA_PurchaseDoc.Currency					AS Currency,
	MA_PurchaseDoc.FixingDate				AS FixingDate,
	MA_PurchaseDoc.FixingIsManual			AS FixingIsManual,
	MA_PurchaseDoc.Fixing					AS Fixing
		FROM  MA_PurchaseDoc, MA_PurchaseDocDetail
		WHERE MA_PurchaseDoc.DocumentType = 9830401 AND -- E_PURCHASE_DOCUMENT_TYPE_INVOICE
			  MA_PurchaseDoc.PurchaseDocId = MA_PurchaseDocDetail.PurchaseDocId AND 
			  MA_PurchaseDocDetail.BillOfLadingId <> 0 AND
			  MA_PurchaseDocDetail.Line = 1
		GROUP BY MA_PurchaseDoc.PurchaseDocId, MA_PurchaseDoc.AdjValueOnlyInvEntryId, MA_PurchaseDoc.DocumentDate, MA_PurchaseDoc.DocNo, MA_PurchaseDoc.Supplier, MA_PurchaseDoc.SupplierDocNo,
				 MA_PurchaseDoc.Currency,MA_PurchaseDoc.FixingDate,MA_PurchaseDoc.FixingIsManual,MA_PurchaseDoc.Fixing, MA_PurchaseDocDetail.BillOfLadingId
				
	UNION ALL SELECT 
	-- Purchase Corrections			
	4										AS DocumentType, 
	MA_PurchaseDoc.PurchaseDocId			AS DocId,
	MA_PurchaseDoc.InvEntryId 				AS InvEntryId,			-- @@@TODO add also InvMultiSt
	MA_PurchaseDoc.DocumentDate				AS DocumentDate, 
	(SELECT TOP 1 MA_Tabella.DocumentDate FROM MA_PurchaseDoc as MA_Tabella
	WHERE MA_Tabella.PurchaseDocId = MA_PurchaseDoc.CorrectedDocumentId
	Order By MA_Tabella.PurchaseDocId desc) AS OriginalDocumentDate,
	'  '									AS ExternalNumber, 
	MA_PurchaseDoc.DocNo					AS InternalNumber, 
	(SELECT TOP 1 MA_PurchaseDoc.DocNo FROM MA_PurchaseDoc as MA_Tabella
	WHERE MA_Tabella.PurchaseDocId = MA_PurchaseDoc.CorrectedDocumentId
	Order By MA_Tabella.PurchaseDocId desc) AS OriginalDocumentNumber,	
	MA_PurchaseDoc.Supplier					AS CustomerSupplier ,
	MA_PurchaseDoc.Currency					AS Currency,
	MA_PurchaseDoc.FixingDate				AS FixingDate,
	MA_PurchaseDoc.FixingIsManual			AS FixingIsManual,
	MA_PurchaseDoc.Fixing					AS Fixing
		FROM  MA_PurchaseDoc, MA_PurchaseDoc AS MA_Tabella
		WHERE MA_PurchaseDoc.DocumentType = 9830403 -- E_PURCHASE_DOCUMENT_TYPE_CORRECTION_INVOICE
		GROUP BY MA_PurchaseDoc.PurchaseDocId, MA_PurchaseDoc.InvEntryId, MA_PurchaseDoc.DocumentDate, MA_PurchaseDoc.DocNo, MA_PurchaseDoc.Supplier, MA_PurchaseDoc.CorrectedDocumentId, MA_PurchaseDoc.DocNo,
				 MA_PurchaseDoc.Currency,MA_PurchaseDoc.FixingDate,MA_PurchaseDoc.FixingIsManual,MA_PurchaseDoc.Fixing
		
	UNION ALL  SELECT 
	-- Delivery Notes		
	5									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId 				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	'17991231'							AS OriginalDocumentDate, 
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	'  '								AS OriginalDocumentNumber, 
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM	MA_SaleDoc 
		WHERE	MA_SaleDoc.DocumentType = 3407873 -- E_DOCUMENT_TYPE_DELIVERY_NOTE
				 
	UNION ALL  SELECT 				 	
	-- Return from Customer
	6									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InventoryIDReturn		AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	'17991231'							AS OriginalDocumentDate, 
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	'  '								AS OriginalDocumentNumber, 
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM	MA_SaleDoc 
		WHERE	MA_SaleDoc.DocumentType = 3407877 -- E_DOCUMENT_TYPE_RETURN_FROM_CUSTOMER
				 
	UNION ALL  SELECT 	
	-- Sale Invoice w/o DN
	7									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId 				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	'17991231'							AS OriginalDocumentDate, 
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	'  '								AS OriginalDocumentNumber, 
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM	MA_SaleDoc, MA_SaleDocDetail
		WHERE	MA_SaleDoc.DocumentType = 3407874 AND -- E_DOCUMENT_TYPE_INVOICE
		        MA_SaleDoc.SaleDocId = MA_SaleDocDetail.SaleDocId AND
				MA_SaleDocDetail.ReferenceDocumentId = 0 AND 
				MA_SaleDocDetail.Line = 1
				 
	UNION ALL SELECT	
	-- Sale invoice w/ DN
	8									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId 				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	(SELECT TOP 1 MA_Tabella.DocumentDate FROM MA_SaleDoc as MA_Tabella, MA_SaleDocDetail
	WHERE MA_Tabella.SaleDocId = MA_SaleDocDetail.ReferenceDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentDate,
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	(SELECT TOP 1 MA_Tabella.DocNo FROM MA_SaleDoc as MA_Tabella, MA_SaleDocDetail
	WHERE MA_Tabella.SaleDocId = MA_SaleDocDetail.ReferenceDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentNumber,
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM  MA_SaleDoc, MA_SaleDocDetail
		WHERE MA_SaleDoc.DocumentType = 3407874 AND -- E_DOCUMENT_TYPE_INVOICE
			  MA_SaleDoc.SaleDocId = MA_SaleDocDetail.SaleDocId AND 
			  MA_SaleDocDetail.ReferenceDocumentId <> 0 
		GROUP BY MA_SaleDoc.SaleDocId, MA_SaleDoc.InvEntryId, MA_SaleDoc.DocumentDate, MA_SaleDoc.DocNo, MA_SaleDoc.CustSupp,
				 MA_SaleDoc.Currency,MA_SaleDoc.FixingDate,MA_SaleDoc.FixingIsManual,MA_SaleDoc.Fixing
				 
	UNION ALL SELECT	
	-- Sale correction invoice
	9									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	(SELECT TOP 1 MA_Tabella.DocumentDate FROM MA_SaleDoc as MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.CorrectedDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentDate,
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	(SELECT TOP 1 MA_Tabella.DocNo FROM MA_SaleDoc as MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.CorrectedDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentNumber,	
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM  MA_SaleDoc
		WHERE MA_SaleDoc.DocumentType = 3407882 -- E_DOCUMENT_TYPE_INVOICE_CORRECTION
		GROUP BY MA_SaleDoc.SaleDocId, MA_SaleDoc.InvEntryId, MA_SaleDoc.DocumentDate, MA_SaleDoc.DocNo, MA_SaleDoc.CustSupp, MA_SaleDoc.CorrectedDocumentId,
				 MA_SaleDoc.Currency,MA_SaleDoc.FixingDate,MA_SaleDoc.FixingIsManual,MA_SaleDoc.Fixing
				 
	UNION ALL SELECT	
	-- Paragon
	10									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId 				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	'17991231'							AS OriginalDocumentDate, 
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	'  '								AS OriginalDocumentNumber, 
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM	MA_SaleDoc
		WHERE	MA_SaleDoc.DocumentType = 3407886 -- E_DOCUMENT_TYPE_PARAGON
				
	UNION ALL SELECT	
	-- Correction Paragon
	11									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId 				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	(SELECT TOP 1 MA_Tabella.DocumentDate FROM MA_SaleDoc AS MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.CorrectedDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentDate,	
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	(SELECT TOP 1 MA_Tabella.DocNo FROM MA_SaleDoc AS MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.CorrectedDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentNumber,		
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM  MA_SaleDoc
		WHERE MA_SaleDoc.DocumentType = 3407887 -- E_DOCUMENT_TYPE_PARAGON_CORRECTION
		GROUP BY MA_SaleDoc.SaleDocId, MA_SaleDoc.InvEntryId, MA_SaleDoc.DocumentDate, MA_SaleDoc.DocNo, MA_SaleDoc.CustSupp, MA_SaleDoc.CorrectedDocumentId,
				 MA_SaleDoc.Currency,MA_SaleDoc.FixingDate,MA_SaleDoc.FixingIsManual,MA_SaleDoc.Fixing

	UNION ALL  SELECT	
	-- Invoice of Paragon
	12									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId 				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	(SELECT TOP 1 MA_Tabella.DocumentDate FROM MA_SaleDoc AS MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.ParagonId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentDate,	
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	(SELECT TOP 1 MA_Tabella.DocNo FROM MA_SaleDoc AS MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.ParagonId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentNumber,		
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM	MA_SaleDoc
		WHERE	MA_SaleDoc.DocumentType = 3407874 AND -- E_DOCUMENT_TYPE_INVOICE
				MA_SaleDoc.IsParagon = 1

	UNION ALL  SELECT 	
	-- Accompanying invoice
	13									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId 				AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	'17991231'							AS OriginalDocumentDate, 
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	'  '								AS OriginalDocumentNumber, 
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM	MA_SaleDoc
		WHERE	MA_SaleDoc.DocumentType = 3407875 -- E_DOCUMENT_TYPE_ACCOMPANYING_INVOICE
		        
	UNION ALL SELECT	
	-- correction of Accompanying invoice
	14									AS DocumentType, 
	MA_SaleDoc.SaleDocId				AS DocId,
	MA_SaleDoc.InvEntryId        AS InvEntryId,
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	(SELECT TOP 1 MA_Tabella.DocumentDate FROM MA_SaleDoc as MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.CorrectedDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentDate,
	'  '								AS ExternalNumber, 
	MA_SaleDoc.DocNo					AS InternalNumber, 
	(SELECT TOP 1 MA_Tabella.DocNo FROM MA_SaleDoc as MA_Tabella
	WHERE MA_Tabella.SaleDocId = MA_SaleDoc.CorrectedDocumentId
	Order By MA_Tabella.SaleDocId desc) AS OriginalDocumentNumber,	
	MA_SaleDoc.CustSupp					AS CustomerSupplier ,
	MA_SaleDoc.Currency					AS Currency,
	MA_SaleDoc.FixingDate				AS FixingDate,
	MA_SaleDoc.FixingIsManual			AS FixingIsManual,
	MA_SaleDoc.Fixing					AS Fixing
		FROM  MA_SaleDoc
		WHERE MA_SaleDoc.DocumentType = 3407884 -- E_DOCUMENT_TYPE_ACCOMPANYING_INVOICE_CORRECTION
		GROUP BY MA_SaleDoc.SaleDocId, MA_SaleDoc.InvEntryId, MA_SaleDoc.DocumentDate, MA_SaleDoc.DocNo, MA_SaleDoc.CustSupp, MA_SaleDoc.CorrectedDocumentId,
				 MA_SaleDoc.Currency,MA_SaleDoc.FixingDate,MA_SaleDoc.FixingIsManual,MA_SaleDoc.Fixing
GO

PRINT 'Vista [dbo].[MA_VInventoryProfit] creata con successo'
GO

