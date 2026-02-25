-- Vista [dbo].[MERCE_PRONTA_BRAVO] - Aggiornamento
-- Generato: 2026-02-23 21:30:39

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MERCE_PRONTA_BRAVO')
BEGIN
    DROP VIEW [dbo].[MERCE_PRONTA_BRAVO]
    PRINT 'Vista [dbo].[MERCE_PRONTA_BRAVO] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MERCE_PRONTA_BRAVO]
AS
SELECT Ordine, CAST(RigaOrdine AS INT) AS RigaOrdine, RigheRaggruppate, OdP, Articolo, QuantitàProdotta
FROM  [WIN-8Q55ETLTAQK].bravoDB_VED.dbo.RigheOC_Prodotte AS RigheOC_Prodotte_1
GO

PRINT 'Vista [dbo].[MERCE_PRONTA_BRAVO] creata con successo'
GO

