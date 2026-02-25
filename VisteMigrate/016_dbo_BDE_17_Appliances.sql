-- Vista [dbo].[BDE_17_Appliances] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_17_Appliances')
BEGIN
    DROP VIEW [dbo].[BDE_17_Appliances]
    PRINT 'Vista [dbo].[BDE_17_Appliances] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_17_Appliances] AS
SELECT 
	C.BravoID						AS IdERP,
	WC.Description					AS Name,
	WC.Description					AS Description,
	COALESCE(CW.BravoWorkerId, '')	AS IdERPResponsible,
	WC.Outsourced					AS ExternalAppliance,
	WC.Supplier						AS IdERPSupplier,
	WC.TBModified					AS BMUpdate
FROM
	BM_ConsoleWC C
	INNER JOIN MA_WorkCenters WC
		ON C.WorkCenter = WC.WC
	LEFT OUTER JOIN BM_ConsoleWorkers CW
		ON CW.Console = C.Console
			AND WC.ManagerID = CW.MagoWorkerID
WHERE
	C.BravoID != ''
	--AND C.Console = ''	-- SCRIVERE TRA GLI APICI IL CODICE DELLA CONSOLE (SOLO IN CUI SI GESTISCANO PIù CONSOLE)
GO

PRINT 'Vista [dbo].[BDE_17_Appliances] creata con successo'
GO

