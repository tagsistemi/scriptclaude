-- Vista [dbo].[BDE_76_ItemsPhotos] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_76_ItemsPhotos')
BEGIN
    DROP VIEW [dbo].[BDE_76_ItemsPhotos]
    PRINT 'Vista [dbo].[BDE_76_ItemsPhotos] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_76_ItemsPhotos]
AS
SELECT 
	Item							AS IdERPItem,
	Picture							AS ImagePath,
	Description						AS Name,
	Description						AS Description,
	1								AS DefaultPhoto,
	1								AS PublicPhoto,
	-- IdVarianti
	TBModified						AS BMUpdate
FROM
	MA_Items
WHERE
	Item != ''
	AND Picture != ''
GO

PRINT 'Vista [dbo].[BDE_76_ItemsPhotos] creata con successo'
GO

