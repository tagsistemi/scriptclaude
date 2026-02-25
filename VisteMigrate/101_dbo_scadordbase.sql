-- Vista [dbo].[scadordbase] - Aggiornamento
-- Generato: 2026-02-23 21:30:40

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'scadordbase')
BEGIN
    DROP VIEW [dbo].[scadordbase]
    PRINT 'Vista [dbo].[scadordbase] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[scadordbase]
AS
SELECT     MAX(Line) AS Riga, MAX(Position) AS Posiz, MAX(OrderDate) AS DataOrdine, ExpectedDeliveryDate, SUM(TaxableAmount) AS Imponibile, 
                      SUM(TotalAmount) AS Totale, PurchaseOrdId
FROM         dbo.MA_PurchaseOrdDetails
WHERE     (LineType = 3538947)
GROUP BY PurchaseOrdId, ExpectedDeliveryDate
GO

PRINT 'Vista [dbo].[scadordbase] creata con successo'
GO

