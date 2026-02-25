-- Vista [dbo].[MA_ProductionDevelopment] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_ProductionDevelopment')
BEGIN
    DROP VIEW [dbo].[MA_ProductionDevelopment]
    PRINT 'Vista [dbo].[MA_ProductionDevelopment] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_ProductionDevelopment] AS  SELECT 
	MA_TmpProducibilityAnalysis.Computer				AS Computer, 
	MA_TmpProducibilityAnalysis.UserName					AS UserName, 
	MA_TmpProducibilityAnalysis.Component				AS Component, 
	MA_TmpProducibilityAnalysis.UoM						AS UoM, 
	MA_TmpProducibilityAnalysis.Variant				AS Variant,  
	SUM (MA_TmpProducibilityAnalysis.NeededQty)	AS NeededQty 
	FROM MA_TmpProducibilityAnalysis 
	GROUP BY 
	MA_TmpProducibilityAnalysis.Computer, 
	MA_TmpProducibilityAnalysis.UserName, 
	MA_TmpProducibilityAnalysis.Component, 
	MA_TmpProducibilityAnalysis.Variant, 
	MA_TmpProducibilityAnalysis.UoM
GO

PRINT 'Vista [dbo].[MA_ProductionDevelopment] creata con successo'
GO

