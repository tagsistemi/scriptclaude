-- Vista [dbo].[IM_JobCorrectionsList] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_JobCorrectionsList')
BEGIN
    DROP VIEW [dbo].[IM_JobCorrectionsList]
    PRINT 'Vista [dbo].[IM_JobCorrectionsList] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_JobCorrectionsList] AS
SELECT
	IM_JobCorrections.Approver,
	IM_JobCorrections.Job		,
	COALESCE (MA_Jobs.ParentJob, '')							AS ParentJob	,			
	MA_Jobs.Description											AS JobDescription,
	IM_JobCorrections.JCNo ,
	IM_JobCorrections.CreationDate ,
	IM_JobCorrectionsDetails.TypeCorrection,
	IM_JobCorrectionsDetails.Component ,
	MA_Items.Description										AS ItemDescription,
	IM_JobCorrectionsDetails.BaseUoM ,
	IM_JobCorrectionsDetails.QtyJob ,
	IM_JobCorrectionsDetails.QtyCorrected ,
	(IM_JobCorrectionsDetails.QtyJob + IM_JobCorrectionsDetails.QtyCorrected)	AS  QtyTot,
	IM_JobCorrectionsDetails.QtyToCorrect ,
	IM_JobCorrectionsDetails.Cost ,
	IM_JobCorrectionsDetails.DiscountFormula ,					
	IM_JobCorrectionsDetails.TotCostAmount ,
	IM_JobCorrectionsDetails.JCId ,
	IM_JobCorrectionsDetails.Line,
	IM_JobCorrectionsDetails.NewItem ,
	MA_Jobs.Customer ,
	
	CASE COALESCE (MA_Jobs.ParentJob, '')
		WHEN '' THEN '1'
		ELSE '2'
	END AS JobTypeOrder


FROM
	IM_JobCorrections
	LEFT OUTER JOIN IM_JobCorrectionsDetails
		ON IM_JobCorrections.JCId = IM_JobCorrectionsDetails.JCId
	LEFT OUTER JOIN MA_Items
		ON IM_JobCorrectionsDetails.Component = MA_Items.Item
	LEFT OUTER JOIN MA_Jobs
		ON IM_JobCorrections.Job = MA_Jobs.Job

WHERE
	MA_Jobs.ParentJob is not null
GO

PRINT 'Vista [dbo].[IM_JobCorrectionsList] creata con successo'
GO

