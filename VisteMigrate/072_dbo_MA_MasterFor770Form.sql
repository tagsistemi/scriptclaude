-- Vista [dbo].[MA_MasterFor770Form] - Aggiornamento
-- Generato: 2026-02-23 21:30:37

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'MA_MasterFor770Form')
BEGIN
    DROP VIEW [dbo].[MA_MasterFor770Form]
    PRINT 'Vista [dbo].[MA_MasterFor770Form] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[MA_MasterFor770Form] AS  SELECT 
	MA_CustSupp.CompanyName, 
	MA_CustSupp.CustSupp, 
	MA_CustSupp.CustSuppType, 
	MA_CustSupp.City, 
	MA_CustSupp.County, 
	MA_CustSupp.Address, 
	MA_CustSuppNaturalPerson.LastName, 
	MA_CustSuppNaturalPerson.Name, 
	MA_CustSuppNaturalPerson.DateOfBirth, 
	MA_CustSuppNaturalPerson.Gender, 
	MA_CustSuppNaturalPerson.CityOfBirth, 
	MA_CustSuppNaturalPerson.CountyOfBirth 
	FROM MA_CustSupp LEFT OUTER JOIN MA_CustSuppNaturalPerson 
	ON  MA_CustSupp.CustSupp=MA_CustSuppNaturalPerson.CustSupp AND MA_CustSupp.CustSuppType=MA_CustSuppNaturalPerson.CustSuppType
GO

PRINT 'Vista [dbo].[MA_MasterFor770Form] creata con successo'
GO

