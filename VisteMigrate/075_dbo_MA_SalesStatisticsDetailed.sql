-- Vista [dbo].[MA_SalesStatisticsDetailed] - Aggiornamento
-- Generato: 2026-02-23 21:30:38

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_SalesStatisticsDetailed')
BEGIN
    DROP VIEW [dbo].[MA_SalesStatisticsDetailed]
    PRINT 'Vista [dbo].[MA_SalesStatisticsDetailed] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_SalesStatisticsDetailed] AS  SELECT  Top 100 percent 
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
	MA_SaleDoc.Salesperson AS DocumentSalesperson, 
	MA_Items.ItemType, 
	MA_Items.CommodityCtg, 
	MA_Items.HomogeneousCtg, 
	MA_Items.CommissionCtg, 
	MA_Items.ProductCtg, 
	MA_SaleDocDetail.LineType, 
	MA_SaleDocDetail.Description, 
	MA_SaleDocDetail.Item, 
	MA_SaleDocDetail.Department, 
	MA_SaleDocDetail.TaxableAmount AS LineTaxableAmount, 
	MA_SaleDocDetail.TaxCode, 
	MA_SaleDocDetail.TotalAmount, 
	MA_SaleDocDetail.Offset, 
	MA_SaleDocDetail.SaleType, 
	MA_SaleDocDetail.CombinedNomenclature, 
	MA_SaleDocDetail.Contribution, 
	MA_SaleDocDetail.DiscountAmount AS LineDiscountAmount, 
	MA_SaleDocDetail.Job AS LineJob, 
	MA_SaleDocDetail.CostCenter AS LineCenterCost 
	FROM	MA_CustSupp, MA_CustSuppCustomerOptions, MA_SaleDoc, MA_SaleDocSummary, MA_Items, MA_SaleDocDetail 
	WHERE	MA_SaleDoc.IncludedInTurnover = '1'  AND  
			MA_CustSupp.CustSuppType = 3211264  AND  
			MA_SaleDocDetail.LineType != 3538944  AND  
			MA_SaleDocDetail.LineType != 3538945  AND  
			MA_SaleDocDetail.LineType != 3538948  AND  
			MA_SaleDocSummary.SaleDocId = MA_SaleDoc.SaleDocId  AND  
			MA_CustSupp.CustSupp = MA_CustSuppCustomerOptions.Customer  AND  
			MA_SaleDoc.CustSupp = MA_CustSupp.CustSupp  AND  
			MA_SaleDoc.SaleDocId = MA_SaleDocDetail.SaleDocId  AND  
			MA_SaleDocDetail.Item = MA_Items.Item  
	ORDER BY MA_CustSupp.CustSupp, MA_SaleDocDetail.Item
GO

PRINT 'Vista [dbo].[MA_SalesStatisticsDetailed] creata con successo'
GO

