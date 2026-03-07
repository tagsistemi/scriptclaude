# Tabelle svuotate su VEDMaster

Elenco completo di tutte le tabelle che vengono svuotate (DELETE/TRUNCATE) su VEDMaster durante il processo di migrazione, raggruppate per script di trasferimento.

> **Nota:** Tutte le operazioni (tranne DDT che filtra per `DocumentType`) eseguono un DELETE completo e poi reinseriscono i dati solo dai database clone. I dati originali di vedcontab sopravvivono solo se la tabella **non è presente** in nessuno di questi script.

---

## 1. SvuotaVedmaster.ps1 — Pulizia iniziale (32 tabelle)

Tabelle `IM_*` relative a commesse, svuotate prima dell'inizio della migrazione.

| # | Tabella |
|---|---------|
| 1 | IM_JobsBalance |
| 2 | IM_JobsCostsRevenuesSummary |
| 3 | IM_JobsNotes |
| 4 | IM_JobsSections |
| 5 | IM_JobsWorkingStep |
| 6 | IM_JobsComponents |
| 7 | IM_JobsDetails |
| 8 | IM_JobsDetailsVCL |
| 9 | IM_JobsDocuments |
| 10 | IM_JobsHistoryStates |
| 11 | IM_JobsWithholdingTax |
| 12 | IM_JobsTaxSummary |
| 13 | IM_JobsSummary |
| 14 | IM_JobsSummaryByCompType |
| 15 | IM_JobsSummaryByCompTypeByWorkingStep |
| 16 | IM_JobsStatOfAccount |
| 17 | MA_Jobs |
| 18 | IM_WorkingReportsDetails |
| 19 | IM_WorkingReports |
| 20 | IM_WorksProgressReport |
| 21 | IM_WPRDetails |
| 22 | IM_MeasuresBooksDetails |
| 23 | IM_MeasuresBooks |
| 24 | IM_SpecificationsItems |
| 25 | IM_Specifications |
| 26 | IM_DeliveryReqDetails |
| 27 | IM_DeliveryRequest |
| 28 | IM_SubcontractOrdDetails |
| 29 | IM_SubcontractOrd |
| 30 | IM_SubcontractQuotasDetails |
| 31 | IM_SubcontractWorksProgressReport |
| 32 | IM_SubcontractWPRDetails |

---

## 2. 00_MasterMigrazione.ps1 (fase 8.10) — Pulizia articoli (18 tabelle)

DELETE con `WHERE Item IN (SELECT Item FROM ma_items)`, tranne le ultime 3 che sono DELETE completi.

| # | Tabella | Tipo DELETE |
|---|---------|-------------|
| 1 | MA_ItemsWMSZones | Condizionale (WHERE Item IN ...) |
| 2 | MA_ItemsLIFO | Condizionale |
| 3 | MA_ItemsKit | Condizionale |
| 4 | MA_ItemsFIFO | Condizionale |
| 5 | MA_ItemsStorageQtyMonthly | Condizionale |
| 6 | MA_ItemsLIFODomCurr | Condizionale |
| 7 | MA_ItemsManufacturingData | Condizionale |
| 8 | MA_ItemsFIFODomCurr | Condizionale |
| 9 | MA_ItemsIntrastat | Condizionale |
| 10 | MA_ItemNotes | Condizionale |
| 11 | MA_ItemsPurchaseBarCode | Condizionale |
| 12 | MA_ItemsLanguageDescri | Condizionale |
| 13 | MA_ItemsSubstitute | Condizionale |
| 14 | MA_StandardCostHistorical | Condizionale |
| 15 | MA_ItemsComparableUoM | Condizionale |
| 16 | MA_ItemCustomers | Completo |
| 17 | MA_ItemSuppliers | Completo |
| 18 | MA_Items | Completo |

---

## 3. Migrate-ItemsData.ps1 (Articoli) — 35 tabelle

