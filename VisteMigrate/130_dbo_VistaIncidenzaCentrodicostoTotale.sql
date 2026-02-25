-- Vista [dbo].[VistaIncidenzaCentrodicostoTotale] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VistaIncidenzaCentrodicostoTotale')
BEGIN
    DROP VIEW [dbo].[VistaIncidenzaCentrodicostoTotale]
    PRINT 'Vista [dbo].[VistaIncidenzaCentrodicostoTotale] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VistaIncidenzaCentrodicostoTotale]
AS
SELECT     dbo.VistaIncidenzaCostoCentro.JournalEntryId, dbo.VistaIncidenzaCostoCentro.TotaleCosto, dbo.VistaIncidenzaCostoCentro.TotaelCostoCentro, 
                      dbo.VistaIncidenzaCostoCentro.CostCenter, dbo.VistaCostiTotaleAnalitici.TotaleCosto AS TotaleCostoPrimaNotaAnalitica, 
                      dbo.VistaIncidenzaCostoCentro.TotaelCostoCentro / dbo.VistaCostiTotaleAnalitici.TotaleCosto * 100 AS incidenza
FROM         dbo.VistaIncidenzaCostoCentro INNER JOIN
                      dbo.VistaCostiTotaleAnalitici ON dbo.VistaIncidenzaCostoCentro.JournalEntryId = dbo.VistaCostiTotaleAnalitici.JournalEntryId
GO

PRINT 'Vista [dbo].[VistaIncidenzaCentrodicostoTotale] creata con successo'
GO

