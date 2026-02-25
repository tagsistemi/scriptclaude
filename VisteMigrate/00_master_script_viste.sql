-- Script di creazione viste generato automaticamente
-- Data: 2026-02-23 21:30:32
-- Database origine: gpxnetclone
-- Database destinazione: vedmaster

USE [vedmaster]
GO

:r 004_dbo_aa_vista_etichette_cliente.sql
GO

:r 005_dbo_artcommessew.sql
GO

:r 006_dbo_BDE_04_UoM.sql
GO

:r 007_dbo_BDE_05_UoMComparations.sql
GO

:r 008_dbo_BDE_10_Items.sql
GO

:r 009_dbo_BDE_10_Items_old.sql
GO

:r 010_dbo_BDE_11_ItemsUOMComparations.sql
GO

:r 011_dbo_BDE_12_ItemsCosts.sql
GO

:r 012_dbo_BDE_12_ItemsCosts_old.sql
GO

:r 013_dbo_BDE_13_ItemsLots.sql
GO

:r 014_dbo_BDE_15_CustSupp.sql
GO

:r 015_dbo_BDE_16_Jobs.sql
GO

:r 016_dbo_BDE_17_Appliances.sql
GO

:r 017_dbo_BDE_18_Operations.sql
GO

:r 018_dbo_BDE_20_BOM.sql
GO

:r 019_dbo_BDE_21_BOMSteps.sql
GO

:r 020_dbo_BDE_22_BOMCompoItems.sql
GO

:r 021_dbo_BDE_23_BOMCompoBOMs.sql
GO

:r 022_dbo_BDE_24_BOMStepsWorkerTime.sql
GO

:r 023_dbo_BDE_25_BOMNotes.sql
GO

:r 024_dbo_BDE_31_Teams.sql
GO

:r 025_dbo_BDE_32_Workers.sql
GO

:r 026_dbo_BDE_40_ManufacturingOrders.sql
GO

:r 027_dbo_BDE_41_MOSteps.sql
GO

:r 028_dbo_BDE_42_StepsWorkerTimes.sql
GO

:r 029_dbo_BDE_43_StepsItems.sql
GO

:r 030_dbo_BDE_44_MOHierarchies.sql
GO

:r 031_dbo_BDE_50_CustomerOrders.sql
GO

:r 032_dbo_BDE_50_CustomerOrders_old.sql
GO

:r 033_dbo_BDE_51_CustomerOrderEntries.sql
GO

:r 034_dbo_BDE_51_CustomerOrderEntries_all.sql
GO

:r 035_dbo_BDE_51_CustomerOrderEntries_old.sql
GO

:r 036_dbo_BDE_51_CustomerOrderEntries_old1.sql
GO

:r 037_dbo_BDE_76_ItemsPhotos.sql
GO

:r 038_dbo_BDE_80_FamiliesAppliances.sql
GO

:r 039_dbo_BDE_81_AppliancesHourlyCosts.sql
GO

:r 040_dbo_BDE_85_OperationsWorkerTimes.sql
GO

:r 041_dbo_docviewoikos.sql
GO

:r 042_dbo_docviewtexigom.sql
GO

:r 043_dbo_docviewved.sql
GO

:r 044_dbo_fatturericevuteoikos.sql
GO

:r 045_dbo_fatturericevutetexigom.sql
GO

:r 046_dbo_fatturericevuteved2007.sql
GO

:r 047_dbo_GPX_VistaRigheOrdiniFor.sql
GO

:r 048_dbo_GPX_VistaRigheRam.sql
GO

:r 049_dbo_GPX_VistaSituazioneCommessa.sql
GO

:r 050_dbo_IM_CLCLComponents.sql
GO

:r 051_dbo_IM_DataJobItemWorkingSteps.sql
GO

:r 052_dbo_IM_InvEntryJobs.sql
GO

:r 053_dbo_IM_JobCorrectionsList.sql
GO

:r 054_dbo_IM_JobItemsOrder.sql
GO

:r 055_dbo_IM_JobsDetailsCategories.sql
GO

:r 056_dbo_IM_JobsParentJobs.sql
GO

:r 057_dbo_IM_PurchaseOrdOrdDetails.sql
GO

:r 058_dbo_IM_PurchReqDetailsGroup.sql
GO

:r 059_dbo_IM_PurchReqGenDocRefPRDetails.sql
GO

:r 060_dbo_IM_PurchReqGenDocRefSuppQuota.sql
GO

:r 061_dbo_IM_PyblsRcvblsJobIncidenceDocs.sql
GO

:r 062_dbo_IM_SuppQuotasDetails.sql
GO

:r 063_dbo_IM_SuppQuotasDetailSummary.sql
GO

:r 064_dbo_IM_SuppQuotasSummary.sql
GO

:r 065_dbo_IM_WorkingReportsWRStat.sql
GO

:r 066_dbo_Lottiw.sql
GO

:r 067_dbo_MA_AvailabilityAnalysis.sql
GO

:r 068_dbo_MA_DepthLevelBOM.sql
GO

:r 069_dbo_MA_InventoryEntriesPhases.sql
GO

:r 070_dbo_MA_ItemsSubstituteFiscalData.sql
GO

:r 071_dbo_MA_JournalEntriesTaxJoin.sql
GO

:r 072_dbo_MA_MasterFor770Form.sql
GO

:r 073_dbo_MA_ProductionDevelopment.sql
GO

:r 074_dbo_MA_SalesStatistics.sql
GO

