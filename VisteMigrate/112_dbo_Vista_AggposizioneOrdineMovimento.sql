-- Vista [dbo].[Vista_AggposizioneOrdineMovimento] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_AggposizioneOrdineMovimento')
BEGIN
    DROP VIEW [dbo].[Vista_AggposizioneOrdineMovimento]
    PRINT 'Vista [dbo].[Vista_AggposizioneOrdineMovimento] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_AggposizioneOrdineMovimento]
AS
SELECT     dbo.MA_InventoryEntriesDetail.Item, dbo.MA_SaleOrdDetails.Job, dbo.MA_SaleOrdDetails.Position, dbo.MA_InventoryEntriesDetail.OrderLine, 
                      dbo.MA_SaleOrdDetails.SaleOrdId, dbo.MA_InventoryEntriesDetail.OrderId
FROM         dbo.MA_SaleOrdDetails INNER JOIN
                      dbo.MA_InventoryEntriesDetail ON dbo.MA_SaleOrdDetails.Item = dbo.MA_InventoryEntriesDetail.Item AND 
                      dbo.MA_SaleOrdDetails.Job = dbo.MA_InventoryEntriesDetail.Job
GO

PRINT 'Vista [dbo].[Vista_AggposizioneOrdineMovimento] creata con successo'
GO

