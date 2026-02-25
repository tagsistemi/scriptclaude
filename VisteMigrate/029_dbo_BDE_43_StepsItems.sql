-- Vista [dbo].[BDE_43_StepsItems] - Aggiornamento
-- Generato: 2026-02-23 21:30:34

-- Eliminazione vista esistente
IF EXISTS (SELECT * FROM sys.views v INNER JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = N'dbo' AND v.name = N'BDE_43_StepsItems')
BEGIN
    DROP VIEW [dbo].[BDE_43_StepsItems]
    PRINT 'Vista [dbo].[BDE_43_StepsItems] eliminata'
END
GO

-- Ricreazione vista
-- VISTA MODIFICATA DA OMAR GRADARA IL 20/05/2021 A SEGUITO DEL TICKET BCM4-49, RELATIVO ALLA SOSTITUZIONE COMPONENTI
-- DA MAGO4 3.2.0 IN POI

CREATE VIEW [dbo].[BDE_43_StepsItems] AS

SELECT
			COMP.MONumber,
			COMP.StepNumber,
			MAX(COMP.IdERPItem)			AS IdERPItem,
			COMP.IdERPUnitOfMeasure,
			MAX(RequiredItemQuantity)	AS RequiredItemQuantity,
			MAX(COMP.BMUpdate)			AS BMUpdate
FROM	
	(

		SELECT
			MOC.MONo						AS MONumber,
			MOC.DNRtgStep					AS StepNumber,
			MOC.InitialPosition				AS InitialPosition,
			CASE 
				WHEN MOC.ReplacedComponent != ''
				THEN MOC.ReplacedComponent
				ELSE MOC.Component
			END								AS IdERPItem,
			UPPER(MOC.UoM)					AS IdERPUnitOfMeasure,
			MOC.BM_OriginalNeededQty		AS RequiredItemQuantity,
			--MOC.Lot						AS StockInternalNumber, -- Il numero di lotto non lo passiamo perché va dichiarato a consuntivo oppure va passato a preventivo con gli impegni
			MOC.TBModified					AS BMUpdate
		FROM
			MA_MOComponents MOC
			INNER JOIN MA_MO MO
				ON MOC.MOId = MO.MOId
			INNER JOIN (
							SELECT
								MOS.MOId,
								MOS.RtgStep
							FROM
								MA_MOSteps MOS
								INNER JOIN BM_ConsoleWC CWC
									ON MOS.WC = CWC.WorkCenter
							--WHERE CWC.Console = '' -- INDICARE IL CODICE DELLA CONSOLE NEL CASO SI GESTISCANO PIU' CONSOLE 
							GROUP BY
								MOS.MOId,
								MOS.RtgStep
						) STEP	-- PER ESTRARRE SOLO I COMPONENTI ASSOCIATI A FASI LA CUI MACCHINA E' PRESENTE NELLA CONSOLE DEL BRAVO AGENT
				ON MOC.MOId = STEP.MOId
				AND MOC.DNRtgStep = STEP.RtgStep
		WHERE
			MOC.ReferredPosition = -1
			AND MOC.BM_UnexpectedComponent = '0' -- Componente consuntivato, ma non previsto nell'OdP. Non va passato perché altrimenti entrerebbe a far parte della lista materiali standard dell'OdP.
			AND MO.MOStatus IN
			(
				20578304,	-- LANCIATO
				20578305,	-- IN LAVORAZIONE
				20578306	-- TERMINATO
			)
			AND MO.MONo != ''
		) COMP
GROUP BY
	COMP.MONumber,
	COMP.StepNumber,
	COMP.InitialPosition,
	COMP.IdERPUnitOfMeasure
GO

PRINT 'Vista [dbo].[BDE_43_StepsItems] creata con successo'
GO

