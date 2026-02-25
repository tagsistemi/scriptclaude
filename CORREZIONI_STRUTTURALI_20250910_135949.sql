-- SCRIPT CORREZIONI STRUTTURALI
-- Generato automaticamente

-- Correzione per IM_WorksProgressReport
TRUNCATE TABLE [VEDMaster].dbo.[IM_WorksProgressReport]
GO

INSERT INTO [VEDMaster].dbo.[IM_WorksProgressReport] (WPRId, WPRNo, Description, Job, CreationDate, Note, Invoiced, GeneratedDocType, TotalAmount, CollectedTotalAmount, WithholdingTaxTotalAmount, CollectingTotalAmount, WithholdingTaxTaxableAmount, InvoicingTaxableAmount, TaxTotalAmount, InvoiceTotalAmount, InvoiceId, TaxCode, Offset, TaxJournal, AccTpl, Payment, InvoiceDescriptionLine1, InvoiceDescriptionLine2, InvoiceDescriptionLine3, Currency, FixingDate, Fixing, FixingIsManual, TaxableAmountDocCurr, TaxAmountDocCurr, InvoicedTotalAmountBaseCurr, CollectingTotalAmountBaseCurr, DiscountFormula, Discount1, Discount2, DiscountedTotalAmount, ParentJobTotalAmount, VariantJobTotalAmount, OATAMBJobTotalAmount, InvoiceWillNotFollow, EnablesRowChange, TBCreated, TBModified, TBCreatedID, TBModifiedID, InvoicePreviewDate, TBGuid)
SELECT WPRId, WPRNo, Description, Job, CreationDate, Note, Invoiced, GeneratedDocType, TotalAmount, CollectedTotalAmount, WithholdingTaxTotalAmount, CollectingTotalAmount, WithholdingTaxTaxableAmount, InvoicingTaxableAmount, TaxTotalAmount, InvoiceTotalAmount, InvoiceId, TaxCode, Offset, TaxJournal, AccTpl, Payment, InvoiceDescriptionLine1, InvoiceDescriptionLine2, InvoiceDescriptionLine3, Currency, FixingDate, Fixing, FixingIsManual, TaxableAmountDocCurr, TaxAmountDocCurr, InvoicedTotalAmountBaseCurr, CollectingTotalAmountBaseCurr, DiscountFormula, Discount1, Discount2, DiscountedTotalAmount, ParentJobTotalAmount, VariantJobTotalAmount, OATAMBJobTotalAmount, InvoiceWillNotFollow, EnablesRowChange, TBCreated, TBModified, TBCreatedID, TBModifiedID, InvoicePreviewDate, TBGuid
FROM [gpxnetclone].dbo.[IM_WorksProgressReport]
GO

-- Correzione per IM_WorkingReports
TRUNCATE TABLE [VEDMaster].dbo.[IM_WorkingReports]
GO

INSERT INTO [VEDMaster].dbo.[IM_WorkingReports] (WorkingReportId, WorkingReportNo, WorkingReportDate, PostingDate, Customer, Payment, PostedToAccounting, Issued, Posted, Printed, InvoiceFollows, WRReason, StubBook, Job, PostedToCostAccounting, WorkingReportType, LabourHourlyRate, CallServiceCost, DNId, DNNo, PriceList, CustomerBank, CompanyBank, AccTpl, TaxJournal, CallService, Labour, Description, InvRsn, StorageStubBook, StoragePhase1, StoragePhase2, SpecificatorPhase1, SpecificatorPhase2, SaleDocGenerated, PostedToInventory, EntryId, BalanceFromEmployeesTab, BalanceFromActualitiesTab, Currency, FixingDate, Fixing, FixingIsManual, WorkingReportTypology, Employee, Qualification, TBCreated, TBModified, TBCreatedID, TBModifiedID, Centro, Cantiere, ExternalReference, TBGuid, Status, SourceCreated, SourceModified, SentByEMail)
SELECT WorkingReportId, WorkingReportNo, WorkingReportDate, PostingDate, Customer, Payment, PostedToAccounting, Issued, Posted, Printed, InvoiceFollows, WRReason, StubBook, Job, PostedToCostAccounting, WorkingReportType, LabourHourlyRate, CallServiceCost, DNId, DNNo, PriceList, CustomerBank, CompanyBank, AccTpl, TaxJournal, CallService, Labour, Description, InvRsn, StorageStubBook, StoragePhase1, StoragePhase2, SpecificatorPhase1, SpecificatorPhase2, SaleDocGenerated, PostedToInventory, EntryId, BalanceFromEmployeesTab, BalanceFromActualitiesTab, Currency, FixingDate, Fixing, FixingIsManual, WorkingReportTypology, Employee, Qualification, TBCreated, TBModified, TBCreatedID, TBModifiedID, NULL as Centro, NULL as Cantiere, ExternalReference, TBGuid, Status, SourceCreated, SourceModified, SentByEMail
FROM [gpxnetclone].dbo.[IM_WorkingReports]
GO

