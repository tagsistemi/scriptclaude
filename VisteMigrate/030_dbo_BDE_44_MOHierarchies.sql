-- Vista [dbo].[BDE_44_MOHierarchies] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_44_MOHierarchies')
BEGIN
    DROP VIEW [dbo].[BDE_44_MOHierarchies]
    PRINT 'Vista [dbo].[BDE_44_MOHierarchies] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_44_MOHierarchies] AS
SELECT
	MOParent.MONo			AS ParentMONumber,
	MOChild.MONo			AS ChildMONumber,
	MOH.TBModified			AS BMUpdate
FROM
	MA_MOHierarchies MOH
	INNER JOIN MA_MO MOParent
		ON MOH.ParentMOId = MOParent.MOId
	INNER JOIN MA_MO MOChild
		ON MOH.ChildMOId = MOChild.MOId
WHERE
	MOParent.MOStatus IN
	(
		20578304,	-- LANCIATO
		20578305,	-- IN LAVORAZIONE
		20578306	-- TERMINATO
	)
	AND MOChild.MOStatus IN
	(
		20578304,	-- LANCIATO
		20578305,	-- IN LAVORAZIONE
		20578306	-- TERMINATO
	)
	AND MOParent.MONo != '' AND MOParent.MOId IS NOT NULL
	AND MOChild.MONo != '' AND MOChild.MOId IS NOT NULL
	AND
	(
		MOH.ChildMOId IN 
					(
							SELECT 
								MOS.MOId 	
							FROM 
								MA_MOSteps MOS
								INNER JOIN BM_ConsoleWC CWC 
									ON MOS.WC = CWC.WorkCenter
							-- WHERE CWC.Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)
		OR MOH.ParentMOId IN 
					(
							SELECT 
								MOS.MOId 	
							FROM 
								MA_MOSteps MOS
								INNER JOIN BM_ConsoleWC CWC 
									ON MOS.WC = CWC.WorkCenter
							-- WHERE CWC.Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)

		)
GO

PRINT 'Vista [dbo].[BDE_44_MOHierarchies] creata con successo'
GO

