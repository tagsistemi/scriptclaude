-- Vista [dbo].[BDE_50_CustomerOrders] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_50_CustomerOrders')
BEGIN
    DROP VIEW [dbo].[BDE_50_CustomerOrders]
    PRINT 'Vista [dbo].[BDE_50_CustomerOrders] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_50_CustomerOrders]
AS SELECT	
	Customer			AS IdERPCustSupp
	,Job				AS IdERPJob
	,TBCreated			AS CreationDate
	,OrderDate			AS OrderDate
	,Cancelled			AS DisableCustomerOrder
	--,Cancelled		AS Deleted	-- Questo campo lo gestisce direttamente Bravo, non va mappato nel task del BDE
	,ExternalOrdNo		AS ExternalNumber
	,InternalOrdNo		AS OrderNumber
	,'0'				AS Status
	,TBModified			AS BMUpdate
FROM
	MA_SaleOrd SO
WHERE
	Delivered=0
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

PRINT 'Vista [dbo].[BDE_50_CustomerOrders] creata con successo'
GO

