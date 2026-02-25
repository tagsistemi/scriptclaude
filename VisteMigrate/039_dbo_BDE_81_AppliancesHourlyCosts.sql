-- Vista [dbo].[BDE_81_AppliancesHourlyCosts] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_81_AppliancesHourlyCosts')
BEGIN
    DROP VIEW [dbo].[BDE_81_AppliancesHourlyCosts]
    PRINT 'Vista [dbo].[BDE_81_AppliancesHourlyCosts] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_81_AppliancesHourlyCosts] AS
SELECT 
	C.BravoID						AS IdERPAppliance,
	COST.ValidFrom					AS ValidityDate,
	COST.HourlyCost					AS HourlyCost,
	COST.AdditionalCost				AS AdditionalCost,
	COST.TBModified					AS BMUpdate
FROM
	BM_ConsoleWC C
	INNER JOIN MA_WorkCenters WC
		ON C.WorkCenter = WC.WC
	INNER JOIN BM_WCCostHistorical COST
		ON COST.WC = C.WorkCenter
WHERE
	C.BravoID != ''
	AND COST.HourlyCost >= 0
	--AND C.Console = ''	-- INDICARE IL CODICE DELLA CONSOLE NEL CASO DI UTILIZZINO PIU' CONSOLE
GO

PRINT 'Vista [dbo].[BDE_81_AppliancesHourlyCosts] creata con successo'
GO