Script: `MigrazioneSottoinsiemeArticoli\Migrate-ItemsData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_UnitsOfMeasure |
| 2 | MA_UnitOfMeasureDetail |
| 3 | MA_ProductCtg |
| 4 | MA_ProductCtgSubCtg |
| 5 | MA_ProductSubCtgDefaults |
| 6 | MA_CommodityCtg |
| 7 | MA_CommodityCtgBudget |
| 8 | MA_CommodityCtgCustomers |
| 9 | MA_CommodityCtgCustomersBudget |
| 10 | MA_CommodityCtgCustomersCtg |
| 11 | MA_CommodityCtgSuppliers |
| 12 | MA_CommodityCtgSuppliersCtg |
| 13 | MA_HomogeneousCtg |
| 14 | MA_HomogeneousCtgBudget |
| 15 | MA_ItemTypes |
| 16 | MA_ItemTypeCustomers |
| 17 | MA_ItemTypeCustomersBudget |
| 18 | MA_ItemTypeSuppliers |
| 19 | MA_ItemTypeBudget |
| 20 | MA_Producers |
| 21 | MA_ProducersCategories |
| 22 | MA_Departments |
| 23 | MA_Items |
| 24 | MA_ItemsGoodsData |
| 25 | MA_ItemsIntrastat |
| 26 | MA_ItemsManufacturingData |
| 27 | MA_ItemsComparableUoM |
| 28 | MA_ItemsSubstitute |
| 29 | MA_ItemsPurchaseBarCode |
| 30 | MA_ItemsLanguageDescri |
| 31 | MA_ItemsKit |
| 32 | MA_ItemCustomers |
| 33 | MA_ItemCustomersBudget |
| 34 | MA_ItemSuppliers |
| 35 | MA_ItemSuppliersOperations |
| 36 | MA_ItemNotes |

---

## 4. Migrate-PurchaseData.ps1 (Acquisti) — 8 tabelle

Script: `MigrazioneSottoinsiemeAcquisti\Migrate-PurchaseData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_PurchaseDoc |
| 2 | MA_PurchaseDocDetail |
| 3 | MA_PurchaseDocNotes |
| 4 | MA_PurchaseDocPymtSched |
| 5 | MA_PurchaseDocReferences |
| 6 | MA_PurchaseDocShrinking |
| 7 | MA_PurchaseDocSummary |
| 8 | MA_PurchaseDocTaxSummary |

---

## 5. Migrate-ItemsData.ps1 (DDT) — 3 tabelle (DELETE condizionale)

Script: `MigrazioneSottoinsiemeDdt\Migrate-ItemsData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone
**DELETE con `WHERE DocumentType = 3407873`** (solo DDT)

| # | Tabella |
|---|---------|
| 1 | MA_SaleDoc |
| 2 | MA_SaleDocDetail |
| 3 | MA_SaleDocReferences |

---

## 6. Migrate-SaleOrdData.ps1 (Ordini Cliente) — 10 tabelle

Script: `MigrazioneSottoinsiemeOrdiniCliente\Migrate-SaleOrdData.ps1`
Sorgenti: gpxnet, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_SaleOrd |
| 2 | MA_SaleOrdAllocationPriority |
| 3 | MA_SaleOrdComponents |
| 4 | MA_SaleOrdDetails |
| 5 | MA_SaleOrdNotes |
| 6 | MA_SaleOrdPymtSched |
| 7 | MA_SaleOrdReferences |
| 8 | MA_SaleOrdShipping |
| 9 | MA_SaleOrdSummary |
| 10 | MA_SaleOrdTaxSummary |

---

## 7. Migrate-PurchaseOrdData.ps1 (Ordini Fornitore) — 10 tabelle

Script: `MigrazioneSottoinsiemeOrdiniFornitore\Migrate-PurchaseOrdData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_PurchaseOrd |
| 2 | MA_PurchaseOrdDefaults |
| 3 | MA_PurchaseOrdDetails |
| 4 | MA_PurchaseOrdNotes |
| 5 | MA_PurchaseOrdParameters |
| 6 | MA_PurchaseOrdPymtSched |
| 7 | MA_PurchaseOrdReferences |
| 8 | MA_PurchaseOrdShipping |
| 9 | MA_PurchaseOrdSummary |
| 10 | MA_PurchaseOrdTaxSummay |

---

## 8. Migrate-CustQuotasData.ps1 (Offerte Cliente) — 7 tabelle

