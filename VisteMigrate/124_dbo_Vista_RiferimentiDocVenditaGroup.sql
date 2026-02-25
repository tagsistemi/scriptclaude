-- Vista [dbo].[Vista_RiferimentiDocVenditaGroup] - Aggiornamento
-- Generato: 2026-02-23 21:30:42

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'Vista_RiferimentiDocVenditaGroup')
BEGIN
    DROP VIEW [dbo].[Vista_RiferimentiDocVenditaGroup]
    PRINT 'Vista [dbo].[Vista_RiferimentiDocVenditaGroup] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[Vista_RiferimentiDocVenditaGroup]
AS
SELECT     SaleDocId, MAX(Line) AS Line, DocumentId, DocumentType, DocumentDate, DocumentNumber, MAX(ReferenceIsAuto) AS ReferenceIsAuto, MAX(Notes) 
                      AS Notes, MAX(TBCreated) AS TBCreated, MAX(TBModified) AS TBModified
FROM         dbo.MA_SaleDocReferences
GROUP BY SaleDocId, DocumentId, DocumentType, DocumentDate, DocumentNumber
GO

PRINT 'Vista [dbo].[Vista_RiferimentiDocVenditaGroup] creata con successo'
GO

