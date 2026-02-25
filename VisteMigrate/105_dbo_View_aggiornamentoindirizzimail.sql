-- Vista [dbo].[View_aggiornamentoindirizzimail] - Creazione
-- Generato: 2026-02-23 21:30:40

-- Creazione schema se non esiste
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
    PRINT 'Schema [dbo] creato'
END
GO

-- Creazione vista
CREATE VIEW [dbo].[View_aggiornamentoindirizzimail]
AS
SELECT     dbo.MA_CustSupp.CustSupp, dbo.MA_CustSupp.CustSuppType, dbo.IndirizziPerFatture.INDIRIZZO, dbo.MA_CustSupp.DocumentSendingType, 
                      dbo.MA_CustSupp.EMail, dbo.MA_CustSupp.MailSendingType
FROM         dbo.MA_CustSupp INNER JOIN
                      dbo.IndirizziPerFatture ON dbo.MA_CustSupp.CustSupp = dbo.IndirizziPerFatture.CODICE
WHERE     (dbo.MA_CustSupp.CustSuppType = 3211264)
GO

PRINT 'Vista [dbo].[View_aggiornamentoindirizzimail] creata con successo'
GO

