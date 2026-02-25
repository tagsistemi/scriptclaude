-- Vista [dbo].[IM_JobItemsOrder] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_JobItemsOrder')
BEGIN
    DROP VIEW [dbo].[IM_JobItemsOrder]
    PRINT 'Vista [dbo].[IM_JobItemsOrder] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_JobItemsOrder] AS  
	SELECT 	
		'1' AS JobTypeOrder,
                IM_JobsItems.Job,
                IM_JobsItems.Job AS ParentJob,
                MA_Jobs.Description AS JobDescription,
                IM_JobsItems.PrefSupplier,
                IM_JobsItems.PrefCost,
                IM_JobsItems.PrefDiscountFormula,
                IM_JobsItems.LastCost,
                IM_JobsItems.SecondLastCost,
                IM_JobsItems.AverageCost,
                IM_JobsItems.Item,
                MA_Items.Producer,
                MA_Items.CommodityCtg,
                MA_Items.ProductCtg,
                MA_Items.Description AS ItemDescription,
                MA_Jobs.CreationDate

	FROM 
                IM_JobsItems
                LEFT OUTER JOIN MA_Items
                               ON IM_JobsItems.Item = MA_Items.Item
                LEFT OUTER JOIN MA_Jobs
                               ON IM_JobsItems.Job = MA_Jobs.Job
	WHERE
                MA_Jobs.ParentJob is not null and
                MA_Jobs.ParentJob = '' --COMMESSE PADRE		
                
UNION ALL

SELECT
                '2' AS JobTypeOrder,
                IM_JobsItems.Job,
                MA_Jobs.ParentJob,
                MA_Jobs.Description AS JobDescription,
                IM_JobsItems.PrefSupplier,
                IM_JobsItems.PrefCost,
                IM_JobsItems.PrefDiscountFormula,
                IM_JobsItems.LastCost,
                IM_JobsItems.SecondLastCost,
                IM_JobsItems.AverageCost,
                IM_JobsItems.Item,
                MA_Items.Producer,
                MA_Items.CommodityCtg,
                MA_Items.ProductCtg,
                MA_Items.Description AS ItemDescription,
                MA_Jobs.CreationDate

FROM
                IM_JobsItems
                LEFT OUTER JOIN MA_Items
                               ON IM_JobsItems.Item = MA_Items.Item
                LEFT OUTER JOIN MA_Jobs
                               ON IM_JobsItems.Job = MA_Jobs.Job
WHERE
                MA_Jobs.ParentJob is not null and
                MA_Jobs.ParentJob != '' --COMMESSE FIGLIE
GO

PRINT 'Vista [dbo].[IM_JobItemsOrder] creata con successo'
GO