Script: `MigrazioneSottoinsiemeOfferteCliente\Migrate-CustQuotasData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_CustQuotas |
| 2 | MA_CustQuotasDetail |
| 3 | MA_CustQuotasNote |
| 4 | MA_CustQuotasReference |
| 5 | MA_CustQuotasShipping |
| 6 | MA_CustQuotasSummary |
| 7 | MA_CustQuotasTaxSummary |

---

## 9. Migrate-SuppQuotasData.ps1 (Offerte Fornitore) — 6 tabelle

Script: `MigrazioneSottoinsiemeOfferteFornitore\Migrate-SuppQuotasData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_SuppQuotas |
| 2 | MA_SuppQuotasDetail |
| 3 | MA_SuppQuotasNote |
| 4 | MA_SuppQuotasReference |
| 5 | MA_SuppQuotasShipping |
| 6 | MA_SuppQuotasTaxSummary |

---

## 10. Migrate-StockData.ps1 (Magazzino) — 8 tabelle

Script: `MigrazioneSottoinsiemeMagazzino\Migrate-StockData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

> **Nota:** MA_CostAccEntries e MA_CostAccEntriesDetail sono state rimosse da questo script per preservare i dati originali di vedcontab.

| # | Tabella |
|---|---------|
| 1 | MA_InventoryReasons |
| 2 | MA_ReceiptsBatch |
| 3 | MA_FixAssetEntries |
| 4 | MA_FixAssetEntriesDetail |
| 5 | MA_ItemsFiscalData |
| 6 | MA_ItemsMonthlyBalances |
| 7 | MA_InventoryEntries |
| 8 | MA_InventoryEntriesDetail |

---

## 11. Migrate-JobsData.ps1 (Commesse) — 4 tabelle

Script: `MigrazioneSottoinsiemeComesse\Migrate-JobsData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_JobGroups |
| 2 | MA_JobsParameters |
| 3 | MA_Jobs |
| 4 | MA_JobsBalances |

---

## 12. Migrate-PerfettoData.ps1 (Perfetto01) — 18 tabelle

Script: `MigrazioneSottoinsiemePerfetto01\Migrate-PerfettoData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | IM_JobCorrections |
| 2 | IM_JobCorrectionsDetails |
| 3 | IM_JobsNumbers |
| 4 | IM_JobsSections |
| 5 | IM_JobsItems |
| 6 | IM_JobsDetails |
| 7 | IM_JobsDetailsVCL |
| 8 | IM_JobsWorkingStep |
| 9 | IM_JobsDocuments |
| 10 | IM_JobsBalance |
| 11 | IM_JobsSummary |
| 12 | IM_JobsSummaryByCompType |
| 13 | IM_JobsSummaryByCompTypeByWorkingStep |
| 14 | IM_JobsCostsRevenuesSummary |
| 15 | IM_JobsTaxSummary |
| 16 | IM_JobsWithholdingTax |
| 17 | IM_JobsNotes |

---

## 13. Migrate-ItemsData.ps1 (Perfetto02) — 28 tabelle

Script: `MigrazioneSottoinsiemePerfetto02\Migrate-ItemsData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | IM_JobQuotations |
| 2 | IM_JobQuotationsGroups |
| 3 | IM_JobQuotasNumbers |
| 4 | IM_JobQuotasSections |
| 5 | IM_JobQuotasWorkingStep |
| 6 | IM_JobQuotasDetails |
| 7 | IM_JobQuotasDetailsVCL |
| 8 | IM_JobQuotasAddCharges |
| 9 | IM_JobQuotasDocuments |
| 10 | IM_JobQuotasSummary |
| 11 | IM_JobQuotasSummByCompType |
| 12 | IM_JobQuotasSummByCompTypeByWorkingStep |
| 13 | IM_JobQuotasTaxSummary |
| 14 | IM_Specifications |
| 15 | IM_SpecificationsItems |
| 16 | IM_WorkingReports |
| 17 | IM_WorkingReportsDetails |
| 18 | IM_WPRDetails |
| 19 | IM_MeasuresBooks |
| 20 | IM_MeasuresBooksDetails |
| 21 | IM_DeliveryRequest |
| 22 | IM_DeliveryReqDetails |
| 23 | IM_SubcontractOrd |
| 24 | IM_SubcontractOrdDetails |
| 25 | IM_SubcontractQuotasDetails |
| 26 | IM_SubcontractWorksProgressReport |
| 27 | IM_SubcontractWPRDetails |
| 28 | IM_WorksProgressReport |

