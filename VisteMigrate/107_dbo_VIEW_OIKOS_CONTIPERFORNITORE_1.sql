-- Vista [dbo].[VIEW_OIKOS_CONTIPERFORNITORE_1] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VIEW_OIKOS_CONTIPERFORNITORE_1')
BEGIN
    DROP VIEW [dbo].[VIEW_OIKOS_CONTIPERFORNITORE_1]
    PRINT 'Vista [dbo].[VIEW_OIKOS_CONTIPERFORNITORE_1] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VIEW_OIKOS_CONTIPERFORNITORE_1]
AS
SELECT     JournalEntryId, CustSuppType, CustSupp
FROM         dbo.MA_JournalEntriesGLDetail
WHERE     (CustSuppType = 3211265) AND (CustSupp <> '')
GO

PRINT 'Vista [dbo].[VIEW_OIKOS_CONTIPERFORNITORE_1] creata con successo'
GO

