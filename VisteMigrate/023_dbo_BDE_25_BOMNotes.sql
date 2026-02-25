-- Vista [dbo].[BDE_25_BOMNotes] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_25_BOMNotes')
BEGIN
    DROP VIEW [dbo].[BDE_25_BOMNotes]
    PRINT 'Vista [dbo].[BDE_25_BOMNotes] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_25_BOMNotes] AS
SELECT
	BMC.BOM							AS IdERPBOM,
	'0'								AS Revision,
	CAST( BMC.SubId AS Varchar(50))	AS Title,
	BMC.Description					AS Description,
	BMC.TBModified					AS BMUpdate
FROM
	MA_BillOfMaterialsComp BMC
	INNER JOIN MA_BillOfMaterials BOM
		ON BMC.BOM = BOM.BOM
	INNER JOIN MA_Items ITM
		ON ITM.Item = BMC.Component
WHERE
	BOM.CodeType = 7798784	-- le distinte fantasma non vengono gestite in Bravo Manufacturing, quindi non verranno importate
	AND BMC.ComponentType = 7798789 -- Righe di tipo "Nota"
	AND BOM.BOM IN 
					(
							SELECT 
								BMR.BOM 	
							FROM 
								MA_BillOfMaterialsRouting BMR
								INNER JOIN BM_ConsoleWC CWC 
									ON BMR.WC = CWC.WorkCenter
							--WHERE CWC.Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							)
GO

PRINT 'Vista [dbo].[BDE_25_BOMNotes] creata con successo'
GO

