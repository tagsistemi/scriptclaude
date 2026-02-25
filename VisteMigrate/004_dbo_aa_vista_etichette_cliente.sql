-- Vista [dbo].[aa_vista_etichette_cliente] - Aggiornamento
-- Generato: 2026-02-23 21:30:32

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'aa_vista_etichette_cliente')
BEGIN
    DROP VIEW [dbo].[aa_vista_etichette_cliente]
    PRINT 'Vista [dbo].[aa_vista_etichette_cliente] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[aa_vista_etichette_cliente]
AS
SELECT     TOP (100) PERCENT dbo.MA_CustSupp.CustSuppType, dbo.MA_CustSupp.CustSupp, dbo.MA_CustSupp.CompanyName, dbo.MA_Items.Item, 
                      dbo.MA_Items.BaseUoM, dbo.MA_Items.CommodityCtg, dbo.MA_Items.PublicNote, dbo.MA_ItemCustomers.CustomerCode, 
                      dbo.MA_ItemCustomers.CustomerDescription, dbo.MA_ItemCustomers.StandardPrice, dbo.MA_Items.OldItem, dbo.MA_Items.Description, 
                      dbo.MA_Items.SaleBarCode, dbo.MA_Items.BasePrice, dbo.MA_ItemCustomers.Customer, dbo.MA_Items.CommissionCtg
FROM         dbo.MA_Items INNER JOIN
                      dbo.MA_ItemCustomers ON dbo.MA_Items.Item = dbo.MA_ItemCustomers.Item INNER JOIN
                      dbo.MA_CustSupp ON dbo.MA_ItemCustomers.Customer = dbo.MA_CustSupp.CustSupp
ORDER BY dbo.MA_Items.Item, dbo.MA_CustSupp.CustSupp
GO

PRINT 'Vista [dbo].[aa_vista_etichette_cliente] creata con successo'
GO

