-- Vista [dbo].[MA_SalesStatistics] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_SalesStatistics')
BEGIN
    DROP VIEW [dbo].[MA_SalesStatistics]
    PRINT 'Vista [dbo].[MA_SalesStatistics] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_SalesStatistics] AS  SELECT Top 100 percent 
	MA_CustSupp.CustSupp, 
	MA_CustSupp.CustSuppType, 
	MA_CustSupp.CompanyName, 
	MA_CustSupp.Account, 
	MA_CustSupp.City, 
	MA_CustSupp.County, 
	MA_CustSupp.ISOCountryCode, 
	MA_CustSupp.PriceList, 
	MA_CustSupp.Disabled, 
	MA_CustSupp.Payment, 
	MA_CustSupp.ExternalCode, 
	MA_CustSuppCustomerOptions.Category, 
	MA_CustSuppCustomerOptions.Area, 
	MA_CustSuppCustomerOptions.Salesperson, 
	MA_SaleDocSummary.TaxableAmount, 
	MA_SaleDocSummary.GoodsAmount, 
	MA_SaleDocSummary.ServiceAmounts, 
	MA_SaleDocSummary.DiscountOnGoods, 
	MA_SaleDocSummary.DiscountOnServices, 
	MA_SaleDocSummary.FreeSamples, 
	MA_SaleDocSummary.Discounts, 
	MA_SaleDocSummary.Allowances, 
	MA_SaleDocSummary.PackagingCharges, 
	MA_SaleDocSummary.ShippingCharges, 
	MA_SaleDocSummary.StampsCharges, 
	MA_SaleDocSummary.CollectionCharges, 
	MA_SaleDocSummary.AdditionalCharges, 
	MA_SaleDocSummary.Contributions, 
	MA_SaleDoc.DocumentType, 
	MA_SaleDoc.DocNo, 
	MA_SaleDoc.DocumentDate, 
	MA_SaleDoc.DepartureDate, 
	MA_SaleDoc.Currency, 
	MA_SaleDoc.FixingDate, 
	MA_SaleDoc.FixingIsManual, 
	MA_SaleDoc.Fixing, 
	MA_SaleDoc.AreaManager, 
	MA_SaleDoc.AccTpl, 
	MA_SaleDoc.TaxJournal, 
	MA_SaleDoc.Issued, 
	MA_SaleDoc.PostedToAccounting, 
	MA_SaleDoc.SaleDocId, 
	MA_SaleDoc.InvRsn, 
	MA_SaleDoc.StubBook AS StubBook, 
	MA_SaleDoc.StoragePhase1, 
	MA_SaleDoc.StoragePhase2, 
	MA_SaleDoc.Job, 
	MA_SaleDoc.CostCenter, 
	MA_SaleDoc.Payment AS DocumentPymt, 
	MA_SaleDoc.PriceList AS DocumentPriceList, 
	MA_SaleDoc.Area AS DocumentArea, 
	MA_SaleDoc.Salesperson AS DocumentSalesperson 
		FROM	MA_CustSupp, MA_CustSuppCustomerOptions, MA_SaleDoc, MA_SaleDocSummary 
		WHERE	MA_SaleDoc.IncludedInTurnover = '1'  AND  
				MA_CustSupp.CustSuppType = 3211264  AND  
				MA_SaleDocSummary.SaleDocId = MA_SaleDoc.SaleDocId  AND  
				MA_CustSupp.CustSupp = MA_CustSuppCustomerOptions.Customer  AND  
				MA_SaleDoc.CustSupp = MA_CustSupp.CustSupp  
		ORDER BY MA_CustSupp.CustSupp
GO

PRINT 'Vista [dbo].[MA_SalesStatistics] creata con successo'
GO

