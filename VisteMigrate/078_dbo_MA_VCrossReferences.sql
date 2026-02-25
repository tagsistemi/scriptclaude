-- Vista [dbo].[MA_VCrossReferences] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_VCrossReferences')
BEGIN
    DROP VIEW [dbo].[MA_VCrossReferences]
    PRINT 'Vista [dbo].[MA_VCrossReferences] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_VCrossReferences] AS  SELECT 
      MA_CrossReferences.OriginDocType,
      MA_CrossReferences.OriginDocID,
      MA_CrossReferences.OriginDocSubID,
      MA_CrossReferences.DerivedDocType,
      MA_CrossReferences.DerivedDocID,
      MA_CrossReferences.DerivedDocSubID,
     
	  CASE
      WHEN MA_CrossReferences.OriginDocType = 27066369 THEN (SELECT CreationDate from MA_WMTransferOrder WHERE MA_WMTransferOrder.ID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066370 THEN (SELECT PostingDate from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066372 THEN (SELECT OrderDate from MA_SaleOrd WHERE MA_SaleOrd.SaleOrdId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066374 THEN (SELECT OrderDate from MA_PurchaseOrd WHERE MA_PurchaseOrd.PurchaseOrdId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066375 OR MA_CrossReferences.OriginDocType = 27066376 OR MA_CrossReferences.OriginDocType = 27066477 THEN (SELECT PreShippingDate from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066378 OR MA_CrossReferences.OriginDocType = 27066379 OR MA_CrossReferences.OriginDocType = 27066380 THEN (SELECT GoodsReceiptDate FROM MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066383 OR MA_CrossReferences.OriginDocType = 27066384 THEN (SELECT DocumentDate FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066400 OR MA_CrossReferences.OriginDocType = 27066401 THEN (SELECT DocumentDate FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType BETWEEN 27066418 AND 27066420 OR MA_CrossReferences.OriginDocType BETWEEN 27066429 AND 27066431 THEN (SELECT PostingDate FROM MA_JournalEntries WHERE MA_JournalEntries.JournalEntryID = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType BETWEEN 27066422 AND 27066423 THEN (SELECT DocumentDate FROM MA_PyblsRcvbls WHERE MA_PyblsRcvbls.PymtSchedId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  = 27066424 THEN (SELECT PostingDate FROM MA_CostAccEntries WHERE MA_CostAccEntries.EntryId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  = 27066425 THEN (SELECT DocumentDate FROM MA_Fees WHERE MA_Fees.FeeId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  BETWEEN 27066426 AND 27066427 THEN (SELECT DocumentDate FROM MA_JournalEntries LEFT OUTER JOIN MA_Intra ON MA_JournalEntries.JournalEntryId = MA_Intra.JournalEntryId WHERE MA_Intra.IntrastatId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  = 27066428 THEN (SELECT PostingDate FROM MA_FixAssetEntries WHERE MA_FixAssetEntries.EntryId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066417 THEN (SELECT DocumentDate FROM MA_AdditionalCharges WHERE MA_AdditionalCharges.AdditionalChargesId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066371 THEN (SELECT QuotationDate from MA_CustQuotas WHERE MA_CustQuotas.CustQuotaId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066432 THEN (SELECT ChangeRetailDataDate FROM MA_ChangeRetailData WHERE MA_ChangeRetailData.ChangeRetailDataID = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066411 THEN (SELECT DeliveryDate FROM MA_MO WHERE MA_MO.MOId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066437 THEN (SELECT DocumentDate FROM MA_BOMPosting WHERE MA_BOMPosting.BOMPostingId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066409 THEN (SELECT InspectionOrderDate FROM MA_InspectionOrders WHERE MA_InspectionOrders.InspectionOrderId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066410 THEN (SELECT InspectionNotesDate FROM MA_InspectionNotes WHERE MA_InspectionNotes.InspectionNotesId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066413 OR MA_CrossReferences.OriginDocType = 27066414 THEN (SELECT PostingDate from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066402 OR MA_CrossReferences.OriginDocType = 27066406 OR MA_CrossReferences.OriginDocType = 27066403 OR MA_CrossReferences.OriginDocType = 27066404 OR MA_CrossReferences.OriginDocType = 27066405 THEN (SELECT DocumentDate FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066381 OR MA_CrossReferences.OriginDocType = 27066382 OR MA_CrossReferences.OriginDocType = 27066398 OR MA_CrossReferences.OriginDocType = 27066385 OR MA_CrossReferences.OriginDocType = 27066386 OR MA_CrossReferences.OriginDocType = 27066391 OR MA_CrossReferences.OriginDocType = 27066433 OR MA_CrossReferences.OriginDocType = 27066399 OR MA_CrossReferences.OriginDocType = 27066392 OR MA_CrossReferences.OriginDocType = 27066393 OR MA_CrossReferences.OriginDocType = 27066397 OR MA_CrossReferences.OriginDocType = 27066387 OR MA_CrossReferences.OriginDocType = 27066388 OR MA_CrossReferences.OriginDocType = 27066396 OR MA_CrossReferences.OriginDocType = 27066389 OR MA_CrossReferences.OriginDocType = 27066394 OR MA_CrossReferences.OriginDocType = 27066395 THEN (SELECT DocumentDate FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066436 THEN (SELECT DocumentDate FROM MA_CommissionEntries WHERE MA_CommissionEntries.EntryId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066373 THEN (SELECT QuotationDate from MA_SuppQuotas WHERE MA_SuppQuotas.SuppQuotaId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066421 OR MA_CrossReferences.OriginDocType = 27066434 THEN (SELECT PreShippingDate from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066435 THEN (SELECT GoodsReceiptDate from MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066407 THEN (SELECT InventoryDate from MA_WMInventory WHERE MA_WMInventory.InventoryID = MA_CrossReferences.OriginDocID)
	  ELSE '17991231'
      END AS OriginDocDate,
     
	  CASE
      WHEN MA_CrossReferences.OriginDocType = 27066369 THEN (SELECT TONumber from MA_WMTransferOrder WHERE MA_WMTransferOrder.ID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066370 THEN (SELECT DocNo from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066372 THEN (SELECT InternalOrdNo from MA_SaleOrd WHERE MA_SaleOrd.SaleOrdId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066374 THEN (SELECT ExternalOrdNo from MA_PurchaseOrd WHERE MA_PurchaseOrd.PurchaseOrdId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066375 OR MA_CrossReferences.OriginDocType = 27066376 OR MA_CrossReferences.OriginDocType = 27066477 THEN (SELECT PreShippingNo from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066378 OR MA_CrossReferences.OriginDocType = 27066379 OR MA_CrossReferences.OriginDocType = 27066380 THEN (SELECT GoodsReceiptNumber from MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066383 OR MA_CrossReferences.OriginDocType = 27066384 THEN (SELECT DocNo FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066400 OR MA_CrossReferences.OriginDocType = 27066401 THEN (SELECT DocNo FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066418 OR MA_CrossReferences.OriginDocType = 27066429 THEN (SELECT RefNo FROM MA_JournalEntries WHERE MA_JournalEntries.JournalEntryID = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType BETWEEN 27066419 AND 27066420 OR MA_CrossReferences.OriginDocType BETWEEN 27066430 AND 27066431 THEN (SELECT DocNo FROM MA_JournalEntries WHERE MA_JournalEntries.JournalEntryID = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType BETWEEN 27066422 AND 27066423 THEN (SELECT DocNo FROM MA_PyblsRcvbls WHERE MA_PyblsRcvbls.PymtSchedId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  = 27066424 THEN (SELECT DocNo FROM MA_CostAccEntries WHERE MA_CostAccEntries.EntryId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  = 27066425 THEN (SELECT DocNo FROM MA_Fees WHERE MA_Fees.FeeId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  BETWEEN 27066426 AND 27066427 THEN (SELECT DocNo FROM MA_JournalEntries LEFT OUTER JOIN MA_Intra ON MA_JournalEntries.JournalEntryId = MA_Intra.JournalEntryId WHERE MA_Intra.IntrastatId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType  = 27066428 THEN (SELECT DocNo FROM MA_FixAssetEntries WHERE MA_FixAssetEntries.EntryId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066417 THEN (SELECT DocumentNumber FROM MA_AdditionalCharges WHERE MA_AdditionalCharges.AdditionalChargesId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066371 THEN (SELECT QuotationNo from MA_CustQuotas WHERE MA_CustQuotas.CustQuotaId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066432 THEN (SELECT ChangeRetailDataNo FROM MA_ChangeRetailData WHERE MA_ChangeRetailData.ChangeRetailDataID = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066411 THEN (SELECT MONo FROM MA_MO WHERE MA_MO.MOId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066437 THEN (SELECT DocumentNo FROM MA_BOMPosting WHERE MA_BOMPosting.BOMPostingId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066409 THEN (SELECT InspectionOrderNo FROM MA_InspectionOrders WHERE MA_InspectionOrders.InspectionOrderId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066410 THEN (SELECT InspectionNotesNo FROM MA_InspectionNotes WHERE MA_InspectionNotes.InspectionNotesId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066413 OR MA_CrossReferences.OriginDocType = 27066414 THEN (SELECT DocNo from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066402 OR MA_CrossReferences.OriginDocType = 27066406 OR MA_CrossReferences.OriginDocType = 27066403 OR MA_CrossReferences.OriginDocType = 27066404 OR MA_CrossReferences.OriginDocType = 27066405 THEN (SELECT DocNo FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066381 OR MA_CrossReferences.OriginDocType = 27066382 OR MA_CrossReferences.OriginDocType = 27066398 OR MA_CrossReferences.OriginDocType = 27066385 OR MA_CrossReferences.OriginDocType = 27066386 OR MA_CrossReferences.OriginDocType = 27066391 OR MA_CrossReferences.OriginDocType = 27066433 OR MA_CrossReferences.OriginDocType = 27066399 OR MA_CrossReferences.OriginDocType = 27066392 OR MA_CrossReferences.OriginDocType = 27066393 OR MA_CrossReferences.OriginDocType = 27066397 OR MA_CrossReferences.OriginDocType = 27066387 OR MA_CrossReferences.OriginDocType = 27066388 OR MA_CrossReferences.OriginDocType = 27066396 OR MA_CrossReferences.OriginDocType = 27066389 OR MA_CrossReferences.OriginDocType = 27066394 OR MA_CrossReferences.OriginDocType = 27066395 THEN (SELECT DocNo FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066436 THEN (SELECT DocNo FROM MA_CommissionEntries WHERE MA_CommissionEntries.EntryId = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066373 THEN (SELECT QuotationNo from MA_SuppQuotas WHERE MA_SuppQuotas.SuppQuotaId = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.OriginDocType = 27066421 OR MA_CrossReferences.OriginDocType = 27066434 THEN (SELECT PreShippingNo from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066435 THEN (SELECT GoodsReceiptNumber from MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.OriginDocID)
      WHEN MA_CrossReferences.OriginDocType = 27066407 THEN (SELECT InventoryNumber from MA_WMInventory WHERE MA_WMInventory.InventoryID = MA_CrossReferences.OriginDocID)
	  ELSE ''
      END AS OriginDocNo,

	  CASE
      WHEN MA_CrossReferences.DerivedDocType = 27066369 THEN (SELECT CreationDate from MA_WMTransferOrder WHERE MA_WMTransferOrder.ID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066370 THEN (SELECT PostingDate from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066372 THEN (SELECT OrderDate from MA_SaleOrd WHERE MA_SaleOrd.SaleOrdId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066374 THEN (SELECT OrderDate from MA_PurchaseOrd WHERE MA_PurchaseOrd.PurchaseOrdId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066375 OR MA_CrossReferences.DerivedDocType = 27066376 OR MA_CrossReferences.DerivedDocType = 27066477 THEN (SELECT PreShippingDate from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066378 OR MA_CrossReferences.DerivedDocType = 27066379 OR MA_CrossReferences.DerivedDocType = 27066380 THEN (SELECT GoodsReceiptDate from MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066383 OR MA_CrossReferences.DerivedDocType = 27066384 THEN (SELECT DocumentDate FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066400 OR MA_CrossReferences.DerivedDocType = 27066401 THEN (SELECT DocumentDate FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType BETWEEN 27066418 AND 27066420 OR MA_CrossReferences.DerivedDocType BETWEEN 27066429 AND 27066431 THEN (SELECT PostingDate FROM MA_JournalEntries WHERE MA_JournalEntries.JournalEntryID = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType BETWEEN 27066422 AND 27066423 THEN (SELECT DocumentDate FROM MA_PyblsRcvbls WHERE MA_PyblsRcvbls.PymtSchedId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  = 27066424 THEN (SELECT PostingDate FROM MA_CostAccEntries WHERE MA_CostAccEntries.EntryId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  = 27066425 THEN (SELECT DocumentDate FROM MA_Fees WHERE MA_Fees.FeeId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  BETWEEN 27066426 AND 27066427 THEN (SELECT DocumentDate FROM MA_JournalEntries LEFT OUTER JOIN MA_Intra ON MA_JournalEntries.JournalEntryId = MA_Intra.JournalEntryId WHERE MA_Intra.IntrastatId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  = 27066428 THEN (SELECT PostingDate FROM MA_FixAssetEntries WHERE MA_FixAssetEntries.EntryId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066417 THEN (SELECT DocumentDate FROM MA_AdditionalCharges WHERE MA_AdditionalCharges.AdditionalChargesId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066371 THEN (SELECT QuotationDate from MA_CustQuotas WHERE MA_CustQuotas.CustQuotaId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066432 THEN (SELECT ChangeRetailDataDate FROM MA_ChangeRetailData WHERE MA_ChangeRetailData.ChangeRetailDataID = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066411 THEN (SELECT DeliveryDate FROM MA_MO WHERE MA_MO.MOId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066437 THEN (SELECT DocumentDate FROM MA_BOMPosting WHERE MA_BOMPosting.BOMPostingId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066409 THEN (SELECT InspectionOrderDate FROM MA_InspectionOrders WHERE MA_InspectionOrders.InspectionOrderId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066410 THEN (SELECT InspectionNotesDate FROM MA_InspectionNotes WHERE MA_InspectionNotes.InspectionNotesId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066413 OR MA_CrossReferences.DerivedDocType = 27066414 THEN (SELECT PostingDate from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066402 OR MA_CrossReferences.DerivedDocType = 27066406 OR MA_CrossReferences.DerivedDocType = 27066403 OR MA_CrossReferences.DerivedDocType = 27066404 OR MA_CrossReferences.DerivedDocType = 27066405 THEN (SELECT DocumentDate FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066381 OR MA_CrossReferences.DerivedDocType = 27066382 OR MA_CrossReferences.DerivedDocType = 27066398 OR MA_CrossReferences.DerivedDocType = 27066385 OR MA_CrossReferences.DerivedDocType = 27066386 OR MA_CrossReferences.DerivedDocType = 27066391 OR MA_CrossReferences.DerivedDocType = 27066433 OR MA_CrossReferences.DerivedDocType = 27066399 OR MA_CrossReferences.DerivedDocType = 27066392 OR MA_CrossReferences.DerivedDocType = 27066393 OR MA_CrossReferences.DerivedDocType = 27066397 OR MA_CrossReferences.DerivedDocType = 27066387 OR MA_CrossReferences.DerivedDocType = 27066388 OR MA_CrossReferences.DerivedDocType = 27066396 OR MA_CrossReferences.DerivedDocType = 27066389 OR MA_CrossReferences.DerivedDocType = 27066394 OR MA_CrossReferences.DerivedDocType = 27066395 THEN (SELECT DocumentDate FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066436 THEN (SELECT DocumentDate FROM MA_CommissionEntries WHERE MA_CommissionEntries.EntryId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066373 THEN (SELECT QuotationDate from MA_SuppQuotas WHERE MA_SuppQuotas.SuppQuotaId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066421 OR MA_CrossReferences.DerivedDocType = 27066434 THEN (SELECT PreShippingDate from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066435 THEN (SELECT GoodsReceiptDate from MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066407 THEN (SELECT InventoryDate from MA_WMInventory WHERE MA_WMInventory.InventoryID = MA_CrossReferences.DerivedDocID)
	  ELSE '17991231'
      END AS DerivedDocDate,
     
	  CASE
      WHEN MA_CrossReferences.DerivedDocType = 27066369 THEN (SELECT TONumber from MA_WMTransferOrder WHERE MA_WMTransferOrder.ID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066370 THEN (SELECT DocNo from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066372 THEN (SELECT InternalOrdNo from MA_SaleOrd WHERE MA_SaleOrd.SaleOrdId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066374 THEN (SELECT ExternalOrdNo from MA_PurchaseOrd WHERE MA_PurchaseOrd.PurchaseOrdId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066375 OR MA_CrossReferences.DerivedDocType = 27066376 OR MA_CrossReferences.DerivedDocType = 27066477 THEN (SELECT PreShippingNo from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066378 OR MA_CrossReferences.DerivedDocType = 27066379 OR MA_CrossReferences.DerivedDocType = 27066380 THEN (SELECT GoodsReceiptNumber from MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066383 OR MA_CrossReferences.DerivedDocType = 27066384 THEN (SELECT DocNo FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066400 OR MA_CrossReferences.DerivedDocType = 27066401 THEN (SELECT DocNo FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066418 OR MA_CrossReferences.OriginDocType = 27066429 THEN (SELECT RefNo FROM MA_JournalEntries WHERE MA_JournalEntries.JournalEntryID = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType BETWEEN 27066419 AND 27066420 OR MA_CrossReferences.DerivedDocType BETWEEN 27066430 AND 27066431 THEN (SELECT DocNo FROM MA_JournalEntries WHERE MA_JournalEntries.JournalEntryID = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType BETWEEN 27066422 AND 27066423 THEN (SELECT DocNo FROM MA_PyblsRcvbls WHERE MA_PyblsRcvbls.PymtSchedId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  = 27066424 THEN (SELECT DocNo FROM MA_CostAccEntries WHERE MA_CostAccEntries.EntryId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  = 27066425 THEN (SELECT DocNo FROM MA_Fees WHERE MA_Fees.FeeId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  BETWEEN 27066426 AND 27066427 THEN (SELECT DocNo FROM MA_JournalEntries LEFT OUTER JOIN MA_Intra ON MA_JournalEntries.JournalEntryId = MA_Intra.JournalEntryId WHERE MA_Intra.IntrastatId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType  = 27066428 THEN (SELECT DocNo FROM MA_FixAssetEntries WHERE MA_FixAssetEntries.EntryId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066417 THEN (SELECT DocumentNumber FROM MA_AdditionalCharges WHERE MA_AdditionalCharges.AdditionalChargesId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066371 THEN (SELECT QuotationNo from MA_CustQuotas WHERE MA_CustQuotas.CustQuotaId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066432 THEN (SELECT ChangeRetailDataNo FROM MA_ChangeRetailData WHERE MA_ChangeRetailData.ChangeRetailDataID = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066411 THEN (SELECT MONo FROM MA_MO WHERE MA_MO.MOId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066437 THEN (SELECT DocumentNo FROM MA_BOMPosting WHERE MA_BOMPosting.BOMPostingId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066409 THEN (SELECT InspectionOrderNo FROM MA_InspectionOrders WHERE MA_InspectionOrders.InspectionOrderId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066410 THEN (SELECT InspectionNotesNo FROM MA_InspectionNotes WHERE MA_InspectionNotes.InspectionNotesId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066413 OR MA_CrossReferences.DerivedDocType = 27066414 THEN (SELECT DocNo from MA_InventoryEntries WHERE MA_InventoryEntries.EntryId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066402 OR MA_CrossReferences.DerivedDocType = 27066406 OR MA_CrossReferences.DerivedDocType = 27066403 OR MA_CrossReferences.DerivedDocType = 27066404 OR MA_CrossReferences.DerivedDocType = 27066405 THEN (SELECT DocNo FROM MA_PurchaseDoc WHERE MA_PurchaseDoc.PurchaseDocId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066381 OR MA_CrossReferences.DerivedDocType = 27066382 OR MA_CrossReferences.DerivedDocType = 27066398 OR MA_CrossReferences.DerivedDocType = 27066385 OR MA_CrossReferences.DerivedDocType = 27066386 OR MA_CrossReferences.DerivedDocType = 27066391 OR MA_CrossReferences.DerivedDocType = 27066433 OR MA_CrossReferences.DerivedDocType = 27066399 OR MA_CrossReferences.DerivedDocType = 27066392 OR MA_CrossReferences.DerivedDocType = 27066393 OR MA_CrossReferences.DerivedDocType = 27066397 OR MA_CrossReferences.DerivedDocType = 27066387 OR MA_CrossReferences.DerivedDocType = 27066388 OR MA_CrossReferences.DerivedDocType = 27066396 OR MA_CrossReferences.DerivedDocType = 27066389 OR MA_CrossReferences.DerivedDocType = 27066394 OR MA_CrossReferences.DerivedDocType = 27066395 THEN (SELECT DocNo FROM MA_SaleDoc WHERE MA_SaleDoc.SaleDocId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066436 THEN (SELECT DocNo FROM MA_CommissionEntries WHERE MA_CommissionEntries.EntryId = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066373 THEN (SELECT QuotationNo from MA_SuppQuotas WHERE MA_SuppQuotas.SuppQuotaId = MA_CrossReferences.DerivedDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066421 OR MA_CrossReferences.DerivedDocType = 27066434 THEN (SELECT PreShippingNo from MA_WMPreShipping WHERE MA_WMPreShipping.PreShippingID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066435 THEN (SELECT GoodsReceiptNumber from MA_WMGoodsReceipt WHERE MA_WMGoodsReceipt.GoodsReceiptID = MA_CrossReferences.DerivedDocID)
      WHEN MA_CrossReferences.DerivedDocType = 27066407 THEN (SELECT InventoryNumber from MA_WMInventory WHERE MA_WMInventory.InventoryID = MA_CrossReferences.DerivedDocID)
	  ELSE ''
      END AS DerivedDocNo,

	  CASE
      WHEN MA_CrossReferences.OriginDocType = 27066369 THEN (SELECT Item from MA_WMTransferOrder WHERE MA_WMTransferOrder.ID = MA_CrossReferences.OriginDocID)
	  WHEN MA_CrossReferences.DerivedDocType = 27066369 THEN (SELECT Item from MA_WMTransferOrder WHERE MA_WMTransferOrder.ID = MA_CrossReferences.DerivedDocID)
      ELSE ''
      END AS Item

      FROM MA_CrossReferences
GO

PRINT 'Vista [dbo].[MA_VCrossReferences] creata con successo'
GO

