-- Vista [dbo].[VistaDebitiCentrodiCosto] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'VistaDebitiCentrodiCosto')
BEGIN
    DROP VIEW [dbo].[VistaDebitiCentrodiCosto]
    PRINT 'Vista [dbo].[VistaDebitiCentrodiCosto] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[VistaDebitiCentrodiCosto]
AS
SELECT     dbo.MA_PyblsRcvbls.CustSuppType, dbo.MA_PyblsRcvbls.CustSupp, dbo.MA_PyblsRcvbls.Settled, dbo.MA_PyblsRcvbls.Payment, 
                      dbo.MA_PyblsRcvbls.JournalEntryId, dbo.MA_PyblsRcvblsDetails.InstallmentNo, dbo.MA_PyblsRcvblsDetails.OpeningDate, 
                      dbo.MA_PyblsRcvblsDetails.InstallmentDate, dbo.MA_PyblsRcvblsDetails.DebitCreditSign, dbo.MA_PyblsRcvblsDetails.Amount, 
                      dbo.MA_PyblsRcvblsDetails.Closed, dbo.MA_PyblsRcvbls.Currency, dbo.MA_PyblsRcvbls.DocNo, dbo.MA_PyblsRcvbls.DocumentDate, 
                      dbo.MA_PyblsRcvbls.PymtSchedId, dbo.VistaIncidenzaCentrodicostoTotale.TotaleCosto, dbo.VistaIncidenzaCentrodicostoTotale.TotaelCostoCentro, 
                      dbo.VistaIncidenzaCentrodicostoTotale.CostCenter, dbo.VistaIncidenzaCentrodicostoTotale.incidenza, 
                      dbo.VistaIncidenzaCentrodicostoTotale.TotaleCostoPrimaNotaAnalitica
FROM         dbo.MA_PyblsRcvbls INNER JOIN
                      dbo.MA_PyblsRcvblsDetails ON dbo.MA_PyblsRcvbls.PymtSchedId = dbo.MA_PyblsRcvblsDetails.PymtSchedId LEFT OUTER JOIN
                      dbo.VistaIncidenzaCentrodicostoTotale ON dbo.MA_PyblsRcvbls.JournalEntryId = dbo.VistaIncidenzaCentrodicostoTotale.JournalEntryId
GO

PRINT 'Vista [dbo].[VistaDebitiCentrodiCosto] creata con successo'
GO

