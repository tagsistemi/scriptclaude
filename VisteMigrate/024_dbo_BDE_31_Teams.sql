-- Vista [dbo].[BDE_31_Teams] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_31_Teams')
BEGIN
    DROP VIEW [dbo].[BDE_31_Teams]
    PRINT 'Vista [dbo].[BDE_31_Teams] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_31_Teams] AS
SELECT
	ResourceCode				AS IdERP,
	Description					AS Name,
	Description					AS Description,
	-- IdERPWageLevel
	TBModified					AS BMUpdate
FROM
	MA_CompanyResources
WHERE
	ResourceType = 27131908 -- SQUADRA
	AND ResourceCode != ''
GO

PRINT 'Vista [dbo].[BDE_31_Teams] creata con successo'
GO