-- Correzione per IM_WorkingReportsDetails
TRUNCATE TABLE [VEDMaster].dbo.[IM_WorkingReportsDetails]
GO

INSERT INTO [VEDMaster].dbo.[IM_WorkingReportsDetails] (WorkingReportId, Line, Employee, Name, OrdinaryHours, OvertimeHours, TravelHours, Customer, VacationLeaveHours, SickLeaveHours, TotalHours, Job, WorkingReportDate, WorkingReportNo, Qualification, EmployeeCost, OrdinaryCost, OvertimeCost, TravelCost, VacationLeaveCost, SickLeaveCost, CustomCost1, CustomCost2, CustomCost3, CustomCost4, TotalCustomCost, CustomHours1, CustomHours2, CustomHours3, CustomHours4, TotalCustomHours, Note, IsOnJobEconomicAnalysis, StartHour, EndHour, WorkingStep, PostedToAccounting, TBCreated, TBModified, TBCreatedID, TBModifiedID, CRRefType, CRRefID, CRRefLine)
SELECT WorkingReportId, Line, Employee, Name, OrdinaryHours, OvertimeHours, TravelHours, Customer, VacationLeaveHours, SickLeaveHours, TotalHours, Job, WorkingReportDate, WorkingReportNo, Qualification, EmployeeCost, OrdinaryCost, OvertimeCost, TravelCost, VacationLeaveCost, SickLeaveCost, CustomCost1, CustomCost2, CustomCost3, CustomCost4, TotalCustomCost, CustomHours1, CustomHours2, CustomHours3, CustomHours4, TotalCustomHours, Note, IsOnJobEconomicAnalysis, StartHour, EndHour, WorkingStep, PostedToAccounting, TBCreated, TBModified, TBCreatedID, TBModifiedID, CRRefType, CRRefID, CRRefLine
FROM [gpxnetclone].dbo.[IM_WorkingReportsDetails]
GO

-- Correzione per IM_WPRDetails
TRUNCATE TABLE [VEDMaster].dbo.[IM_WPRDetails]
GO

INSERT INTO [VEDMaster].dbo.[IM_WPRDetails] (WPRId, Line, Job, ParentJob, JobLineId, UoM, InstalledQty, UnitValue, Amount, Specification, SpecificationItem, ComponentType, Component, Description, ShortDescription, ProgressConfirmingMode, Section, JobQty, JobLineValue, ProgressPerc, DetailedQty, AdditionalQty1, AdditionalQty2, AdditionalQty3, AdditionalQty4, MeasuresBookId, MeasuresBookNo, TreeData, LineFromMeasuresBookDetails, FullDescription, TBCreated, TBModified, TBCreatedID, TBModifiedID, CRRefType, CRRefID, CRRefSubID)
SELECT WPRId, Line, Job, ParentJob, JobLineId, UoM, InstalledQty, UnitValue, Amount, Specification, SpecificationItem, ComponentType, Component, Description, ShortDescription, ProgressConfirmingMode, Section, JobQty, JobLineValue, ProgressPerc, DetailedQty, AdditionalQty1, AdditionalQty2, AdditionalQty3, AdditionalQty4, MeasuresBookId, MeasuresBookNo, TreeData, LineFromMeasuresBookDetails, FullDescription, TBCreated, TBModified, TBCreatedID, TBModifiedID, CRRefType, CRRefID, CRRefSubID
FROM [gpxnetclone].dbo.[IM_WPRDetails]
GO

