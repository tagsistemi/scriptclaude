-- Vista [dbo].[BDE_04_UoM] - Aggiornamento
-- Generato: 2026-02-23 21:30:32

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_04_UoM')
BEGIN
    DROP VIEW [dbo].[BDE_04_UoM]
    PRINT 'Vista [dbo].[BDE_04_UoM] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_04_UoM] AS
SELECT
	UPPER(BaseUoM)	AS IdERP,
	UPPER(Symbol)	AS Symbol,
	Description		AS Name,
	Notes			AS Notes,
	TBCreated		AS TBCreated,
	TBModified		AS BMUpdate
FROM
	MA_UnitsOfMeasure
WHERE
	BaseUoM != ''
GO

PRINT 'Vista [dbo].[BDE_04_UoM] creata con successo'
GO

