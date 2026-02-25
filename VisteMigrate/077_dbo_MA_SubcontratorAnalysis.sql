-- Vista [dbo].[MA_SubcontratorAnalysis] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_SubcontratorAnalysis')
BEGIN
    DROP VIEW [dbo].[MA_SubcontratorAnalysis]
    PRINT 'Vista [dbo].[MA_SubcontratorAnalysis] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_SubcontratorAnalysis] AS  SELECT 
			MA_MOSteps.MOId				AS MOId, 
			MA_MOSteps.MONo				AS MONo, 
			MA_MO.CreationDate			AS CreationDate, 
            MA_MOSteps.WC					AS WC, 
            MA_MOSteps.BOM				AS BOM, 
			MA_MOSteps.UoM					AS UoM, 
            MA_MOSteps.ProductionQty		AS ProductionQty, 
            MA_MOSteps.ProducedQty			AS ProducedQty, 
            MA_MOSteps.Storage				AS Storage, 
            MA_MOSteps.Supplier			AS Supplier, 
            MA_MOSteps.ProcessingQuantity		AS ProcessingQuantity, 
            MA_MOComponents.Component		AS Component, 
            MA_MOComponents.NeededQty	AS NeededQty, 
            MA_MOSteps.Operation			AS Operation, 
            MA_MOSteps.RtgStep					AS RtgStep, 
            MA_MOSteps.Outsourced				AS Outsourced, 
            MA_MOComponents.DNRtgStep			AS DNRtgStep, 
            MA_MOSteps.AltRtgStep		AS AltRtgStep, 
            MA_MOSteps.Alternate			AS Alternate, 
            MA_MO.DeliveryDate				AS DeliveryDate, 
            MA_MO.InternalOrdNo			AS InternalOrdNo, 
            MA_MO.Customer					AS Customer, 
            MA_MO.Job					AS Job 
				FROM MA_MOSteps, MA_MOComponents, MA_MO 
				WHERE  MA_MOSteps.Outsourced = '1' AND 
					MA_MOSteps.Supplier > '' AND 
					(MA_MOSteps.MOStatus = 20578304 OR MA_MOSteps.MOStatus = 20578305 OR MA_MOSteps.MOStatus = 20578307) AND 
					MA_MOComponents.ReferredPosition = -1 AND 
					MA_MOComponents.Simulation =  '' AND 
					MA_MOComponents.MOId = MA_MOSteps.MOId AND 
					MA_MOComponents.IsAOverPick = 0 AND
					MA_MO.MOId = MA_MOSteps.MOId AND 
                    MA_MOSteps.RtgStep >= MA_MOComponents.DNRtgStep
GO

PRINT 'Vista [dbo].[MA_SubcontratorAnalysis] creata con successo'
GO

