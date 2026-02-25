-- Vista [dbo].[MA_AvailabilityAnalysis] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_AvailabilityAnalysis')
BEGIN
    DROP VIEW [dbo].[MA_AvailabilityAnalysis]
    PRINT 'Vista [dbo].[MA_AvailabilityAnalysis] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_AvailabilityAnalysis] AS  SELECT 
	3801100										AS CodeType, 
	MA_PurchaseOrdDetails.PurchaseOrdId			AS DocumentId, 
	MA_PurchaseOrd.InternalOrdNo				AS DocumentNumber, 
	MA_PurchaseOrdDetails.Line					AS Line, 
	MA_PurchaseOrdDetails.Item					AS Item, 
	MA_PurchaseOrdDetails.UoM					AS UoM, 
	MA_PurchaseOrdDetails.Job					AS Job,
	MA_PurchaseOrdDetails.Qty - MA_PurchaseOrdDetails.DeliveredQty	AS IssuedQuantity, 
	0										AS PickedQuantity, 
	MA_PurchaseOrdDetails.ExpectedDeliveryDate		AS FromDate, 
	2										AS Sequence
		FROM	MA_PurchaseOrdDetails, MA_PurchaseOrd 
		WHERE	MA_PurchaseOrdDetails.PurchaseOrdId = MA_PurchaseOrd.PurchaseOrdId AND 
				MA_PurchaseOrdDetails.Qty - MA_PurchaseOrdDetails.DeliveredQty > 0.0 AND 
				MA_PurchaseOrdDetails.Delivered = '0' AND 
				MA_PurchaseOrdDetails.Cancelled = '0' AND
				MA_PurchaseOrdDetails.LineType != 3538948

	UNION ALL  SELECT 
						
	3801103						AS CodeType, 
	MA_MO.MOId					AS DocumentId, 
	MA_MO.MONo					AS DocumentNumber, 
	0							AS Line, 
	MA_MO.BOM					AS Item, 
	MA_MO.UoM					AS UoM, 
	MA_MO.Job					AS Job,
	MA_MO.ProductionQty - MA_MO.ProducedQty - MA_MO.SecondRateQuantity	AS IssuedQuantity, 
	0							AS PickedQuantity, 
	MA_MO.DeliveryDate			AS FromDate, 
	3							AS Sequence 
		FROM	MA_MO 
		WHERE	MA_MO.Simulation = '' AND 
				(MA_MO.MOStatus = 20578304 OR MA_MO.MOStatus = 20578305 OR MA_MO.MOStatus = 20578307) AND 
				MA_MO.ProductionQty - MA_MO.ProducedQty - MA_MO.SecondRateQuantity > 0.0 

	UNION ALL  SELECT 
	
	3801103																AS CodeType, 
	MA_MOComponents.MOId												AS DocumentId, 
	MA_MOComponents.MONo												AS DocumentNumber, 
	MA_MOComponents.Line												AS Line, 
	MA_MOComponents.Component											AS Item, 
	MA_MOComponents.UoM													AS UoM, 
	MA_MO.Job															AS Job,
	0																	AS IssuedQuantity, 
	MA_MOComponents.NeededQty - MA_MOComponents.PickedQuantity			AS PickedQuantity, 
	MA_MO.DeliveryDate													AS FromDate, 
	4																	AS Sequence 
	FROM	MA_MOComponents, MA_MO 
	WHERE	MA_MOComponents.ReferredPosition = -1 AND 
			MA_MOComponents.Simulation = '' AND 
			MA_MOComponents.NeededQty - MA_MOComponents.PickedQuantity > 0.0 AND
			MA_MOComponents.Closed = '0' AND 
			MA_MOComponents.MOId = MA_MO.MOId AND 
			(MA_MO.MOStatus = 20578304 OR MA_MO.MOStatus = 20578305 OR MA_MO.MOStatus = 20578307) 
	
	UNION ALL  SELECT 
	
	3801098														AS CodeType, 
	MA_SaleOrdDetails.SaleOrdId									AS DocumentId, 
	MA_SaleOrd.InternalOrdNo									AS DocumentNumber, 
	MA_SaleOrdDetails.Line										AS Line, 
	MA_SaleOrdDetails.Item										AS Item, 
	MA_SaleOrdDetails.UoM										AS UoM, 
	MA_SaleOrdDetails.Job										AS Job, 
	0															AS IssuedQuantity, 
	MA_SaleOrdDetails.Qty - MA_SaleOrdDetails.DeliveredQty		AS PickedQuantity, 
	MA_SaleOrdDetails.ExpectedDeliveryDate						AS FromDate, 
	5														AS Sequence 
	FROM	MA_SaleOrdDetails, MA_SaleOrd 
	WHERE	MA_SaleOrdDetails.SaleOrdId = MA_SaleOrd.SaleOrdId AND 
			MA_SaleOrdDetails.Qty - MA_SaleOrdDetails.DeliveredQty > 0.0 AND 
			MA_SaleOrdDetails.Delivered = '0' AND 
			MA_SaleOrdDetails.Cancelled = '0' AND
			MA_SaleOrdDetails.LineType != 3538948
GO

PRINT 'Vista [dbo].[MA_AvailabilityAnalysis] creata con successo'
GO

