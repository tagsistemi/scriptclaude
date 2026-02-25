-- Vista [dbo].[Vista_controlloddt_fattura] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_controlloddt_fattura')
BEGIN
    DROP VIEW [dbo].[Vista_controlloddt_fattura]
    PRINT 'Vista [dbo].[Vista_controlloddt_fattura] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_controlloddt_fattura]
AS
SELECT     dbo.Vista_Bolle.Item, dbo.Vista_Bolle.Job, dbo.Vista_Bolle.UnitValue AS valoreunitariobolla, dbo.Vista_Fatture.UnitValue AS valoreunitariofattura, 
                      dbo.Vista_Bolle.TaxableAmount AS imponibilebolla, dbo.Vista_Fatture.TaxableAmount AS imponibilefattura, dbo.Vista_Bolle.DocNo AS nrbolla, 
                      dbo.Vista_Bolle.DocumentDate AS databolla, dbo.Vista_Fatture.DocNo AS nrfattura, dbo.Vista_Fatture.DocumentDate AS datafattura
FROM         dbo.Vista_Bolle INNER JOIN
                      dbo.Vista_Fatture ON dbo.Vista_Bolle.Item = dbo.Vista_Fatture.Item AND dbo.Vista_Bolle.Job = dbo.Vista_Fatture.Job
GO

PRINT 'Vista [dbo].[Vista_controlloddt_fattura] creata con successo'
GO

