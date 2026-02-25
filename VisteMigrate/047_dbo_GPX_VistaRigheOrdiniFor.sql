-- Vista [dbo].[GPX_VistaRigheOrdiniFor] - Aggiornamento
-- Generato: 2026-02-23 21:30:35

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'GPX_VistaRigheOrdiniFor')
BEGIN
    DROP VIEW [dbo].[GPX_VistaRigheOrdiniFor]
    PRINT 'Vista [dbo].[GPX_VistaRigheOrdiniFor] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[GPX_VistaRigheOrdiniFor]
AS
SELECT     Item, Job, SUM(Qty) AS qtaordinata, SUM(DeliveredQty) AS qtaconsegnataof, MAX(Description) AS DescrizioneOrdFor, MAX(UoM) 
                      AS UoMOrdineFor
FROM         dbo.MA_PurchaseOrdDetails
GROUP BY Item, Job
GO

PRINT 'Vista [dbo].[GPX_VistaRigheOrdiniFor] creata con successo'
GO

