-- Vista [dbo].[VistaQtaConsegnatePerCommessaPosizione] - Aggiornamento
-- Generato: 2026-02-23 21:30:43

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VistaQtaConsegnatePerCommessaPosizione')
BEGIN
    DROP VIEW [dbo].[VistaQtaConsegnatePerCommessaPosizione]
    PRINT 'Vista [dbo].[VistaQtaConsegnatePerCommessaPosizione] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VistaQtaConsegnatePerCommessaPosizione] AS SELECT     Job, SaleOrdNo, SaleOrdPos, DocumentType, SUM(Qty) AS Qta FROM         MA_SaleDocDetail GROUP BY Job, SaleOrdNo, SaleOrdPos, DocumentType
GO

PRINT 'Vista [dbo].[VistaQtaConsegnatePerCommessaPosizione] creata con successo'
GO

