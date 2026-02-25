-- Vista [dbo].[IM_JobsParentJobs] - Aggiornamento
-- Generato: 2026-02-23 21:30:36

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_JobsParentJobs')
BEGIN
    DROP VIEW [dbo].[IM_JobsParentJobs]
    PRINT 'Vista [dbo].[IM_JobsParentJobs] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_JobsParentJobs] AS  
	SELECT DISTINCT JCRS.[Job] AS ParentJob
		   , JCRS.[Job]
		   , MAJ.JobType AS JobType
		   , MAJ.GroupCode AS GroupCode
		   , MAJ.Customer AS Customer
		   , JS.Manager
	FROM [IM_JobsCostsRevenuesSummary] AS JCRS
	JOIN MA_Jobs MAJ ON JCRS.[Job] = MAJ.job
	JOIN IM_JobsSummary JS ON JS.Job = JCRS.[Job]
	WHERE (MAJ.JobType = 25034752 OR MAJ.JobType = 25034753) AND MAJ.ParentJob = ''
	GROUP BY JCRS.[Job], MAJ.JobType, MAJ.GroupCode, MAJ.Customer, JS.Manager
	UNION ALL
	SELECT GJ2.[ParentJob] AS ParentJob
		   , JCRS2.[Job]
		   , MAJ2.JobType AS JobType
		   , MAJ2.GroupCode AS GroupCode
		   , MAJ2.Customer AS Customer
		   , JS2.Manager
	FROM [IM_JobsCostsRevenuesSummary] as JCRS2
	OUTER APPLY dbo.GetJobs(JCRS2.[Job]) GJ2
	JOIN MA_Jobs MAJ2 ON JCRS2.[Job] = MAJ2.job
	JOIN IM_JobsSummary JS2 ON JS2.Job = JCRS2.[Job]
	WHERE GJ2.ParentJob <> '' AND MAJ2.JobType <> 25034752
	GROUP BY GJ2.[ParentJob], JCRS2.[Job], MAJ2.JobType, MAJ2.GroupCode, MAJ2.Customer, JS2.Manager
GO

PRINT 'Vista [dbo].[IM_JobsParentJobs] creata con successo'
GO

