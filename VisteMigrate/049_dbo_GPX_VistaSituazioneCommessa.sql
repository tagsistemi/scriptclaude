-- Vista [dbo].[GPX_VistaSituazioneCommessa] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'GPX_VistaSituazioneCommessa')
BEGIN
    DROP VIEW [dbo].[GPX_VistaSituazioneCommessa]
    PRINT 'Vista [dbo].[GPX_VistaSituazioneCommessa] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[GPX_VistaSituazioneCommessa]
AS
SELECT     dbo.MA_SaleOrdDetails.Job, dbo.MA_SaleOrdDetails.Item, dbo.MA_SaleOrdDetails.Qty AS QtaOrdinataDaCliente, 
                      dbo.GPX_VistaRigheOrdiniFor.qtaordinata AS QtaOrdinataAFornitore, dbo.GPX_VistaRigheOrdiniFor.qtaconsegnataof AS QtaConsegnataDaiFornitori, 
                      dbo.GPX_VistaRigheRam.QtaOrdine AS QtaOrdinataRigaRam, dbo.GPX_VistaRigheRam.QtaDaProd AS QtaDaProdurreRigaRam, 
                      dbo.GPX_VistaRigheRam.QtaConsegnata AS QtaConsegnataAClienteRigaRam, dbo.MA_SaleOrdDetails.Description, 
                      dbo.MA_SaleOrdDetails.UoM AS UoMOrdineCli, dbo.GPX_VistaRigheOrdiniFor.UoMOrdineFor, dbo.GPX_VistaRigheRam.UoMRam, 
                      dbo.MA_SaleOrd.StoragePhase1 AS DepositoOrdine, dbo.MA_SaleOrdDetails.[Position] AS Pos_Ordine
FROM         dbo.MA_SaleOrdDetails INNER JOIN
                      dbo.MA_SaleOrd ON dbo.MA_SaleOrdDetails.SaleOrdId = dbo.MA_SaleOrd.SaleOrdId LEFT OUTER JOIN
                      dbo.GPX_VistaRigheRam ON dbo.MA_SaleOrdDetails.Item = dbo.GPX_VistaRigheRam.Articolo AND 
                      dbo.MA_SaleOrdDetails.Job = dbo.GPX_VistaRigheRam.Commessa LEFT OUTER JOIN
                      dbo.GPX_VistaRigheOrdiniFor ON dbo.MA_SaleOrdDetails.Job = dbo.GPX_VistaRigheOrdiniFor.Job AND 
                      dbo.MA_SaleOrdDetails.Item = dbo.GPX_VistaRigheOrdiniFor.Item
GO

PRINT 'Vista [dbo].[GPX_VistaSituazioneCommessa] creata con successo'
GO

