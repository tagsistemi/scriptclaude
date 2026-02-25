-- Vista [dbo].[BDE_24_BOMStepsWorkerTime] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_24_BOMStepsWorkerTime')
BEGIN
    DROP VIEW [dbo].[BDE_24_BOMStepsWorkerTime]
    PRINT 'Vista [dbo].[BDE_24_BOMStepsWorkerTime] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_24_BOMStepsWorkerTime] AS
SELECT
	BOM.BOM							AS IdERPBOM,
	'0'								AS Revision,
	BOML.RtgStep					AS StepNumber,
	BMR.Alternate					AS Alternate,
	BMR.AltRtgStep					AS AlternateStepNumber,	
	CASE
		WHEN BOML.LabourType = 28508161	THEN 0		-- attrezzaggio
		WHEN BOML.LabourType = 28508160	THEN 1		-- lavorazione
	END								AS Activity,
	BOML.ResourceCode				AS IdERPTeam,
	--''								AS IdERPWageLevel,	-- 20/09/2019: Alessio ha verificato che tale dato non è obbligatorio, ma dovrà essere compilato tramite script sql post processo con il livello salariale legato alla squadra in Bravo
	 CASE 
		WHEN BOML.AttendancePerc > 0	
		THEN CASE WHEN BOML.LabourType = 28508161 /*attrezzaggio*/ THEN (BMR.SetupTime*BOML.AttendancePerc)/100 ELSE (BMR.ProcessingTime*BOML.AttendancePerc)/100 END
		ELSE BOML.WorkingTime
	END								AS WorkerTime,
	(BOML.AttendancePerc/100)		AS WorkerTimeRatio,
	BOML.NoOfResources				AS WorkersNumber,
	''								AS Notes,
	BOML.TBModified					AS BMUpdate

		
	
FROM
	MA_BOMLabour BOML
	INNER JOIN MA_BillOfMaterialsRouting BMR
		ON BOML.BOM = BMR.BOM
			AND BOML.RtgStep = BMR.RtgStep
			AND BOML.Alternate = BMR.Alternate
			AND BOML.AltRtgStep = BMR.AltRtgStep
	INNER JOIN MA_BillOfMaterials BOM
		ON BOM.BOM = BOML.BOM
where
	((BMR.Alternate = '' and BMR.AltRtgStep = 0) OR (BMR.Alternate != '' AND BMR.AltRtgStep != 0))

	AND BOML.ResourceType =  27131908 -- SQUADRA (non importiamo le righe di tipo matricola perché non gestite da Bravo M.)
										-- deciso da Danilo con mail del 17/09/2019 
	AND BMR.WC IN 
					(
							SELECT 
								WorkCenter 	
							FROM 
								BM_ConsoleWC 
							--WHERE Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)
GO

PRINT 'Vista [dbo].[BDE_24_BOMStepsWorkerTime] creata con successo'
GO

