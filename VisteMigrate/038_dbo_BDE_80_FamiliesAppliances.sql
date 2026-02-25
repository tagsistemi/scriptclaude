-- Vista [dbo].[BDE_80_FamiliesAppliances] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_80_FamiliesAppliances')
BEGIN
    DROP VIEW [dbo].[BDE_80_FamiliesAppliances]
    PRINT 'Vista [dbo].[BDE_80_FamiliesAppliances] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_80_FamiliesAppliances] AS
SELECT 
	WCFamily						AS IdERP,
	Description						AS Name,
	Description						AS Description,
	TBModified						AS BMUpdate
FROM
	MA_WCFamilies
WHERE
	WCFamily != ''
GO

PRINT 'Vista [dbo].[BDE_80_FamiliesAppliances] creata con successo'
GO