-- Correzione per IM_MeasuresBooks
TRUNCATE TABLE [VEDMaster].dbo.[IM_MeasuresBooks]
GO

INSERT INTO [VEDMaster].dbo.[IM_MeasuresBooks] (MeasuresBookId, MeasuresBookNo, Description, AlreadyInWPR, CreationDate, Job, ParentJob, Note, Approval, ApprovalDate, ApprovalBy, Currency, FixingDate, Fixing, FixingIsManual, MeasuresBookType, AccrualDate, Disabled, EnablesRowChange, TBCreated, TBModified, TBCreatedID, TBModifiedID, CRRefType, CRRefID, TBGuid)
SELECT MeasuresBookId, MeasuresBookNo, Description, AlreadyInWPR, CreationDate, Job, ParentJob, Note, Approval, ApprovalDate, ApprovalBy, Currency, FixingDate, Fixing, FixingIsManual, MeasuresBookType, AccrualDate, Disabled, EnablesRowChange, TBCreated, TBModified, TBCreatedID, TBModifiedID, CRRefType, CRRefID, TBGuid
FROM [gpxnetclone].dbo.[IM_MeasuresBooks]
GO

-- Correzione per IM_Specifications
TRUNCATE TABLE [VEDMaster].dbo.[IM_Specifications]
GO

INSERT INTO [VEDMaster].dbo.[IM_Specifications] (Specification, Description, Disabled, Version, TBCreated, TBModified, TBCreatedID, TBModifiedID, LenSegmenti, Segmenti, Separatore, Filler)
SELECT Specification, Description, Disabled, Version, TBCreated, TBModified, TBCreatedID, TBModifiedID, NULL as LenSegmenti, NULL as Segmenti, NULL as Separatore, NULL as Filler
FROM [gpxnetclone].dbo.[IM_Specifications]
GO

-- Correzione per IM_SpecificationsItems
TRUNCATE TABLE [VEDMaster].dbo.[IM_SpecificationsItems]
GO

INSERT INTO [VEDMaster].dbo.[IM_SpecificationsItems] (Specification, Item, UoM, ParentItem, Price, Time, Title, ShortDescription, FullDescription, Line, Priority, TreeData, Level, ParentLine, LineType, CLForItem, Qty, TBCreated, TBModified, TBCreatedID, TBModifiedID)
SELECT Specification, Item, UoM, ParentItem, Price, Time, Title, ShortDescription, FullDescription, Line, Priority, TreeData, Level, ParentLine, LineType, CLForItem, Qty, TBCreated, TBModified, TBCreatedID, TBModifiedID
FROM [furmanetclone].dbo.[IM_SpecificationsItems]
GO

-- Correzione per IM_JobQuotations
TRUNCATE TABLE [VEDMaster].dbo.[IM_JobQuotations]
GO

INSERT INTO [VEDMaster].dbo.[IM_JobQuotations] (JobQuotationId, Customer, JobQuotationNo, QuotationReference, CreationDate, HourlyRate, MarkupPerc, Specification, ValidityEndingDate, Contact, UseContact, LabourMarkup, UseSpecificationPrice, Description, Storage, ExpectedStartingDate, ExpectedEndingDate, WorksEndingDate, Simulation, SimDate, SimPurchaseRequestNo, SimPurchaseRequestId, OriginalJobQuotationId, TaxCode, Payment, CustomerBank, CompanyBank, CompanyCurrentAccount, Presentation, Language, PriceList, SendDocumentsTo, SendPaymentsTo, NetOfTax, SalesPerson, Currency, FixingDate, Fixing, FixingIsManual, UnitValueIsCalculated, QuotationRequestId, UseSpecificationQty, JobQuotaRevNo, JobQuotaFinal, JobQuotaParentId, EmployeeReference, JobReference, JobQuotaPreferentialRev, JobQuotaStatus, TBCreated, TBModified, TBCreatedID, TBModifiedID, Analisi, AcceptanceDate, AcquireProbabilityDate, AcquireProbabilityPerc, CRRefType, CRRefID, TBGuid, JobQuotationGroup, JobGroup)
SELECT JobQuotationId, Customer, JobQuotationNo, QuotationReference, CreationDate, HourlyRate, MarkupPerc, Specification, ValidityEndingDate, Contact, UseContact, LabourMarkup, UseSpecificationPrice, Description, Storage, ExpectedStartingDate, ExpectedEndingDate, WorksEndingDate, Simulation, SimDate, SimPurchaseRequestNo, SimPurchaseRequestId, OriginalJobQuotationId, TaxCode, Payment, CustomerBank, CompanyBank, CompanyCurrentAccount, Presentation, Language, PriceList, SendDocumentsTo, SendPaymentsTo, NetOfTax, SalesPerson, Currency, FixingDate, Fixing, FixingIsManual, UnitValueIsCalculated, QuotationRequestId, UseSpecificationQty, JobQuotaRevNo, JobQuotaFinal, JobQuotaParentId, EmployeeReference, JobReference, JobQuotaPreferentialRev, JobQuotaStatus, TBCreated, TBModified, TBCreatedID, TBModifiedID, NULL as Analisi, AcceptanceDate, AcquireProbabilityDate, AcquireProbabilityPerc, CRRefType, CRRefID, TBGuid, JobQuotationGroup, JobGroup
FROM [gpxnetclone].dbo.[IM_JobQuotations]
GO

