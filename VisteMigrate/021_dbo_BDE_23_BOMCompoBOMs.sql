-- Vista [dbo].[BDE_23_BOMCompoBOMs] - Aggiornamento
-- Generato: 2026-02-23 21:30:33

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_23_BOMCompoBOMs')
BEGIN
    DROP VIEW [dbo].[BDE_23_BOMCompoBOMs]
    PRINT 'Vista [dbo].[BDE_23_BOMCompoBOMs] eliminata'
END
GO

-- Ricreazione vista
CREATE VIEW [dbo].[BDE_23_BOMCompoBOMs] AS
SELECT
	BMC.BOM						AS IdERPParentBOM,
	'0'							AS RevisionParentBOM,
	BMC.Component				AS IdERPBOM,
	'0'							AS Revision,
	BMC.DNRtgStep				AS StepNumber,
	''							AS Alternate,
	0							AS AlternateStepNumber,
	UPPER(BMC.UoM)				AS IdERPUnitOfMeasure,
	BMC.Qty						AS RequiredItemQuantity,
	BMC.FixedComponent			AS FixedComponent,
	BMC.ToExplode				AS ExplodeComponent,
	BMC.ValidityStartingDate	AS ValidityStartDate,
	BMC.ValidityEndingDate		AS ValidityEndDate,
	BMC.SubId					AS OrderId,
	BMC.TBModified				AS BMUpdate
FROM
	MA_BillOfMaterialsComp BMC
	INNER JOIN MA_BillOfMaterials BOM
		ON BMC.BOM = BOM.BOM
	INNER JOIN MA_Items ITM
		ON ITM.Item = BMC.Component
	INNER JOIN (
					SELECT
						BMR.BOM,
						BMR.RtgStep
					FROM
						MA_BillOfMaterialsRouting BMR
						INNER JOIN BM_ConsoleWC CWC
							ON BMR.WC = CWC.WorkCenter
					--WHERE CWC.Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
					GROUP BY
						BMR.BOM,
						BMR.RtgStep
				) STEP	-- PER ESTRARRE SOLO I COMPONENTI ASSOCIATI A FASI LA CUI MACCHINA E' PRESENTE NELLA CONSOLE DEL BRAVO AGENT
		ON BMC.BOM = STEP.BOM
		AND BMC.DNRtgStep = STEP.RtgStep
WHERE
	BOM.CodeType = 7798784	-- le distinte fantasma non vengono gestite in Bravo Manufacturing, quindi non verranno importate
	AND BMC.ComponentType = 7798784 -- Righe di tipo "Articolo"
	AND ITM.Nature != 22413314	-- Prodotto Finito e Semilavorato
	AND BMC.Component IN (select BOM from MA_BillOfMaterials WHERE BOM.CodeType = 7798784)
GO

PRINT 'Vista [dbo].[BDE_23_BOMCompoBOMs] creata con successo'
GO

