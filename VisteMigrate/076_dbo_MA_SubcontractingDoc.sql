-- Vista [dbo].[MA_SubcontractingDoc] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_SubcontractingDoc')
BEGIN
    DROP VIEW [dbo].[MA_SubcontractingDoc]
    PRINT 'Vista [dbo].[MA_SubcontractingDoc] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_SubcontractingDoc] AS  SELECT DISTINCT
	MA_PurchaseOrdDetails.MOId					AS MOId, 
	3801100									AS CodeType, 
	MA_PurchaseOrdDetails.PurchaseOrdId					AS DocumentId, 
	MA_PurchaseOrd.InternalOrdNo				AS DocumentNumber, 
	MA_PurchaseOrd.OrderDate					AS DocumentDate, 
	MA_PurchaseOrd.Supplier						AS Supplier
		FROM	MA_PurchaseOrdDetails, MA_PurchaseOrd, MA_MO
		WHERE	MA_PurchaseOrdDetails.PurchaseOrdId = MA_PurchaseOrd.PurchaseOrdId AND 
				MA_PurchaseOrdDetails.MOId = MA_MO.MOId

	UNION ALL SELECT DISTINCT
						
	MA_SaleDocDetail.MOId				AS MOId, 
	3801088									AS CodeType, 
	MA_SaleDocDetail.SaleDocId			AS DocumentId, 
	MA_SaleDoc.DocNo						AS DocumentNumber, 
	MA_SaleDoc.DocumentDate				AS DocumentDate, 
	MA_SaleDoc.CustSupp					AS Supplier
		FROM	MA_SaleDocDetail, MA_SaleDoc, MA_MO 
		WHERE	MA_SaleDocDetail.SaleDocId = MA_SaleDoc.SaleDocId AND 
				MA_SaleDocDetail.MOId = MA_MO.MOId

	UNION ALL SELECT DISTINCT
						
	MA_PurchaseDocDetail.MOId				AS MOId, 
	3801108									AS CodeType, 
	MA_PurchaseDocDetail.PurchaseDocId		AS DocumentId, 
	MA_PurchaseDoc.SupplierDocNo			AS DocumentNumber, 
	MA_PurchaseDoc.SupplierDocDate	AS DocumentDate, 
	MA_PurchaseDoc.Supplier				AS Supplier
		FROM	MA_PurchaseDocDetail, MA_PurchaseDoc, MA_MO 
		WHERE	MA_PurchaseDocDetail.PurchaseDocId = MA_PurchaseDoc.PurchaseDocId AND 
				MA_PurchaseDocDetail.MOId = MA_MO.MOId AND
				MA_PurchaseDoc.DocumentType = 9830404
GO

PRINT 'Vista [dbo].[MA_SubcontractingDoc] creata con successo'
GO

