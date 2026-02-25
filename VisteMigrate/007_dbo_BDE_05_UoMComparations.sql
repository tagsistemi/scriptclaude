-- Vista [dbo].[BDE_05_UoMComparations] - Aggiornamento
-- Generato: 2026-02-23 21:30:32

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_05_UoMComparations')
BEGIN
    DROP VIEW [dbo].[BDE_05_UoMComparations]
    PRINT 'Vista [dbo].[BDE_05_UoMComparations] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_05_UoMComparations] AS
SELECT
	BaseUoM			AS IdERPUnitOfMeasureBase,
	ComparableUoM	AS IdERPUnitOfMeasureCompared,
	BaseUoMQty		AS BaseQuantity,
	CompUoMQty		AS ComparedQuantity,
	TBCreated		AS TBCreated,
	TBModified		AS BMUpdate
FROM
	MA_UnitOfMeasureDetail
WHERE
	BaseUoM != '' AND ComparableUoM != ''
GO

PRINT 'Vista [dbo].[BDE_05_UoMComparations] creata con successo'
GO