:r 075_dbo_MA_SalesStatisticsDetailed.sql
GO

:r 076_dbo_MA_SubcontractingDoc.sql
GO

:r 077_dbo_MA_SubcontratorAnalysis.sql
GO

:r 078_dbo_MA_VCrossReferences.sql
GO

:r 079_dbo_MA_VDocumentsToBeInvoiced.sql
GO

:r 080_dbo_MA_VInventoryProfit.sql
GO

:r 081_dbo_MA_VInvEntries.sql
GO

:r 082_dbo_MA_VInvEntriesDetail.sql
GO

:r 083_dbo_MA_VOpenOrders.sql
GO

:r 084_dbo_MA_VPaymentScheduleSplitTax.sql
GO

:r 085_dbo_MA_VReceiptsBatch.sql
GO

:r 086_dbo_MA_VSaleOrdersToDelivered.sql
GO

:r 087_dbo_MA_VTaxDocSendings.sql
GO

:r 088_dbo_MA_VTransactionReport.sql
GO

:r 089_dbo_MA_VWMSaleOrdersPreShipping.sql
GO

:r 090_dbo_MERCE_PRONTA_BRAVO.sql
GO

:r 091_dbo_mp_OrdArtOldItem.sql
GO

:r 092_dbo_mp_QAnalisiArticolo.sql
GO

:r 093_dbo_mp_QVendAgReg.sql
GO

:r 094_dbo_mp_QxMedia12m.sql
GO

:r 095_dbo_mp_VistaOrdXCliente.sql
GO

:r 096_dbo_Ord_Fornitori_Tempo_Evasione.sql
GO

:r 097_dbo_ordforcommesse.sql
GO

:r 098_dbo_PARTITARIO.sql
GO

:r 099_dbo_PARTITARIONEW.sql
GO

:r 100_dbo_saldi_per_gruppo.sql
GO

:r 101_dbo_scadordbase.sql
GO

:r 102_dbo_scadordbase1.sql
GO

:r 103_dbo_scadordbase3.sql
GO

:r 104_dbo_Statistica numero commesse.sql
GO

:r 105_dbo_View_aggiornamentoindirizzimail.sql
GO

:r 106_dbo_VIEW_CODICI_IVA_UTILIZZATI.sql
GO

:r 107_dbo_VIEW_OIKOS_CONTIPERFORNITORE_1.sql
GO

:r 108_dbo_VIEW_OIKOS_CONTIPERFORNITORE2.sql
GO

:r 109_dbo_VIEW_ORDFOR_CENTRI.sql
GO

:r 110_dbo_VIEW_ORDFOR_CENTRI_ORIGINALE.sql
GO

:r 111_dbo_viewavanfatt.sql
GO

:r 112_dbo_Vista_AggposizioneOrdineMovimento.sql
GO

:r 113_dbo_Vista_Basecontrolloordinibollefatt.sql
GO

:r 114_dbo_Vista_BaseUpdatePosOrdine.sql
GO

:r 115_dbo_Vista_Bolle.sql
GO

:r 116_dbo_Vista_controlloddt_fattura.sql
GO

:r 117_dbo_Vista_controlloqtaconsegnata.sql
GO

:r 118_dbo_Vista_costoimballoordini.sql
GO

:r 119_dbo_Vista_ExportFatture.sql
GO

:r 120_dbo_Vista_Fatture.sql
GO

:r 121_dbo_Vista_numero_commesse_anno.sql
GO

:r 122_dbo_Vista_QtaConsegnataCommessa.sql
GO

:r 123_dbo_Vista_Ramdaevadere.sql
GO

:r 124_dbo_Vista_RiferimentiDocVenditaGroup.sql
GO

:r 125_dbo_VistaBaseControlloOrdiniBolle.sql
GO

:r 126_dbo_vistabasevalcostovendita.sql
GO

:r 127_dbo_VistaCostiTotaleAnalitici.sql
GO

:r 128_dbo_VistaDebitiCentrodiCosto.sql
GO

:r 129_dbo_vistaimpegniinentratadaram.sql
GO

:r 130_dbo_VistaIncidenzaCentrodicostoTotale.sql
GO

:r 131_dbo_VistaIncidenzaCostoCentro.sql
GO

:r 132_dbo_Vistaordinidaevadere.sql
GO

:r 133_dbo_vistaperbilanciodimagazzino_corretta.sql
GO

:r 134_dbo_vistaperbilanciomagazzino.sql
GO

:r 135_dbo_vistaperbilanciomagazzino_07092017.sql
GO

:r 136_dbo_vistaperbilanciomagazzino_12122018.sql
GO

:r 137_dbo_vistaperbilanciomagazzino_30052017.sql
GO

:r 138_dbo_vistaperbilanciomagazzinox.sql
GO

:r 139_dbo_vistapermercepronta.sql
GO

:r 140_dbo_VistaQtaConsegnatePerCommessaPosizione.sql
GO

:r 141_dbo_vistarigheoforep.sql
GO

:r 142_dbo_VistaVendite.sql
GO

:r 143_dbo_VwIxW_OffForCont.sql
GO

:r 144_dbo_VwIxW_OffForRighe.sql
GO

:r 145_dbo_VwIxW_OrdForCom.sql
GO

:r 146_dbo_VwIxWMovMagPerCommEDep.sql
GO

:r 147_dbo_WIEW_LISTAFATTURATOPERDIVISIONE.sql
GO

