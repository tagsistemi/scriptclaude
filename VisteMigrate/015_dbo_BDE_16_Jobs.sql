-- Vista [dbo].[BDE_16_Jobs] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_16_Jobs')
BEGIN
    DROP VIEW [dbo].[BDE_16_Jobs]
    PRINT 'Vista [dbo].[BDE_16_Jobs] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_16_Jobs]
AS


SELECT 
	Job									as IdERP,
	Description							as Description,
	Customer							as IdERPCustSupp,
	CreationDate						as CreationDate,
	ExpectedStartingDate				as ExpectedStartDate,
	ExpectedDeliveryDate				AS ExpectedDeliveryDate,
	StartingDate						as StartDate,
	DeliveryDate						AS EndDate,
	DeliveryDate						AS DeliveryDate,
	CONVERT(Integer, Inhouse)			AS InternalJob,
	ParentJob							AS IdERPParentJob,
	CONVERT(Integer, Disabled)			AS DisableJob,
	TBModified							AS BMUpdate

	
FROM
	MA_Jobs
WHERE
	Job != ''
GO

PRINT 'Vista [dbo].[BDE_16_Jobs] creata con successo'
GO

