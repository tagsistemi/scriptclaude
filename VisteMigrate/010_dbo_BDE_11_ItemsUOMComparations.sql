-- Vista [dbo].[BDE_11_ItemsUOMComparations] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_11_ItemsUOMComparations')
BEGIN
    DROP VIEW [dbo].[BDE_11_ItemsUOMComparations]
    PRINT 'Vista [dbo].[BDE_11_ItemsUOMComparations] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_11_ItemsUOMComparations] AS
SELECT 
	IC.Item							AS IdERPItem,
	-- IdERPVariant
	IC.ComparableUoM				AS IdERPComparedUnitOfMeasure,
	IC.BaseUoMQty					AS BaseQuantity,
	IC.CompUoMQty					AS ComparedQuantity,
	--IC.BM_ItemSubstDefault			AS DefaultOnSostitution, -- assenza Bravo Agent
	--IC.BM_ItemPickingDefault		AS DefaultOnPicking,-- assenza Bravo Agent
	IC.TBModified					AS BMUpdate

FROM
	MA_ItemsComparableUoM IC 
	INNER JOIN MA_Items I
		ON IC.Item = I.Item
WHERE
	IC.Item != ''
	AND IC.ComparableUoM != ''
	AND (IC.BaseUoMQty > 0 AND IC.CompUoMQty > 0)
GO

PRINT 'Vista [dbo].[BDE_11_ItemsUOMComparations] creata con successo'
GO