---

## 14. Migrate-LotsData.ps1 (Lotti) — 9 tabelle

Script: `MigrazioneSottoinsiemeLotti\Migrate-LotsData.ps1`
Sorgente: vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_LotSerialParameters |
| 2 | MA_LotsNumbers |
| 3 | MA_Lots |
| 4 | MA_SerialNumbers |
| 5 | MA_LotsStoragesQty |
| 6 | MA_LotsStoragesQtyMonthly |
| 7 | MA_LotsMonthly |
| 8 | MA_LotsTracing |
| 9 | MA_TmpLotsTracing |

---

## 15. Migrate-ItemsData.ps1 (Multistorages) — 4 tabelle

Script: `MigrazioneSottoinsiemeMultistorages\Migrate-ItemsData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_StorageGroups |
| 2 | MA_Storages |
| 3 | MA_ItemsStorageQty |
| 4 | MA_ItemsStorageQtyMonthly |

---

## 16. Migrate-ItemsData.ps1 (Employees) — 3 tabelle

Script: `MigrazioneSottoinsiemeEmployees\Migrate-ItemsData.ps1`
Sorgenti: gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | IM_Employees |
| 2 | IM_EmployeesAnnual |
| 3 | IM_EmployeesNotes |

---

## 17. Migrate-GpxData.ps1 (Tabelle custom GPX) — 6 tabelle

Script: `MigrazioneSottoinsiemeGpx\Migrate-GpxData.ps1`
Sorgente: gpxnet

| # | Tabella |
|---|---------|
| 1 | gpx_parametri |
| 2 | gpx_parametririghe |
| 3 | gpx_testaram |
| 4 | gpx_righeram |
| 5 | gpx_righemp |
| 6 | gpx_saledocram |

---

## 18. Migrate-CrossReferencesData.ps1 — 1 tabella

Script: `MigrazioneSottoinsiemeCrossReferences\Migrate-CrossReferencesData.ps1`
Sorgenti: vedcontab, gpxnetclone, furmanetclone, vedbondifeclone

| # | Tabella |
|---|---------|
| 1 | MA_CrossReferences |

---

## Riepilogo

| Script | Ambito | N. Tabelle | Tipo DELETE |
|--------|--------|------------|-------------|
| SvuotaVedmaster.ps1 | Pulizia iniziale commesse | 32 | Completo |
| 00_MasterMigrazione.ps1 (8.10) | Articoli vedmaster | 18 | Condizionale / Completo |
| Migrate-ItemsData.ps1 (Articoli) | Anagrafiche articoli | 35 | Completo |
| Migrate-PurchaseData.ps1 | Documenti acquisto | 8 | Completo |
| Migrate-ItemsData.ps1 (DDT) | DDT vendita | 3 | Condizionale (DocumentType) |
| Migrate-SaleOrdData.ps1 | Ordini cliente | 10 | Completo |
| Migrate-PurchaseOrdData.ps1 | Ordini fornitore | 10 | Completo |
| Migrate-CustQuotasData.ps1 | Offerte cliente | 7 | Completo |
| Migrate-SuppQuotasData.ps1 | Offerte fornitore | 6 | Completo |
| Migrate-StockData.ps1 | Magazzino | 8 | Completo |
| Migrate-JobsData.ps1 | Commesse | 4 | Completo |
| Migrate-PerfettoData.ps1 | Perfetto01 | 18 | Completo |
| Migrate-ItemsData.ps1 (Perfetto02) | Perfetto02 | 28 | Completo |
| Migrate-LotsData.ps1 | Lotti | 9 | Completo |
| Migrate-ItemsData.ps1 (Multistorages) | Depositi multipli | 4 | Completo |
| Migrate-ItemsData.ps1 (Employees) | Dipendenti | 3 | Completo |
| Migrate-GpxData.ps1 | Tabelle custom GPX | 6 | Completo |
| Migrate-CrossReferencesData.ps1 | Cross references | 1 | Completo |
| **TOTALE** | | **~210** | |
