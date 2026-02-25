-- Vista [dbo].[Lottiw] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Lottiw')
BEGIN
    DROP VIEW [dbo].[Lottiw]
    PRINT 'Vista [dbo].[Lottiw] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Lottiw]
AS
SELECT     dbo.MA_Items.Description, dbo.MA_Items.Item, dbo.MA_Lots.Lot, dbo.MA_Lots.ReceiptInvTransId, dbo.MA_Lots.FinalBookInv, dbo.MA_Lots.IssuedQty, 
                      dbo.MA_Lots.IssuedValue, LEFT(dbo.MA_Lots.Lot, 5) AS Commessa, dbo.MA_Lots.TotallyConsumed, dbo.MA_Lots.InitialBookInv, 
                      dbo.MA_Lots.ReceivedValue, dbo.MA_Lots.ReceivedQty, dbo.MA_Lots.Cost, dbo.MA_Lots.LoadDate, dbo.MA_Items.CommodityCtg, 
                      dbo.MA_Items.HomogeneousCtg, dbo.MA_Items.ItemType, dbo.MA_Items.CommissionCtg
FROM         dbo.MA_Items INNER JOIN
                      dbo.MA_Lots ON dbo.MA_Items.Item = dbo.MA_Lots.Item
GO

PRINT 'Vista [dbo].[Lottiw] creata con successo'
GO

