-- Vista [dbo].[BDE_10_Items_old] - Aggiornamento
-- Generato: 2026-02-23 21:30:32

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_10_Items_old')
BEGIN
    DROP VIEW [dbo].[BDE_10_Items_old]
    PRINT 'Vista [dbo].[BDE_10_Items_old] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_10_Items_old] AS
SELECT 
	I.Item													AS IdERP, 
	I.Description											AS Name,
	I.Description											AS Description,
	
	2 /* Qtà proporzionale*/								AS PropositionTypeFinalBalance,
	CASE Nature
		WHEN 22413314 Then 0	-- Acquisto
		WHEN 22413313 Then 2	-- Semilavorato
		WHEN 22413312 Then 1	-- Prodotto Finito
	END														AS Nature,
	I.BaseUoM												AS IdERPUnitOfMeasure, 
	-- IdERPItemMacroCategory --> I.ItemType
	-- IdERPItemCategory --> I.CommodityCtg
	-- IdERPItemSubCategory  --> I.HomogeneousCtg
	IGD.NetWeight											AS NetWeight,
	IGD.GrossWeight											AS GrossWeight,
	I.Picture												AS Image,
	CONVERT(Integer, I.Disabled)							AS DisableItem,
	--  IdVariant
	CONVERT(Integer, IGD.UseLots)							AS UseStocks, 
	IMD.ProductionLot										AS ProductionLot,
	-- RoundExcess
	-- EnableComparedUnitsOfMeasure
	-- SecondRateMaxTolerance
	-- ScrapMaxTolerance
	-- CommitmentType
	-- OverproductionMode
	I.TBModified											AS BMUpdate
FROM
	MA_Items I
	left join MA_ItemsGoodsData IGD
		ON I.ITEM = IGD.Item
	left join MA_ItemsManufacturingData IMD
		on IMD.Item = I.Item
WHERE
	I.Item != ''
GO

PRINT 'Vista [dbo].[BDE_10_Items_old] creata con successo'
GO

