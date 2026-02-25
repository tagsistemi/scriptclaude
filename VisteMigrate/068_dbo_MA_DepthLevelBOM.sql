-- Vista [dbo].[MA_DepthLevelBOM] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_DepthLevelBOM')
BEGIN
    DROP VIEW [dbo].[MA_DepthLevelBOM]
    PRINT 'Vista [dbo].[MA_DepthLevelBOM] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_DepthLevelBOM] AS SELECT * FROM FN_DepthLevelBOM()
GO

PRINT 'Vista [dbo].[MA_DepthLevelBOM] creata con successo'
GO