-- Correzione per IM_JobQuotasDetails
TRUNCATE TABLE [VEDMaster].dbo.[IM_JobQuotasDetails]
GO

INSERT INTO [VEDMaster].dbo.[IM_JobQuotasDetails] (JobQuotationId, Section, Line, ComponentType, Component, BaseUoM, Description, Quantity, UnitTime, TotalTime, FunctionalCtg, Specification, SpecificationItem, IsAVariableCL, BlockTimeVCL, GoodsCost, LabourCost, ComponentPrice, QuotedTotalAmount, GoodsCostTotalAmount, GoodsMarkupPerc, CanBeUpdated, HourlyRate, Position, ExpensesAmount, ExpensesIncidence, GoodsValue, ShortDescription, FullDescription, LabourMarkupPerc, QuotedPrice, SpecificationPrice, Variance, VariancePerc, LabourUnitCost, BaseCost, FitCostFormula, FitCostPerc1, FitCostPerc2, AccessoriesCostPerc, AccessoriesCostValue, FitCost, UnitCost, CostTotalAmount, MarkupFormula, MarkupPerc1, MarkupPerc2, MarkupValue, UnitValue, DiscountFormula, Discount1, Discount2, DiscountAmount, TaxableAmount, TotalAmount, Performance, TaxCode, AdditionalQty1, AdditionalQty2, AdditionalQty3, AdditionalQty4, UnitValueIsCalculated, MarkupIsOnCharges, CostingType, DistributedDiscount, DiscountedValue, ExternalReference, WorkingStep, FormulaId, ToBeChecked, NoteVCL, TBCreated, TBModified, TBCreatedID, TBModifiedID, SubcontractQuotaId, SubcontractSupplier, CLUnitTime, FixedUnitTime, CLBaseCost, FixedBaseCost, CLAccessoriesCostValue, FixedAccessoriesCostValue, CLFitCost, FixedFitCost, CLUnitCost, CLUnitValue, FixedUnitValue)
SELECT JobQuotationId, Section, Line, ComponentType, Component, BaseUoM, Description, Quantity, UnitTime, TotalTime, FunctionalCtg, Specification, SpecificationItem, IsAVariableCL, BlockTimeVCL, GoodsCost, LabourCost, ComponentPrice, QuotedTotalAmount, GoodsCostTotalAmount, GoodsMarkupPerc, CanBeUpdated, HourlyRate, Position, ExpensesAmount, ExpensesIncidence, GoodsValue, ShortDescription, FullDescription, LabourMarkupPerc, QuotedPrice, SpecificationPrice, Variance, VariancePerc, LabourUnitCost, BaseCost, FitCostFormula, FitCostPerc1, FitCostPerc2, AccessoriesCostPerc, AccessoriesCostValue, FitCost, UnitCost, CostTotalAmount, MarkupFormula, MarkupPerc1, MarkupPerc2, MarkupValue, UnitValue, DiscountFormula, Discount1, Discount2, DiscountAmount, TaxableAmount, TotalAmount, Performance, TaxCode, AdditionalQty1, AdditionalQty2, AdditionalQty3, AdditionalQty4, UnitValueIsCalculated, MarkupIsOnCharges, CostingType, DistributedDiscount, DiscountedValue, ExternalReference, WorkingStep, FormulaId, ToBeChecked, NoteVCL, TBCreated, TBModified, TBCreatedID, TBModifiedID, SubcontractQuotaId, SubcontractSupplier, CLUnitTime, FixedUnitTime, CLBaseCost, FixedBaseCost, CLAccessoriesCostValue, FixedAccessoriesCostValue, CLFitCost, FixedFitCost, CLUnitCost, CLUnitValue, FixedUnitValue
FROM [gpxnetclone].dbo.[IM_JobQuotasDetails]
GO

