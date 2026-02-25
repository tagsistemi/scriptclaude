-- Vista [dbo].[Vista_BaseUpdatePosOrdine] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_BaseUpdatePosOrdine')
BEGIN
    DROP VIEW [dbo].[Vista_BaseUpdatePosOrdine]
    PRINT 'Vista [dbo].[Vista_BaseUpdatePosOrdine] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_BaseUpdatePosOrdine]
AS
SELECT     dbo.MA_SaleOrdDetails.Item, dbo.MA_InventoryEntriesDetail.OrderLine, dbo.MA_SaleOrdDetails.Position, dbo.MA_SaleOrdDetails.Job, 
                      dbo.MA_SaleOrdDetails.SaleOrdId
FROM         dbo.MA_SaleOrdDetails INNER JOIN
                      dbo.MA_InventoryEntriesDetail ON dbo.MA_SaleOrdDetails.Item = dbo.MA_InventoryEntriesDetail.Item AND 
                      dbo.MA_SaleOrdDetails.Job = dbo.MA_InventoryEntriesDetail.Job
GO

PRINT 'Vista [dbo].[Vista_BaseUpdatePosOrdine] creata con successo'
GO

