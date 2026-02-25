-- Vista [dbo].[Vista_Ramdaevadere] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_Ramdaevadere')
BEGIN
    DROP VIEW [dbo].[Vista_Ramdaevadere]
    PRINT 'Vista [dbo].[Vista_Ramdaevadere] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_Ramdaevadere]
AS
SELECT     TOP (100) PERCENT MIN(dbo.gpx_righeram.Reparto) AS Rep, dbo.gpx_testaram.NrRam, MIN(dbo.gpx_testaram.DataRam) AS Data_Ram, 
                      MIN(dbo.MA_SaleOrd.ExpectedDeliveryDate) AS DataCons, MIN(dbo.gpx_testaram.Commessa) AS NOrdine, MIN(dbo.gpx_testaram.Cliente) AS Ccliente,
                       dbo.MA_CustSupp.CompanyName, dbo.gpx_testaram.StatoRam, '' AS NOTE, dbo.gpx_testaram.IdRam, dbo.MA_SaleOrd.SaleOrdId
FROM         dbo.gpx_righeram INNER JOIN
                      dbo.gpx_testaram ON dbo.gpx_righeram.IdRam = dbo.gpx_testaram.IdRam INNER JOIN
                      dbo.MA_SaleOrd ON dbo.gpx_testaram.IdOrdine = dbo.MA_SaleOrd.SaleOrdId INNER JOIN
                      dbo.MA_CustSupp ON dbo.gpx_testaram.Cliente = dbo.MA_CustSupp.CustSupp
GROUP BY dbo.gpx_testaram.NrRam, dbo.MA_CustSupp.CustSupp, dbo.MA_CustSupp.CustSuppType, dbo.MA_CustSupp.CompanyName, 
                      dbo.gpx_testaram.Cliente, dbo.gpx_testaram.StatoRam, dbo.gpx_testaram.IdRam, dbo.MA_SaleOrd.SaleOrdId
HAVING      (SUM(dbo.gpx_righeram.QtaDaProd) > 0) AND (dbo.MA_CustSupp.CustSuppType = 3211264)
ORDER BY Rep, DataCons, dbo.gpx_testaram.NrRam
GO

PRINT 'Vista [dbo].[Vista_Ramdaevadere] creata con successo'
GO

