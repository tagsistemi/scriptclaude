-- Vista [dbo].[VistaVendite] - Creazione
-- Generato: 2026-02-23 21:30:43

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[VistaVendite] AS SELECT     MA_SaleDocDetail.Item, MA_SaleDocDetail.DocumentDate, MA_SaleDocDetail.DocumentType, MA_Items.CommodityCtg, MA_Items.HomogeneousCtg, MA_Items.CommissionCtg,                        MA_SaleDocDetail.TaxableAmount FROM         MA_SaleDocDetail INNER JOIN                       MA_Items ON MA_SaleDocDetail.Item = MA_Items.Item WHERE     (MA_SaleDocDetail.DocumentType = 3407873)
GO

PRINT 'Vista [dbo].[VistaVendite] creata con successo'
GO

