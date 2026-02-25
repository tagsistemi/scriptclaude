-- Vista [dbo].[scadordbase3] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'scadordbase3')
BEGIN
    DROP VIEW [dbo].[scadordbase3]
    PRINT 'Vista [dbo].[scadordbase3] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[scadordbase3]
AS
SELECT     MAX(Line) AS riga, Position, MAX(OrderDate) AS DtaOrdFor, ExpectedDeliveryDate, PurchaseOrdId, SUM(UnitValue * DeliveredQty) AS ImpCons, 
                      SUM(TotalAmount / Qty * DeliveredQty) AS TotCons
FROM         dbo.MA_PurchaseOrdDetails
WHERE     (LineType = 3538947) AND (DeliveredQty > 0)
GROUP BY PurchaseOrdId, Position, ExpectedDeliveryDate
GO

PRINT 'Vista [dbo].[scadordbase3] creata con successo'
GO

