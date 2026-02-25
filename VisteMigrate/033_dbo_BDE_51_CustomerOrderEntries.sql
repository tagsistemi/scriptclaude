-- Vista [dbo].[BDE_51_CustomerOrderEntries] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_51_CustomerOrderEntries')
BEGIN
    DROP VIEW [dbo].[BDE_51_CustomerOrderEntries]
    PRINT 'Vista [dbo].[BDE_51_CustomerOrderEntries] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_51_CustomerOrderEntries] as
SELECT	
    SOD.Item AS IdERPItem,

    CASE
        WHEN SOD.JOB <> ''
            THEN SOD.Job
        ELSE SO.InternalOrdNo 
		--+ '_' + RIGHT('000' + CAST(MIN(SOD.Position) AS VARCHAR(3)), 3)
    END AS IdERPJob,

    SOD.UoM AS IdERPUnitOfMeasure,
    SOD.ExpectedDeliveryDate AS ExpectedDeliveryDate,
    SOD.ConfirmedDeliveryDate AS ConfirmedDeliveryDate,
    SOD.Description AS ItemCustomDescription,

    -- Elenco POSITION raggruppate
    STUFF((
        SELECT ', ' + CAST(SOD2.Position AS VARCHAR(10))
        FROM MA_SaleOrdDetails SOD2
        WHERE
            SOD2.SaleOrdId = SOD.SaleOrdId
            AND SOD2.Item = SOD.Item
            AND ISNULL(SOD2.JOB, '') = ISNULL(SOD.JOB, '')
            AND SOD2.UoM = SOD.UoM
            AND SOD2.ExpectedDeliveryDate = SOD.ExpectedDeliveryDate
            AND SOD2.ConfirmedDeliveryDate = SOD.ConfirmedDeliveryDate
          --AND SOD2.UnitValue = SOD.UnitValue
            AND SOD2.Delivered = 0
        FOR XML PATH(''), TYPE
    ).value('.', 'VARCHAR(MAX)'), 1, 2, '') AS Notes,

    SO.InternalOrdNo AS OrderNumber,
  --SOD.UnitValue AS UnitPrice,

    -- Quantità sommata
    SUM(SOD.Qty) AS RequiredQuantity,

    -- Riga ordine rappresentativa
    MIN(SOD.Position) AS OrderRow,

    0 AS Status,
    MAX(SOD.TBModified) AS BMUpdate
FROM
    MA_SaleOrdDetails SOD
    INNER JOIN MA_SaleOrd SO
        ON SOD.SaleOrdId = SO.SaleOrdId
    INNER JOIN MA_Items IT
        ON IT.Item = SOD.Item
WHERE
    SOD.Delivered = 0
    AND IT.Nature IN (22413313,22413312)
GROUP BY
    SOD.SaleOrdId,
    SOD.Item,
    CASE
        WHEN SOD.JOB <> ''
            THEN SOD.Job
        ELSE SO.InternalOrdNo
    END,
    SOD.JOB,
    SOD.UoM,
    SOD.ExpectedDeliveryDate,
    SOD.ConfirmedDeliveryDate,
    SOD.Description,
    SO.InternalOrdNo
  --SOD.UnitValue;
GO

PRINT 'Vista [dbo].[BDE_51_CustomerOrderEntries] creata con successo'
GO

