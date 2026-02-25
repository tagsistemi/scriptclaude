-- Vista [dbo].[VistaIncidenzaCostoCentro] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VistaIncidenzaCostoCentro')
BEGIN
    DROP VIEW [dbo].[VistaIncidenzaCostoCentro]
    PRINT 'Vista [dbo].[VistaIncidenzaCostoCentro] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VistaIncidenzaCostoCentro]
AS
SELECT     TOP 100 PERCENT dbo.MA_CostAccEntries.JournalEntryId, dbo.MA_CostAccEntriesDetail.CostCenter, SUM(dbo.MA_CostAccEntries.TotalAmount) 
                      AS TotaleCosto, SUM(dbo.MA_CostAccEntriesDetail.Amount) AS TotaelCostoCentro
FROM         dbo.MA_CostAccEntries INNER JOIN
                      dbo.MA_CostAccEntriesDetail ON dbo.MA_CostAccEntries.EntryId = dbo.MA_CostAccEntriesDetail.EntryId
GROUP BY dbo.MA_CostAccEntries.JournalEntryId, dbo.MA_CostAccEntriesDetail.CostCenter
ORDER BY dbo.MA_CostAccEntries.JournalEntryId, dbo.MA_CostAccEntriesDetail.CostCenter
GO

PRINT 'Vista [dbo].[VistaIncidenzaCostoCentro] creata con successo'
GO

