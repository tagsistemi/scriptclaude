-- Vista [dbo].[BDE_13_ItemsLots] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_13_ItemsLots')
BEGIN
    DROP VIEW [dbo].[BDE_13_ItemsLots]
    PRINT 'Vista [dbo].[BDE_13_ItemsLots] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_13_ItemsLots]
AS
SELECT 
	Lot								AS InternalNumber,
	Item							AS IdERPItem,
	Supplier						AS IdERPSupplier,
	SupplierLotNo					AS SupplierStockNumber,
	ValidFrom						AS ArrivalDate,
	CASE 
		WHEN ValidTo = '1799/12/31'
		THEN '1753/01/01'
		ELSE ValidTo
	END
										AS ExpireDate,
	Notes							AS Notes,
	Location						AS Location,
	Disabled						AS DisableStock,
	TBModified						AS BMUpdate
FROM
	MA_Lots
WHERE
	Lot != ''
	AND Item != ''
	and ValidFrom > ValidTo
GO

PRINT 'Vista [dbo].[BDE_13_ItemsLots] creata con successo'
GO

