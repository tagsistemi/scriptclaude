-- Vista [dbo].[BDE_41_MOSteps] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_41_MOSteps')
BEGIN
    DROP VIEW [dbo].[BDE_41_MOSteps]
    PRINT 'Vista [dbo].[BDE_41_MOSteps] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_41_MOSteps] AS
SELECT
	MOS.MONo					AS MONumber,
	MOS.RtgStep					AS StepNumber,
	MOS.WC						AS IdERPAppliance,
	MOS.Operation				AS IdERPOperation,
	MOS.QueueTime				AS QueueTime,
	MOS.SetupTime				AS SetupTime,
	MOS.ProcessingTime			AS ProcessTime,
	-- per i tempi di manodopera, prendo il tempo macchina (attraversamento) se la somma dei tempi matricola è > tempo macchina, altrimenti prendo i tempi matricola
	COALESCE(CASE WHEN MOL.LabourSetupTime > 0		AND MOL.LabourSetupTime <= MOS.SetupTime			THEN MOL.LabourSetupTime		ELSE MOS.SetupTime		END ,0)		AS WorkerSetupTime,
	COALESCE(CASE WHEN MOL.LabourProcessingTime> 0	AND MOL.LabourProcessingTime <= MOS.ProcessingTime	THEN MOL.LabourProcessingTime	ELSE MOS.ProcessingTime	END, 0)		AS WorkerProcessTime,
	MOS.ProductionQty			AS ProductionQuantity,
	MO.UoM						AS IdERPUnitOfMeasure,
	MOS.Outsourced				AS ExternalStep,
	'0'							AS CancelledStep,
	CAST(MOS.Notes	AS Varchar(1024)) AS Notes,
	MOS.StepRunDate				AS StepLaunchDate,
	MOS.StepDeliveryDate		AS StepDeliveryDate,
	MOS.Alternate				AS Alternate,
	MOS.AltRtgStep				AS AlternateStepNumber,
	MOS.EstimatedQueueTime		AS SimQueueTime,
	MOS.EstimatedSetupTime		AS SimSetupTime,
	MOS.EstimatedProcessingTime	AS SimProcessTime,
	MOS.SimStartDate			AS SimStartDate,
	MOS.SimEndDate				AS SimEndDate,
	MOS.PreviousStepQuantity	AS BalPreviousStepQuantity,
	MOS.ProducedQty				AS BalProducedQuantity,
	MOS.SecondRateQuantity		AS BalSecondRateQuantity,
	MOS.ScrapQuantity			AS BalScrapQuantity,
	MOS.StartingDate			AS BalStartDate,
	MOS.EndingDate				AS BalEndDate,
	MOS.ActualSetupTime			AS BalSetupTime,
	MOS.ActualProcessingTime	AS BalProcessTime,
	CASE
		WHEN MOS.MOStatus = 20578307 THEN 0			-- Confermato
		WHEN MOS.MOStatus = 20578304 THEN 1			-- Lanciato
		WHEN MOS.MOStatus = 20578305 THEN 2			-- In Lavorazione
		WHEN MOS.MOStatus = 20578306 THEN 3			-- Terminato
	END							AS BalStatus,
	EstimatedWC					AS SimIdERPAppliance,
	ActualWC					AS BalIdERPAppliance,
	MOS.TBModified				AS BMUpdate

FROM
	MA_MOSteps MOS
	INNER JOIN MA_MO MO
		ON MOS.MOId = MO.MOId
	LEFT OUTER JOIN 
		(
			SELECT
				MOL2.MOId,
				MOL2.RtgStep,
				MOL2.Alternate,
				MOL2.AltRtgStep,
				sum(
						CASE 
							WHEN MOL2.LabourType = 28508161 -- attrezzaggio
							THEN CASE WHEN MOL2.AttendancePerc > 0	THEN (MOS2.SetupTime*MOL2.AttendancePerc*MOL2.NoOfResources)/100		ELSE MOL2.WorkingTime*MOL2.NoOfResources END
							ELSE 0
						END
					) AS LabourSetupTime,
				sum(
						CASE 
							WHEN MOL2.LabourType = 28508160 -- lavorazione
							THEN CASE WHEN MOL2.AttendancePerc > 0	THEN (MOS2.ProcessingTime*MOL2.AttendancePerc*MOL2.NoOfResources)/100	ELSE MOL2.WorkingTime*MOL2.NoOfResources END
							ELSE 0
						END
					) AS LabourProcessingTime
			FROM
				MA_MOLabour MOL2
				INNER JOIN MA_MOSteps MOS2
					ON MOL2.MOId = MOS2.MOId
						AND MOL2.RtgStep = MOS2.RtgStep
						AND MOL2.Alternate = MOS2.Alternate
						AND MOL2.AltRtgStep = MOS2.AltRtgStep
			where
				Phase = 28573696 -- preventivo
			GROUP BY
				MOL2.MOId,
				MOL2.RtgStep,
				MOL2.Alternate,
				MOL2.AltRtgStep
	
		) MOL
		ON MOL.MOId = MOS.MOId
			AND MOL.RtgStep = MOS.RtgStep
			AND MOL.Alternate = MOS.Alternate
			AND MOL.AltRtgStep = MOS.AltRtgStep
WHERE
	MO.MOStatus IN
	(
		20578304,	-- LANCIATO
		20578305,	-- IN LAVORAZIONE
		20578306	-- TERMINATO
	)
	AND MO.MONo != ''
	AND ((MOS.Alternate = '' and MOS.AltRtgStep = 0) OR (MOS.Alternate != '' AND MOS.AltRtgStep != 0))
	AND MOS.WC IN 
					(
							SELECT 
								WorkCenter 	
							FROM 
								BM_ConsoleWC 
							--WHERE Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)
GO

PRINT 'Vista [dbo].[BDE_41_MOSteps] creata con successo'
GO

