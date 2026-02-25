-- Vista [dbo].[BDE_12_ItemsCosts] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_12_ItemsCosts')
BEGIN
    DROP VIEW [dbo].[BDE_12_ItemsCosts]
    PRINT 'Vista [dbo].[BDE_12_ItemsCosts] eliminata'
END
GO

-- Ricreazione vista
--CREATE OR ALTER VIEW BDE_12_ItemsCosts AS
CREATE  VIEW [dbo].[BDE_12_ItemsCosts] AS
SELECT

			Item						AS IdERPItem,
			'-'							AS Storage,
			1							AS FiscalPeriod,

			InitialBookInv				AS InitialBookInv,
			InitialBookInvValue			AS InitialBookInvValue,
			BookInvValue				AS BookInvValue,
			PurchasesQty				AS PurchasesQty,
			PurchasesValue				AS PurchasesValue,
			ProducedQty					AS ProducedQty,
			ProducedValue				AS ProducedValue,
			TBModified				AS TBModified,	

	CONVERT( DATE, TBModified)	/*SOLODATA*/	AS CostDate,
	COALESCE(LastCost,0)				AS LastCost,
	COALESCE(StandardCost, 0)			AS StandardCost,
	CASE
		WHEN (InitialBookInv+PurchasesQty+ProducedQty) != 0
		THEN CASE WHEN (InitialBookInvValue+PurchasesValue+ProducedValue)/(InitialBookInv+PurchasesQty+ProducedQty) >= 0
			THEN (InitialBookInvValue+PurchasesValue+ProducedValue)/(InitialBookInv+PurchasesQty+ProducedQty)
			ELSE 0
			END
		ELSE 0
	END								AS AverageCost,
	TBModified					AS BMUpdate




FROM
	MA_ItemsFiscalData
WHERE
	FISCALYEAR = YEAR(GETDATE()) and Item!=''
GO

PRINT 'Vista [dbo].[BDE_12_ItemsCosts] creata con successo'
GO