-- Correzione per IM_JobQuotasSummary
TRUNCATE TABLE [VEDMaster].dbo.[IM_JobQuotasSummary]
GO

INSERT INTO [VEDMaster].dbo.[IM_JobQuotasSummary] (JobQuotationId, AuctionBase, Decrease, DecreasePerc, LabourTotalAmount, ExpensesTotalAmount, TotalTime, GoodsTotalAmount, TaxableAmount, DistributedExpTotAmount, UndistributableExpTotAmount, DistributableExpTotAmount, SpecificationTotalAmount, QuotedTotalAmount, TaxAmount, TotalAmount, GoodsMarkupFormula, LabourMarkupFormula, ServicesMarkupFormula, ChargesMarkupFormula, OtherMarkupFormula, QuotedTotalAmountDocCurr, TotalAmountDocCurr, FreeSamplesDocCurr, TaxableAmountDocCurr, TaxAmountDocCurr, StampsCharges, CollectionCharges, FreeSamplesTotalAmount, PackagingCharges, ShippingCharges, AdditionalCharges, AllowancesTotalAmount, TotalAmountBaseCurr, AdvancesTotalAmount, GoodsDiscountTotalAmount, ServicesDiscountTotalAmount, CashOnDeliveryPerc, CashOnDeliveryCharges, PriceTotalAmount, TaxableTotalAmount, TaxChargedTotalAmount, FurtherDiscountFormula, FurtherDiscount1, FurtherDiscount2, DetailsDiscountTotalAmount, FurtherDiscountTotalAmount, DiscountTotalAmount, CostsTotalAmount, ProceedsTotalAmount, PerformanceTotalAmount, TaxNotApplied, TaxCode, FurtherDiscountIsAutomatic, TBCreated, TBModified, TBCreatedID, TBModifiedID, UseMethodPrefTaxCode)
SELECT JobQuotationId, AuctionBase, Decrease, DecreasePerc, LabourTotalAmount, ExpensesTotalAmount, TotalTime, GoodsTotalAmount, TaxableAmount, DistributedExpTotAmount, UndistributableExpTotAmount, DistributableExpTotAmount, SpecificationTotalAmount, QuotedTotalAmount, TaxAmount, TotalAmount, GoodsMarkupFormula, LabourMarkupFormula, ServicesMarkupFormula, ChargesMarkupFormula, OtherMarkupFormula, QuotedTotalAmountDocCurr, TotalAmountDocCurr, FreeSamplesDocCurr, TaxableAmountDocCurr, TaxAmountDocCurr, StampsCharges, CollectionCharges, FreeSamplesTotalAmount, PackagingCharges, ShippingCharges, AdditionalCharges, AllowancesTotalAmount, TotalAmountBaseCurr, AdvancesTotalAmount, GoodsDiscountTotalAmount, ServicesDiscountTotalAmount, CashOnDeliveryPerc, CashOnDeliveryCharges, PriceTotalAmount, TaxableTotalAmount, TaxChargedTotalAmount, FurtherDiscountFormula, FurtherDiscount1, FurtherDiscount2, DetailsDiscountTotalAmount, FurtherDiscountTotalAmount, DiscountTotalAmount, CostsTotalAmount, ProceedsTotalAmount, PerformanceTotalAmount, TaxNotApplied, TaxCode, FurtherDiscountIsAutomatic, TBCreated, TBModified, TBCreatedID, TBModifiedID, UseMethodPrefTaxCode
FROM [gpxnetclone].dbo.[IM_JobQuotasSummary]
GO

