-- Vista [dbo].[saldi_per_gruppo] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'saldi_per_gruppo')
BEGIN
    DROP VIEW [dbo].[saldi_per_gruppo]
    PRINT 'Vista [dbo].[saldi_per_gruppo] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[saldi_per_gruppo]
AS
SELECT     TOP 100 PERCENT dbo.MA_CostAccEntriesDetail.Account, dbo.MA_CostAccEntriesDetail.AccrualDate, dbo.MA_CostAccEntriesDetail.CodeType, 
                      dbo.MA_CostAccEntriesDetail.CostCenter, dbo.MA_CostAccEntriesDetail.DebitCreditSign, dbo.MA_CostAccEntriesDetail.Amount, 
                      dbo.MA_ChartOfAccounts.Description AS descripdc, dbo.MA_CostCenters.Description AS descricentro, dbo.MA_CostCenters.GroupCode, 
                      dbo.MA_CostCenterGroups.Description AS descrigruppo, dbo.MA_ChartOfAccounts.Ledger, 
                      CASE dbo.MA_CostAccEntriesDetail.DebitCreditSign WHEN 4980736 THEN dbo.MA_CostAccEntriesDetail.Amount ELSE 0 END AS Dare, 
                      CASE dbo.MA_CostAccEntriesDetail.DebitCreditSign WHEN 4980737 THEN dbo.MA_CostAccEntriesDetail.Amount ELSE 0 END AS avere, 
                      SUBSTRING(dbo.MA_CostAccEntriesDetail.Account, 1, 4) AS MASTRINO
FROM         dbo.MA_CostCenterGroups INNER JOIN
                      dbo.MA_CostCenters ON dbo.MA_CostCenterGroups.GroupCode = dbo.MA_CostCenters.GroupCode INNER JOIN
                      dbo.MA_ChartOfAccounts INNER JOIN
                      dbo.MA_CostAccEntriesDetail ON dbo.MA_ChartOfAccounts.Account = dbo.MA_CostAccEntriesDetail.Account ON 
                      dbo.MA_CostCenters.CostCenter = dbo.MA_CostAccEntriesDetail.CostCenter
GO

PRINT 'Vista [dbo].[saldi_per_gruppo] creata con successo'
GO

