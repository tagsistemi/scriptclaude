-- Vista [dbo].[BDE_15_CustSupp] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_15_CustSupp')
BEGIN
    DROP VIEW [dbo].[BDE_15_CustSupp]
    PRINT 'Vista [dbo].[BDE_15_CustSupp] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_15_CustSupp] AS
SELECT 
	CustSupp								AS IdERP,
	CASE CustSuppType
		WHEN 3211264 then 0 --cliente
		WHEN 3211265 then 1 -- fornitore
	end										AS TypeCustSupp,
	CompanyName								AS CompanyName,
	TaxIdNumber								AS TaxIdNumber,
	FiscalCode								AS FiscalCode,
	Address									AS Address,
	ZIPCode									AS ZIPCode,
	City									AS City,
	County									AS Province,
	Country									AS Country,
	Telephone1								AS Phone1,
	Telephone2								AS Phone2,
	Telex									AS Telex,
	Fax										AS Fax,
	Internet								AS WebSite,
	Email									AS Email,
	ContactPerson							AS Representative,
	CAST(Notes as text)						AS Notes,
	Disabled								AS DisabledCustSupp,
	1										AS MaterialsProposition,
	TBModified								AS BMUpdate
FROM
	MA_CustSupp
WHERE
	CustSupp != ''
	AND CompanyName IS NOT NULL
	AND CompanyName != ''
GO

PRINT 'Vista [dbo].[BDE_15_CustSupp] creata con successo'
GO

