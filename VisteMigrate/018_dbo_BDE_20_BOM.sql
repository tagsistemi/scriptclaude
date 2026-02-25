-- Vista [dbo].[BDE_20_BOM] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_20_BOM')
BEGIN
    DROP VIEW [dbo].[BDE_20_BOM]
    PRINT 'Vista [dbo].[BDE_20_BOM] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_20_BOM] AS
SELECT
	BOM							AS IdERP,
	BOM							AS Name,
	Description					AS Description,
	BOM							AS IdItemERP,
	Disabled					AS Disabled,
	UPPER(UoM)					AS IdERPUnitOfMeasure,
	InProduction				AS Status,
	CreationDate				AS CreationDate,
	TBModified					AS Lastupdate,
	'0'							AS Revision,
	TBModified					AS BMUpdate
FROM
	MA_BillOfMaterials BOM

WHERE
	BOM.CodeType = 7798784	-- le distinte fantasma non vengono gestite in Bravo Manufacturing, quindi non verranno importate
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

PRINT 'Vista [dbo].[BDE_20_BOM] creata con successo'
GO

