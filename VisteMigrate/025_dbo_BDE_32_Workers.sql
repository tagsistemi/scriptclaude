-- Vista [dbo].[BDE_32_Workers] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_32_Workers')
BEGIN
    DROP VIEW [dbo].[BDE_32_Workers]
    PRINT 'Vista [dbo].[BDE_32_Workers] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_32_Workers] AS
SELECT
	RIGHT('000'+convert(VARCHAR(10),WRK.WorkerID),4)			AS IdERP,
	WRK.WorkerID												AS IdExternalCode,
	CASE WHEN WRK.Name = ''		THEN '.' ELSE WRK.Name		END AS Name,
	CASE WHEN WRK.LastName = '' THEN '.' ELSE WRK.LastName	END AS Surname,
	-- IdERPTeam (non indicato perché Mago prevede che una matricola possa essere associata a più squadre)
	-- IdERPWageLevel
	COALESCE(Titles.Description, '')	AS WorkTitle,
	CASE WHEN WRK.EmploymentDate	<> ('17991231') THEN WRK.EmploymentDate		ELSE ('17530101') END		AS HiringDate,
	CASE WHEN WRK.ResignationDate	<> ('17991231') THEN WRK.ResignationDate	ELSE ('17530101') END 		AS DischargingDate,
	WRK.ImagePath						AS Photo,
	-- ParallelizationMode
	-- DefaultIdERPShift
	WRK.TBModified						AS BMUpdate
FROM
	BM_ConsoleWorkers C
	INNER JOIN MA_Workers WRK
		ON C.MagoWorkerID = WRK.WorkerID
	LEFT OUTER JOIN MA_Titles Titles
		ON WRK.Title = Titles.TitleCode
WHERE
	C.BravoWorkerId != ''
	--AND C.Console = ''	-- COMPILARE IL CODICE CONSOLE (NEL CASO VENGANO GESTITE PIU' CONSOLE)
GO

PRINT 'Vista [dbo].[BDE_32_Workers] creata con successo'
GO

