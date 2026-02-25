-- Vista [dbo].[BDE_51_CustomerOrderEntries_old] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_51_CustomerOrderEntries_old')
BEGIN
    DROP VIEW [dbo].[BDE_51_CustomerOrderEntries_old]
    PRINT 'Vista [dbo].[BDE_51_CustomerOrderEntries_old] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_51_CustomerOrderEntries_old]
AS 
SELECT	
	SOD.Item						AS IdERPItem
	,CASE
		WHEN SOD.JOB != ''
		THEN SOD.Job
		ELSE SO.InternalOrdNo+'_'+RIGHT('000' + CAST(SOD.POSITION	AS VARCHAR(3)),3)	
	END								AS IdERPJob
	,SOD.UoM						AS IdERPUnitOfMeasure
	,SOD.ExpectedDeliveryDate		AS ExpectedDeliveryDate
	,SOD.ConfirmedDeliveryDate		AS ConfirmedDeliveryDate
	,SOD.Description				AS ItemCustomDescription
	,SOD.DiscountFormula			AS DiscountFormula
	,SOD.Notes						AS Notes
	,SO.InternalOrdNo				AS OrderNumber
	,SOD.TaxableAmount				AS TotalPrice
	,SOD.UnitValue					AS UnitPrice
	,SOD.Qty						AS RequiredQuantity
	--,								AS ProducedQuantity -- QUESTO CAMPO NON LO PASSIAMO PERCHE' VIENE COMPILATO DA BRAVO
	,SOD.Position					AS OrderRow
	,100-(((100-SOD.Discount1)/100)*(100-SOD.Discount2)) AS Discount
	,0							AS Status
	,SOD.TBModified					AS BMUpdate
FROM
	MA_SaleOrdDetails SOD
	INNER JOIN MA_SaleOrd SO
		ON SOD.SaleOrdId = SO.SaleOrdId
	--LEFT OUTER JOIN
	--	(
	--		SELECT
	--			SaleOrdId
	--			,MIN(Delivered) AS DeliveredMin
	--			,MAX(Delivered) AS DeliveredMax
	--		FROM
	--			MA_SaleOrdDetails
	--		WHERE
	--			LineType IN (3538946,3538947)	-- Righe di tipo Merce e Servizio
	--			And Cancelled = '0'				-- Non annullate
	--		GROUP BY
	--			SaleOrdId
	--	) SOD
	--	ON SO.SaleOrdId = SOD.SaleOrdId
GO

PRINT 'Vista [dbo].[BDE_51_CustomerOrderEntries_old] creata con successo'
GO

