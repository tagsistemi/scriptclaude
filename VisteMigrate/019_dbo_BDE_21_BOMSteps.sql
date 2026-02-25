-- Vista [dbo].[BDE_21_BOMSteps] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_21_BOMSteps')
BEGIN
    DROP VIEW [dbo].[BDE_21_BOMSteps]
    PRINT 'Vista [dbo].[BDE_21_BOMSteps] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_21_BOMSteps] AS
SELECT
	BMR.BOM						AS IdERPBOM,
	'0'							AS Revision,
	BMR.RtgStep					AS StepNumber,
	BMR.Alternate				AS Alternate,
	BMR.AltRtgStep				AS AlternateStepNumber,
	BMR.WC						AS IdERPAppliance,
	BMR.Operation				AS IdERPOperation,
	WC.Outsourced				AS ExternalStep,
	BMR.Notes					AS Notes,
	BMR.TotalTime				AS OverallProcessTime,
	BMR.QueueTime				AS QueueTime,
	BMR.SetupTime				AS SetupTime,
	BMR.ProcessingTime			AS ProcessTime,
	-- per i tempi di manodopera, prendo il tempo macchina (attraversamento) se la somma dei tempi matricola è > tempo macchina, altrimenti prendo i tempi matricola
	COALESCE(CASE WHEN BOML.LabourSetupTime > 0		AND BOML.LabourSetupTime <= BMR.SetupTime			THEN BOML.LabourSetupTime		ELSE BMR.SetupTime		END ,0)		AS WorkerSetupTime,
	COALESCE(CASE WHEN BOML.LabourProcessingTime> 0	AND BOML.LabourProcessingTime <= BMR.ProcessingTime	THEN BOML.LabourProcessingTime	ELSE BMR.ProcessingTime	END, 0)		AS WorkerProcessTime,
	
	BMR.TBModified					AS BMUpdate
FROM
	MA_BillOfMaterialsRouting BMR
	INNER JOIN MA_WorkCenters WC
		ON BMR.WC = WC.WC
	INNER JOIN MA_BillOfMaterials BOM
		ON BMR.BOM = BOM.BOM
	LEFT OUTER JOIN 
		(
			SELECT
				BOML2.BOM,
				BOML2.RtgStep,
				BOML2.Alternate,
				BOML2.AltRtgStep,
				sum(
						CASE 
							WHEN BOML2.LabourType = 28508161 -- attrezzaggio
							THEN CASE WHEN BOML2.AttendancePerc > 0	THEN (BMR2.SetupTime*BOML2.AttendancePerc*BOML2.NoOfResources)/100		ELSE BOML2.WorkingTime*BOML2.NoOfResources END
							ELSE 0
						END
					) AS LabourSetupTime,
				sum(
						CASE 
							WHEN BOML2.LabourType = 28508160 -- lavorazione
							THEN CASE WHEN BOML2.AttendancePerc > 0	THEN (BMR2.ProcessingTime*BOML2.AttendancePerc*BOML2.NoOfResources)/100	ELSE BOML2.WorkingTime*BOML2.NoOfResources END
							ELSE 0
						END
					) AS LabourProcessingTime
			FROM
				MA_BOMLabour BOML2
				INNER JOIN MA_BillOfMaterialsRouting BMR2
					ON BOML2.BOM = BMR2.BOM
						AND BOML2.RtgStep = BMR2.RtgStep
						AND BOML2.Alternate = BMR2.Alternate
						AND BOML2.AltRtgStep = BMR2.AltRtgStep
			GROUP BY
				BOML2.BOM,
				BOML2.RtgStep,
				BOML2.Alternate,
				BOML2.AltRtgStep
	
		) BOML
		ON BOML.BOM = BMR.BOM
			AND BOML.RtgStep = BMR.RtgStep
			AND BOML.Alternate = BMR.Alternate
			AND BOML.AltRtgStep = BMR.AltRtgStep
WHERE
	BOM.CodeType = 7798784	-- le distinte fantasma non vengono gestite in Bravo Manufacturing, quindi non verranno importate
	AND BMR.WC IN 
					(
							SELECT 
								WorkCenter 	
							FROM 
								BM_ConsoleWC 
							--WHERE Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)
GO

PRINT 'Vista [dbo].[BDE_21_BOMSteps] creata con successo'
GO

