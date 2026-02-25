-- Vista [dbo].[BDE_85_OperationsWorkerTimes] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_85_OperationsWorkerTimes')
BEGIN
    DROP VIEW [dbo].[BDE_85_OperationsWorkerTimes]
    PRINT 'Vista [dbo].[BDE_85_OperationsWorkerTimes] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_85_OperationsWorkerTimes] AS
SELECT
	OPL.Operation					AS IdERPOperation,
	OPL.ResourceCode				AS IdERPTeam,
	-- IdERPWageLevel
	CASE OPL.LabourType
		WHEN 28508161	THEN 0	-- ATTREZZAGGIO
		WHEN 28508160	THEN 1	-- LAVORAZIONE
	END								AS Activity,
	CASE 
		WHEN OPL.WorkingTime != 0
		THEN OPL.WorkingTime 
		ELSE CASE OPL.LabourType
				WHEN 28508161 THEN (OP.SetupTime * OPL.AttendancePerc)/100
				WHEN 28508160 THEN (OP.ProcessingTime * OPL.AttendancePerc)/100
			END
	END								AS WorkerTime,
	(OPL.AttendancePerc/100)			AS WorkerTimeRatio,
	OPL.NoOfResources				AS WorkersNumber,
	-- Notes
	-- Revision
	OPL.TBModified					AS BMUpdate
FROM
	MA_OperationsLabour OPL
	INNER JOIN MA_Operations OP
		ON OP.Operation = OPL.Operation
WHERE
	OPL.ResourceType = 27131908 --SQUADRA
	AND OPL.Operation != ''
	AND OPL.ResourceCode != ''
GO

PRINT 'Vista [dbo].[BDE_85_OperationsWorkerTimes] creata con successo'
GO

