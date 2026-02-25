-- Vista [dbo].[IM_WorkingReportsWRStat] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'IM_WorkingReportsWRStat')
BEGIN
    DROP VIEW [dbo].[IM_WorkingReportsWRStat]
    PRINT 'Vista [dbo].[IM_WorkingReportsWRStat] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[IM_WorkingReportsWRStat]  
AS  
	SELECT 	IM_WorkingReports.WorkingReportNo, 
		IM_WorkingReports.WorkingReportId, 
		IM_WorkingReports.WorkingReportDate, 
		IM_WorkingReports.PostingDate, 
		IM_WorkingReports.Customer, 
		IM_WorkingReports.Job, 
		IM_WorkingReports.StubBook, 
		IM_WorkingReportsStat.Line, 
		IM_WorkingReportsStat.Processing, 
		IM_WorkingReportsStat.Description, 
		IM_WorkingReportsStat.Time 
	FROM IM_WorkingReportsStat LEFT OUTER JOIN IM_WorkingReports ON 
		IM_WorkingReportsStat.WorkingReportId = IM_WorkingReports.WorkingReportId
GO

PRINT 'Vista [dbo].[IM_WorkingReportsWRStat] creata con successo'
GO

