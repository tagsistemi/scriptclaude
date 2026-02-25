-- Vista [dbo].[GPX_VistaRigheRam] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'GPX_VistaRigheRam')
BEGIN
    DROP VIEW [dbo].[GPX_VistaRigheRam]
    PRINT 'Vista [dbo].[GPX_VistaRigheRam] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[GPX_VistaRigheRam]
AS
SELECT     Articolo, Commessa, SUM(Qta) AS QtaOrdine, SUM(QtaDaProd) AS QtaDaProd, SUM(QtaConsegnata) AS QtaConsegnata, MAX(PosizioneOrdine) 
                      AS Posizione, MAX(UM) AS UoMRam
FROM         dbo.gpx_righeram
GROUP BY Commessa, Articolo
GO

PRINT 'Vista [dbo].[GPX_VistaRigheRam] creata con successo'
GO

