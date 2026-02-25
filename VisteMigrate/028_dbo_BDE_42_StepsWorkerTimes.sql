-- Vista [dbo].[BDE_42_StepsWorkerTimes] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_42_StepsWorkerTimes')
BEGIN
    DROP VIEW [dbo].[BDE_42_StepsWorkerTimes]
    PRINT 'Vista [dbo].[BDE_42_StepsWorkerTimes] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_42_StepsWorkerTimes] AS
SELECT
	MO.MONo							AS MONumber,
	MOL.RtgStep						AS StepNumber,
	CASE
		WHEN MOL.LabourType = 28508161	THEN 0		-- attrezzaggio
		WHEN MOL.LabourType = 28508160	THEN 1		-- lavorazione
	END								AS Activity,
	MOL.ResourceCode				AS IdERPTeam,
	--''								AS IdERPWageLevel,	-- 20/09/2019: Alessio ha verificato che tale dato non è obbligatorio, ma dovrà essere compilato tramite script sql post processo con il livello salariale legato alla squadra in Bravo
	 CASE 
		WHEN MOL.AttendancePerc > 0	
		THEN CASE WHEN MOL.LabourType = 28508161 /*attrezzaggio*/ THEN (MOS.SetupTime*MOL.AttendancePerc)/100 ELSE (MOS.ProcessingTime*MOL.AttendancePerc)/100 END
		ELSE MOL.WorkingTime
	END								AS WorkerTime,
	(MOL.AttendancePerc/100)		AS WorkerTimeRatio,
	MOL.NoOfResources				AS WorkersNumber,
	''								AS Notes,
	MOL.TBModified					AS BMUpdate

		
	
FROM
	MA_MOLabour MOL
	INNER JOIN MA_MOSteps MOS
		ON MOL.MOId = MOS.MOId
			AND MOL.RtgStep = MOS.RtgStep
			AND MOL.Alternate = MOS.Alternate
			AND MOL.AltRtgStep = MOS.AltRtgStep
	INNER JOIN MA_MO MO
		ON MO.MOId = MOL.MOId
where
	Phase = 28573696 -- preventivo
	AND MO.MOStatus IN
	(
		20578304,	-- LANCIATO
		20578305,	-- IN LAVORAZIONE
		20578306	-- TERMINATO
	)
	AND MO.MONo != ''
	AND ((MOS.Alternate = '' and MOS.AltRtgStep = 0) OR (MOS.Alternate != '' AND MOS.AltRtgStep != 0))

	AND MOL.ResourceType =  27131908 -- SQUADRA (non importiamo le righe di tipo matricola perché non gestite da Bravo M.)
										-- deciso da Danilo con mail del 17/09/2019 
	AND MOS.WC IN 
					(
							SELECT 
								WorkCenter 	
							FROM 
								BM_ConsoleWC 
							--WHERE Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)
GO

PRINT 'Vista [dbo].[BDE_42_StepsWorkerTimes] creata con successo'
GO

