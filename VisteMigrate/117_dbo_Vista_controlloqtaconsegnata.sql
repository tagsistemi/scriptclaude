-- Vista [dbo].[Vista_controlloqtaconsegnata] - Aggiornamento
-- Generato: 2026-02-23 21:30:41

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_controlloqtaconsegnata')
BEGIN
    DROP VIEW [dbo].[Vista_controlloqtaconsegnata]
    PRINT 'Vista [dbo].[Vista_controlloqtaconsegnata] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_controlloqtaconsegnata]
AS
SELECT     Item, Description, TaxCode, BaseUoM, CommodityCtg, Qty, DeliveredQty, Delivered, Job, SaleBarCode, DescriCategoria, ExpectedDeliveryDate, 
                      imponibileunitario, TaxableAmount, saldoqta, Customer, CompanyName, CustSuppType, Address, ZIPCode, City, County, ExternalOrdNo, Department, 
                      Position, StoragePhase1, QtaCons
FROM         dbo.Vistaordinidaevadere
WHERE     (DeliveredQty <> QtaCons)
GO

PRINT 'Vista [dbo].[Vista_controlloqtaconsegnata] creata con successo'
GO

