-- Vista [dbo].[VIEW_OIKOS_CONTIPERFORNITORE2] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VIEW_OIKOS_CONTIPERFORNITORE2')
BEGIN
    DROP VIEW [dbo].[VIEW_OIKOS_CONTIPERFORNITORE2]
    PRINT 'Vista [dbo].[VIEW_OIKOS_CONTIPERFORNITORE2] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VIEW_OIKOS_CONTIPERFORNITORE2]
AS
SELECT     dbo.VIEW_OIKOS_CONTIPERFORNITORE_1.JournalEntryId, dbo.VIEW_OIKOS_CONTIPERFORNITORE_1.CustSupp, 
                      dbo.MA_JournalEntriesGLDetail.AccRsn, dbo.MA_JournalEntriesGLDetail.PostingDate, dbo.MA_JournalEntriesGLDetail.Account, 
                      dbo.MA_JournalEntriesGLDetail.DebitCreditSign, dbo.MA_JournalEntriesGLDetail.Amount
FROM         dbo.VIEW_OIKOS_CONTIPERFORNITORE_1 INNER JOIN
                      dbo.MA_JournalEntriesGLDetail ON 
                      dbo.VIEW_OIKOS_CONTIPERFORNITORE_1.JournalEntryId = dbo.MA_JournalEntriesGLDetail.JournalEntryId
WHERE     (dbo.MA_JournalEntriesGLDetail.AccRsn = 'FTRIC') OR
                      (dbo.MA_JournalEntriesGLDetail.AccRsn = 'NCRIC')
GO

PRINT 'Vista [dbo].[VIEW_OIKOS_CONTIPERFORNITORE2] creata con successo'
GO

