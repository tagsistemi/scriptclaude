-- Vista [dbo].[BDE_40_ManufacturingOrders] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_40_ManufacturingOrders')
BEGIN
    DROP VIEW [dbo].[BDE_40_ManufacturingOrders]
    PRINT 'Vista [dbo].[BDE_40_ManufacturingOrders] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_40_ManufacturingOrders] AS
SELECT
	MO.MONo						AS MONumber,
	MO.BOM						AS IdERPItem,
	MO.UoM						AS IdERPUnitOfMeasure,
	MO.ProductionQty			AS ProductionQuantity,
	MO.InternalOrdNo			AS InternalOrderNumber,
	MO.Position					AS OrderPosition,
	MO.ProductionLotNumber		AS StockNumber,
	MO.DeliveryDate				AS DeliveryDate,
	-- SuspendMO
	MO.Notes					AS Notes,
	MO.CreationDate				AS CreationDate,
	MO.LastModificationDate		AS LastModifyDate,
	MO.RunDate					AS LaunchDate,
	MO.PrintDate				AS PrintDate,
	-- QueueTime
	MO.EstimatedSetupTime		AS SetupTime,
	MO.EstimatedProcessingTime	AS ProcessTime,
	MO.SimStartDate				AS SimStartDate,
	MO.SimEndDate				AS SimEndDate,
	--SimQueueTime
	MO.SimulatedSetupTime		AS SimSetupTime,
	MO.SimulatedProcessingTime	AS SimProcessTime,
	MO.ProducedQty				AS BalProducedQuantity,
	MO.SecondRateQuantity		AS BalSecondRateQuantity,
	MO.ScrapQuantity			AS BalScrapQuantity,
	MO.StartingDate				AS BalStartDate,
	MO.EndingDate				AS BalEndDate,
	MO.ActualSetupTime			AS BalSetupTime,
	MO.ActualProcessingTime		AS BalProcessTime,
	CASE MO.MOSTATUS
		WHEN 20578304 THEN 1 -- LANCIATO
		WHEN 20578305 THEN 2 -- IN LAVORAZIONE
		WHEN 20578306 THEN 3 -- TERMINATO
	END							AS BalStatus,
	MO.Customer					AS IdERPCustSupp,
	MO.Job						AS IdERPJob,
	MO.BOM						AS BOMNumber,
	'0'							AS BOMRevision,
	MO.TBModified				AS BMUpdate

FROM
	MA_MO MO
WHERE
	MO.MOStatus IN
	(
		20578304,	-- LANCIATO
		20578305,	-- IN LAVORAZIONE
		20578306	-- TERMINATO
	)
	AND MO.MONo != ''
	AND MO.MOId IN 
					(
							SELECT 
								MOS.MOId 	
							FROM 
								MA_MOSteps MOS
								INNER JOIN BM_ConsoleWC CWC 
									ON MOS.WC = CWC.WorkCenter
							--WHERE CWC.Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)
GO

PRINT 'Vista [dbo].[BDE_40_ManufacturingOrders] creata con successo'
GO

