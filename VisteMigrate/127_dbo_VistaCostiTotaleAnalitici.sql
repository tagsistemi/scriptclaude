-- Vista [dbo].[VistaCostiTotaleAnalitici] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VistaCostiTotaleAnalitici')
BEGIN
    DROP VIEW [dbo].[VistaCostiTotaleAnalitici]
    PRINT 'Vista [dbo].[VistaCostiTotaleAnalitici] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VistaCostiTotaleAnalitici]
AS
SELECT     JournalEntryId, SUM(TotalAmount) AS TotaleCosto
FROM         dbo.MA_CostAccEntries
GROUP BY JournalEntryId
GO

PRINT 'Vista [dbo].[VistaCostiTotaleAnalitici] creata con successo'
GO

