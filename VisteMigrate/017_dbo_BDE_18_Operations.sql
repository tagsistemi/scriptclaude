-- Vista [dbo].[BDE_18_Operations] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_18_Operations')
BEGIN
    DROP VIEW [dbo].[BDE_18_Operations]
    PRINT 'Vista [dbo].[BDE_18_Operations] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_18_Operations] AS
SELECT
	Operation					AS IdERP,
	Description					AS Name,
	Description					AS Description,
	WC							AS IdERPAppliance,
	QueueTime					AS QueueTime,
	SetupTime					AS SetupTime,
	ProcessingTime				AS ProcessTime,
	-- WorkerSetupTime
	-- WorkerProcessTime
	TBModified					AS BMUpdate
FROM
	MA_Operations
WHERE
	Operation != ''
GO

PRINT 'Vista [dbo].[BDE_18_Operations] creata con successo'
GO

