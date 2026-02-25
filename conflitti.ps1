# Import SQL Server module
#Import-Module SqlServer

# Connessione SQL Server parameters
$ServerName = "192.168.0.3\SQL2008"
$DatabaseName = "VedMaster"
$SourceDatabases = @("VEDBondife", "VEDCONTAB", "FurmaNet", "gpxnet")
$Username = "sa"
$Password = "stream"

# Creare la stringa di connessione
$ConnectionString = "Server=$ServerName;Database=$DatabaseName;User Id=$Username;Password=$Password;"

# SQL per creare le tabelle
$SqlQuery = @"
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_MA_Jobs]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_MA_Jobs]
    PRINT 'Tabella MM4_MA_Jobs eliminata.'
END
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_Employees]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_Employees]
    PRINT 'Tabella MM4_IM_Employees eliminata.'
END
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_ComponentsLists]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_ComponentsLists]
    PRINT 'Tabella MM4_IM_ComponentsLists eliminata.'
END
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_Specifications]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_Specifications]
    PRINT 'Tabella MM4_IM_Specifications eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_QuotationRequests]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_QuotationRequests]
    PRINT 'Tabella MM4_IM_QuotationRequests eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_JobQuotations]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_JobQuotations]
    PRINT 'Tabella MM4_IM_JobQuotations eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_WorkingReports]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_WorkingReports]
    PRINT 'Tabella MM4_IM_WorkingReports eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_WorksProgressReport]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_WorksProgressReport]
    PRINT 'Tabella MM4_IM_WorksProgressReport eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_PurchaseRequest]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_PurchaseRequest]
    PRINT 'Tabella MM4_IM_PurchaseRequest eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_DeliveryRequest]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_DeliveryRequest]
    PRINT 'Tabella MM4_IM_DeliveryRequest eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_MA_PurchaseOrd]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_MA_PurchaseOrd]
    PRINT 'Tabella MM4_MA_PurchaseOrd eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_SubcontractOrd]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_SubcontractOrd]
    PRINT 'Tabella MM4_IM_SubcontractOrd eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_SubcontractWorksProgressReport]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_SubcontractWorksProgressReport]
    PRINT 'Tabella MM4_IM_SubcontractWorksProgressReport eliminata.'
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MM4_IM_StatOfAccount]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[MM4_IM_StatOfAccount]
    PRINT 'Tabella MM4_IM_StatOfAccount eliminata.'
END

CREATE TABLE [dbo].[MM4_MA_Jobs](
    [Db] [varchar](20) NULL,
    [Job] [varchar](10) NOT NULL,
    [Description] [varchar](128) NULL,
    [GroupCode] [varchar](10) NULL,
    [Customer] [varchar](12) NULL,
    [CreationDate] [datetime] NULL,
    [ExpectedStartingDate] [datetime] NULL,
    [StartingDate] [datetime] NULL,
    [ExpectedDeliveryDate] [datetime] NULL,
    [DeliveryDate] [datetime] NULL,
    [Contract] [varchar](64) NULL,
    [ContactPerson] [varchar](64) NULL,
    [Price] [float] NULL,
    [Collected] [float] NULL,
    [ExpectedCost] [float] NULL,
    [MachineHours] [float] NULL,
    [DepreciationPerc] [float] NULL,
    [Inhouse] [char](1) NULL,
    [Disabled] [char](1) NULL,
    [Notes] [varchar](64) NULL,
    [JobType] [int] NULL,
    [ParentJob] [varchar](10) NULL,
    [TBGuid] [uniqueidentifier] NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [IM_JobStatus] [int] NULL,
    [ContractCode] [varchar](15) NULL,
    [ProjectCode] [varchar](16) NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [IM_JobSubStatus] [varchar](10) NULL,
    [EIJobCode] [varchar](100) NULL,
    [IM_JobId] [int] NOT NULL,
    [IM_CRRefType] [int] NOT NULL,
    [IM_CRRefID] [int] NOT NULL
);

CREATE TABLE [dbo].[MM4_IM_Employees](
    [Db] [varchar](20) NULL,
    [Employee] [varchar](10) NULL,
    [Name] [varchar](64) NULL,
    [Address] [varchar](64) NULL,
    [Qualification] [varchar](10) NULL,
    [ZipCode] [varchar](8) NULL,
    [City] [varchar](32) NULL,
    [County] [varchar](3) NULL,
    [Telephone1] [varchar](20) NULL,
    [Telephone2] [varchar](20) NULL,
    [OrdinaryCost] [float] NULL,
    [OvertimeCost] [float] NULL,
    [TravelExpenses] [float] NULL,
    [SickLeaveCost] [float] NULL,
    [VacationLeaveCost] [float] NULL,
    [FiscalCode] [varchar](16) NULL,
    [Document1] [varchar](32) NULL,
    [Document2] [varchar](32) NULL,
    [Document1Type] [varchar](32) NULL,
    [Document2Type] [varchar](32) NULL,
    [Disabled] [char](1) NULL,
    [CustomCost1] [float] NULL,
    [CustomCost2] [float] NULL,
    [CustomCost3] [float] NULL,
    [CustomCost4] [float] NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [Login] [varchar](64) NULL,
    [Manager] [varchar](10) NULL,
    [TypeAccessJobs] [int] NULL,
    [email] [varchar](255) NOT NULL,
    [WRStatus] [int] NULL,
    [AppRole] [int] NULL,
    [Region] [varchar](32) NULL
);

CREATE TABLE [dbo].[MM4_IM_ComponentsLists](
    [Db] [varchar](20) NULL,
    [ComponentsList] [varchar](21) NULL,
    [Description] [varchar](128) NULL,
    [CreationDate] [datetime] NULL,
    [LastChangeDate] [datetime] NULL,
    [ReferenceQuantity] [float] NULL,
    [HourlyRate] [float] NULL,
    [UnitTime] [int] NULL,
    [BaseUoM] [varchar](8) NULL,
    [IsUpdated] [char](1) NULL,
    [ComponentSubListsTotalTime] [int] NULL,
    [TimesAndCostsAreBlocked] [char](1) NULL,
    [AccessoriesCostTotalAmount] [float] NULL,
    [ServicesCostTotalAmount] [float] NULL,
    [ChargesCostTotalAmount] [float] NULL,
    [GoodsCostTotalAmount] [float] NULL,
    [OtherCostTotalAmount] [float] NULL,
    [LabourCostTotalAmount] [float] NULL,
    [ComponentSubListsCost] [float] NULL,
    [GoodsMarkupPerc] [float] NULL,
    [ServicesMarkupPerc] [float] NULL,
    [OtherMarkupPerc] [float] NULL,
    [LabourMarkupPerc] [float] NULL,
    [ChargesMarkupPerc] [float] NULL,
    [MarkupIsInDoc] [char](1) NULL,
    [ComponentCostTotalAmount] [float] NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [Disabled] [char](1) NULL,
    [DisableCreationItem] [char](1) NULL,
    [Note] [varchar](255) NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [FixedComponentCostTotalAmount] [float] NULL,
    [FixedUnitTime] [int] NULL
);

CREATE TABLE [dbo].[MM4_IM_Specifications](
    [Db] [varchar](20) NULL,
    [Specification] [varchar](10) NOT NULL,
    [Description] [varchar](64) NULL,
    [Disabled] [char](1) NULL,
    [Version] [smallint] NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [LenSegmenti] [smallint] NULL,
    [Segmenti] [smallint] NULL,
    [Separatore] [varchar](1) NULL,
    [Filler] [varchar](1) NULL
);

CREATE TABLE [dbo].[MM4_IM_QuotationRequests](
	[Db] [varchar](20)  NULL,
	[QuotationRequestId] [int] NULL,
	[QuotationRequestNo] [varchar](21) NULL,
	[CreationDate] [datetime] NULL,
	[Customer] [varchar](12) NULL,
	[Contact] [varchar](12) NULL,
	[UseContact] [char](1) NULL,
	[ValidityEndingDate] [datetime] NULL,
	[RequestReference] [varchar](10) NULL,
	[Description] [varchar](64) NULL,
	[DetailedDescription] [varchar](250) NULL,
	[Specification] [varchar](10) NULL,
	[QuotationIsIssued] [char](1) NULL,
	[FeasibilityDate] [datetime] NULL,
	[FeasibilityManager] [varchar](10) NULL,
	[Feasible] [char](1) NULL,
	[Note] [varchar](128) NULL,
	[QuotationManager] [varchar](10) NULL,
	[CustomerBank] [varchar](11) NULL,
	[CompanyBank] [varchar](11) NULL,
	[CompanyCurrentAccount] [varchar](16) NULL,
	[SendDocumentsTo] [varchar](8) NULL,
	[SendPaymentsTo] [varchar](8) NULL,
	[Language] [varchar](8) NULL,
	[PriceList] [varchar](8) NULL,
	[TaxCode] [varchar](4) NULL,
	[NetOfTax] [char](1) NULL,
	[Closed] [char](1) NULL,
	[CustomerReference] [varchar](10) NULL,
	[CustomerRefPerson] [varchar](64) NULL,
	[Printed] [char](1) NULL,
	[CustomerEngineer] [varchar](64) NULL,
	[TBCreated] [datetime] NOT NULL,
	[TBModified] [datetime] NOT NULL,
	[QuotationRequestStatus] [int] NULL,
	[TBCreatedID] [int] NOT NULL,
	[TBModifiedID] [int] NOT NULL,
	[TBGuid] [uniqueidentifier] NULL);

CREATE TABLE [dbo].[MM4_IM_JobQuotations](
	[Db] [varchar](20)  NULL,
	[JobQuotationId] [int] NULL,
	[Customer] [varchar](12) NULL,
	[JobQuotationNo] [varchar](10) NULL,
	[QuotationReference] [varchar](16) NULL,
	[CreationDate] [datetime] NULL,
	[HourlyRate] [float] NULL,
	[MarkupPerc] [float] NULL,
	[Specification] [varchar](10) NULL,
	[ValidityEndingDate] [datetime] NULL,
	[Contact] [varchar](12) NULL,
	[UseContact] [char](1) NULL,
	[LabourMarkup] [float] NULL,
	[UseSpecificationPrice] [char](1) NULL,
	[Description] [varchar](250) NULL,
	[Storage] [varchar](8) NULL,
	[ExpectedStartingDate] [datetime] NULL,
	[ExpectedEndingDate] [datetime] NULL,
	[WorksEndingDate] [datetime] NULL,
	[Simulation] [varchar](15) NULL,
	[SimDate] [datetime] NULL,
	[SimPurchaseRequestNo] [varchar](10) NULL,
	[SimPurchaseRequestId] [int] NULL,
	[OriginalJobQuotationId] [int] NULL,
	[TaxCode] [varchar](4) NULL,
	[Payment] [varchar](8) NULL,
	[CustomerBank] [varchar](11) NULL,
	[CompanyBank] [varchar](11) NULL,
	[CompanyCurrentAccount] [varchar](16) NULL,
	[Presentation] [int] NULL,
	[Language] [varchar](8) NULL,
	[PriceList] [varchar](8) NULL,
	[SendDocumentsTo] [varchar](8) NULL,
	[SendPaymentsTo] [varchar](8) NULL,
	[NetOfTax] [char](1) NULL,
	[SalesPerson] [varchar](8) NULL,
	[Currency] [varchar](8) NULL,
	[FixingDate] [datetime] NULL,
	[Fixing] [float] NULL,
	[FixingIsManual] [char](1) NULL,
	[UnitValueIsCalculated] [char](1) NULL,
	[QuotationRequestId] [int] NULL,
	[UseSpecificationQty] [char](1) NULL,
	[JobQuotaRevNo] [smallint] NOT NULL,
	[JobQuotaFinal] [char](1) NULL,
	[JobQuotaParentId] [int] NOT NULL,
	[TBCreated] [datetime] NOT NULL,
	[TBModified] [datetime] NOT NULL,
	[JobQuotaPreferentialRev] [char](1) NULL,
	[JobQuotaStatus] [int] NULL,
	[EmployeeReference] [varchar](10) NOT NULL,
	[JobReference] [varchar](10) NOT NULL,
	[TBCreatedID] [int] NOT NULL,
	[TBModifiedID] [int] NOT NULL,
	[AcceptanceDate] [datetime] NULL,
	[AcquireProbabilityDate] [datetime] NULL,
	[AcquireProbabilityPerc] [float] NULL,
	[CRRefType] [int] NULL,
	[CRRefID] [int] NULL,
	[TBGuid] [uniqueidentifier] NULL,
	[JobQuotationGroup] [varchar](10) NULL,
	[JobGroup] [varchar](10) NULL);


CREATE TABLE [dbo].[MM4_IM_WorkingReports](
    [Db] [varchar](20) NULL,
    [WorkingReportId] [int] NULL,
    [WorkingReportNo] [varchar](10) NULL,
    [WorkingReportDate] [datetime] NULL,
    [PostingDate] [datetime] NULL,
    [Customer] [varchar](12) NULL,
    [Payment] [varchar](8) NULL,
    [PostedToAccounting] [char](1) NULL,
    [Issued] [char](1) NULL,
    [Posted] [char](1) NULL,
    [Printed] [char](1) NULL,
    [InvoiceFollows] [char](1) NULL,
    [WRReason] [varchar](8) NULL,
    [StubBook] [varchar](8) NULL,
    [Job] [varchar](10) NULL,
    [PostedToCostAccounting] [char](1) NULL,
    [WorkingReportType] [int] NULL,
    [LabourHourlyRate] [float] NULL,
    [CallServiceCost] [float] NULL,
    [DNId] [int] NULL,
    [DNNo] [varchar](10) NULL,
    [PriceList] [varchar](8) NULL,
    [CustomerBank] [varchar](11) NULL,
    [CompanyBank] [varchar](11) NULL,
    [AccTpl] [varchar](8) NULL,
    [TaxJournal] [varchar](8) NULL,
    [CallService] [varchar](21) NULL,
    [Labour] [varchar](21) NULL,
    [Description] [varchar](32) NULL,
    [InvRsn] [varchar](8) NULL,
    [StorageStubBook] [varchar](8) NULL,
    [StoragePhase1] [varchar](8) NULL,
    [StoragePhase2] [varchar](8) NULL,
    [SpecificatorPhase1] [varchar](12) NULL,
    [SpecificatorPhase2] [varchar](12) NULL,
    [SaleDocGenerated] [char](1) NULL,
    [PostedToInventory] [char](1) NULL,
    [EntryId] [int] NULL,
    [BalanceFromEmployeesTab] [char](1) NULL,
    [BalanceFromActualitiesTab] [char](1) NULL,
    [Currency] [varchar](8) NULL,
    [FixingDate] [datetime] NULL,
    [Fixing] [float] NULL,
    [FixingIsManual] [char](1) NULL,
    [WorkingReportTypology] [int] NULL,
    [Employee] [varchar](10) NULL,
    [Qualification] [varchar](10) NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [ExternalReference] [varchar](21) NULL,
    [TBGuid] [uniqueidentifier] NULL,
    [Status] [int] NULL,
    [SourceCreated] [int] NULL,
    [SourceModified] [int] NULL,
    [SentByEMail] [char](1) NULL
);

CREATE TABLE [dbo].[MM4_IM_WorksProgressReport](
    [Db] [varchar](20) NULL,
    [WPRId] [int] NULL,
    [WPRNo] [varchar](10) NULL,
    [Description] [varchar](64) NULL,
    [Job] [varchar](10) NULL,
    [CreationDate] [datetime] NULL,
    [Note] [varchar](250) NULL,
    [Invoiced] [char](1) NULL,
    [GeneratedDocType] [int] NULL,
    [TotalAmount] [float] NULL,
    [CollectedTotalAmount] [float] NULL,
    [WithholdingTaxTotalAmount] [float] NULL,
    [CollectingTotalAmount] [float] NULL,
    [WithholdingTaxTaxableAmount] [float] NULL,
    [InvoicingTaxableAmount] [float] NULL,
    [TaxTotalAmount] [float] NULL,
    [InvoiceTotalAmount] [float] NULL,
    [InvoiceId] [int] NULL,
    [TaxCode] [varchar](4) NULL,
    [Offset] [varchar](16) NULL,
    [TaxJournal] [varchar](8) NULL,
    [AccTpl] [varchar](8) NULL,
    [Payment] [varchar](8) NULL,
    [InvoiceDescriptionLine1] [varchar](64) NULL,
    [InvoiceDescriptionLine2] [varchar](64) NULL,
    [InvoiceDescriptionLine3] [varchar](64) NULL,
    [Currency] [varchar](8) NULL,
    [FixingDate] [datetime] NULL,
    [Fixing] [float] NULL,
    [FixingIsManual] [char](1) NULL,
    [TaxableAmountDocCurr] [float] NULL,
    [TaxAmountDocCurr] [float] NULL,
    [InvoicedTotalAmountBaseCurr] [float] NULL,
    [CollectingTotalAmountBaseCurr] [float] NULL,
    [DiscountFormula] [varchar](16) NULL,
    [Discount1] [float] NULL,
    [Discount2] [float] NULL,
    [DiscountedTotalAmount] [float] NULL,
    [ParentJobTotalAmount] [float] NULL,
    [VariantJobTotalAmount] [float] NULL,
    [OATAMBJobTotalAmount] [float] NULL,
    [InvoiceWillNotFollow] [char](1) NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [EnablesRowChange] [char](1) NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [InvoicePreviewDate] [datetime] NULL,
    [TBGuid] [uniqueidentifier] NULL
);

CREATE TABLE [dbo].[MM4_IM_PurchaseRequest](
    [Db] [varchar](20) NULL,
    [PurchaseRequestId] [int] NULL,
    [PurchaseRequestNo] [varchar](10) NULL,
    [CreationDate] [datetime] NULL,
    [OriginDocType] [int] NULL,
    [Final] [char](1) NULL,
    [Simulation] [varchar](15) NULL,
    [OriginalPurchReqId] [int] NULL,
    [TaxableAmount] [float] NULL,
    [TaxAmount] [float] NULL,
    [Amount] [float] NULL,
    [DiscountTotalAmount] [float] NULL,
    [GoodsTotalAmount] [float] NULL,
    [SimulatedValueType] [int] NULL,
    [ManageQuotasDiscount] [char](1) NULL,
    [ManageQuotasAllowances] [char](1) NULL,
    [NettingStorage] [varchar](8) NULL,
    [NettingSpecificatorType] [int] NULL,
    [NettingSpecificator] [varchar](12) NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [Applier] [varchar](10) NULL,
    [Notes] [ntext] NULL,
    [ServicesTotalAmount] [float] NULL,
    [TBGuid] [uniqueidentifier] NULL
);



CREATE TABLE [dbo].[MM4_IM_DeliveryRequest](
    [Db] [varchar](20) NULL,
    [DeliveryRequestId] [int] NULL,
    [DeliveryRequestNo] [varchar](10) NULL,
    [CreationDate] [datetime] NULL,
    [Applier] [varchar](10) NULL,
    [Description] [varchar](128) NULL,
    [Job] [varchar](10) NOT NULL,
    [StoragePO] [varchar](8) NULL,
    [StoragePL] [varchar](8) NULL,
    [EvaluationStatus] [int] NULL,
    [EvaluationDate] [datetime] NULL,
    [ApprovalStatus] [int] NULL,
    [Note] [varchar](250) NULL,
    [Ordered] [char](1) NULL,
    [RequiredDeliveryDate] [datetime] NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [TBCreatedID] [int] NOT NULL,
    [TBModifiedID] [int] NOT NULL,
    [TBGuid] [uniqueidentifier] NULL
);




CREATE TABLE [dbo].[MM4_MA_PurchaseOrd](
    [Db] [varchar](20) NULL,
    [InternalOrdNo] [varchar](10) NULL,
    [ExternalOrdNo] [varchar](20) NULL,
    [OrderDate] [datetime] NULL,
    [ExpectedDeliveryDate] [datetime] NULL,
    [ConfirmedDeliveryDate] [datetime] NULL,
    [Supplier] [varchar](12) NULL,
    [Language] [varchar](8) NULL,
    [OurReference] [varchar](32) NULL,
    [YourReference] [varchar](32) NULL,
    [Payment] [varchar](8) NULL,
    [SupplierBank] [varchar](11) NULL,
    [CompanyBank] [varchar](11) NULL,
    [SendDocumentsTo] [varchar](8) NULL,
    [NetOfTax] [char](1) NULL,
    [Currency] [varchar](8) NULL,
    [FixingDate] [datetime] NULL,
    [FixingIsManual] [char](1) NULL,
    [Fixing] [float] NULL,
    [Area] [varchar](8) NULL,
    [Salesperson] [varchar](8) NULL,
    [Notes] [ntext] NULL,
    [Paid] [char](1) NULL,
    [Delivered] [char](1) NULL,
    [Printed] [char](1) NULL,
    [SentByEMail] [char](1) NULL,
    [Cancelled] [char](1) NULL,
    [PurchaseOrdId] [int] NULL,
    [Job] [varchar](10) NULL,
    [CostCenter] [varchar](8) NULL,
    [AccTpl] [varchar](8) NULL,
    [TaxJournal] [varchar](8) NULL,
    [InvRsn] [varchar](8) NULL,
    [StubBook] [varchar](8) NULL,
    [StoragePhase1] [varchar](8) NULL,
    [SpecificatorPhase1] [varchar](12) NULL,
    [StoragePhase2] [varchar](8) NULL,
    [SpecificatorPhase2] [varchar](12) NULL,
    [NonStandardPayment] [char](1) NULL,
    [UseBusinessYear] [char](1) NULL,
    [SubcontractorOrder] [char](1) NULL,
    [CompanyCA] [varchar](18) NULL,
    [LastSubId] [int] NULL,
    [CustSuppType] [int] NULL,
    [Specificator1Type] [int] NULL,
    [Specificator2Type] [int] NULL,
    [ProductLine] [varchar](8) NULL,
    [TBGuid] [uniqueidentifier] NULL,
    [AccGroup] [varchar](2) NULL,
    [SupplierCA] [varchar](18) NULL,
    [TBCreated] [datetime] NULL,
    [TBModified] [datetime] NULL,
    [PaymentAddress] [varchar](8) NULL,
    [ContractCode] [varchar](15) NULL,
    [ProjectCode] [varchar](16) NULL,
    [BarcodeSegment] [varchar](10) NULL,
    [TBCreatedID] [int] NULL,
    [TBModifiedID] [int] NULL,
    [Receipt] [char](1) NULL,
    [Autorizzato] [char](1) NULL,
    [DataAutorizzazione] [datetime] NULL,
    [chSpedito] [char](1) NULL,
    [chDataSped] [datetime] NULL,
    [chGiaAutoriz] [char](1) NULL,
    [chGiaSpedito] [char](1) NULL,
    [TaxCommunicationGroup] [varchar](16) NULL,
    [SentByPostaLite] [char](1) NULL,
    [Archived] [char](1) NULL
);

CREATE TABLE [dbo].[MM4_IM_SubcontractOrd](
    [Db] [varchar](20) NULL,
    [SubcontractOrdId] [int] NULL,
    [SubcontractOrdNo] [varchar](10) NULL,
    [ExternalOrdNo] [varchar](20) NULL,
    [OrderDate] [datetime] NULL,
    [ExpectedTestDate] [datetime] NULL,
    [ExpectedEndingDate] [datetime] NULL,
    [Supplier] [varchar](12) NULL,
    [Job] [varchar](10) NULL,
    [SubcontractOrdStatus] [int] NULL,
    [Currency] [varchar](8) NULL,
    [FixingDate] [datetime] NULL,
    [FixingIsManual] [char](1) NULL,
    [Fixing] [float] NULL,
    [Payment] [varchar](8) NULL,
    [Cancelled] [char](1) NULL,
    [Delivered] [char](1) NULL,
    [Paid] [char](1) NULL,
    [AccTpl] [varchar](8) NULL,
    [AccGroup] [varchar](2) NULL,
    [CostCenter] [varchar](8) NULL,
    [ContractCode] [varchar](10) NULL,
    [ProjectCode] [varchar](16) NULL,
    [SupplierBank] [varchar](11) NULL,
    [CompanyBank] [varchar](11) NULL,
    [SupplierCA] [varchar](18) NULL,
    [CompanyCA] [varchar](18) NULL,
    [Language] [varchar](8) NULL,
    [PaymentAddress] [varchar](8) NULL,
    [TaxJournal] [varchar](8) NULL,
    [TaxCode] [varchar](4) NULL,
    [Description] [varchar](64) NULL,
    [OurReference] [varchar](32) NULL,
    [YourReference] [varchar](32) NULL,
    [Notes] [ntext] NULL,
    [Printed] [char](1) NULL,
    [WithholdingPaymentDate] [datetime] NULL,
    [TBCreated] [datetime] NULL,
    [TBModified] [datetime] NULL,
    [TBCreatedID] [int] NULL,
    [TBModifiedID] [int] NULL,
    [OriginCostsSubcontract] [int] NULL,
    [CodeService] [varchar](21) NULL,
    [NetOfTax] [char](1) NULL,
    [TBGuid] [uniqueidentifier] NULL
);

CREATE TABLE [dbo].[MM4_IM_SubcontractWorksProgressReport](
    [Db] [varchar](20) NULL,
    [SubcontractWPRId] [int] NULL,
    [SubcontractWPRNo] [varchar](10) NULL,
    [ExternalWPRNo] [varchar](20) NULL,
    [SubcontractWPRDate] [datetime] NULL,
    [SubcontractOrdId] [int] NULL,
    [Supplier] [varchar](12) NULL,
    [Job] [varchar](10) NULL,
    [SubcontractWPRStatus] [int] NULL,
    [Currency] [varchar](8) NULL,
    [FixingDate] [datetime] NULL,
    [FixingIsManual] [char](1) NULL,
    [Fixing] [float] NULL,
    [Payment] [varchar](8) NULL,
    [Paid] [char](1) NULL,
    [AccTpl] [varchar](8) NULL,
    [AccGroup] [varchar](2) NULL,
    [CostCenter] [varchar](8) NULL,
    [ContractCode] [varchar](10) NULL,
    [ProjectCode] [varchar](16) NULL,
    [SupplierBank] [varchar](11) NULL,
    [CompanyBank] [varchar](11) NULL,
    [SupplierCA] [varchar](18) NULL,
    [CompanyCA] [varchar](18) NULL,
    [Language] [varchar](8) NULL,
    [PaymentAddress] [varchar](8) NULL,
    [TaxJournal] [varchar](8) NULL,
    [TaxCode] [varchar](4) NULL,
    [Description] [varchar](64) NULL,
    [ExternalDescription] [varchar](64) NULL,
    [OurReference] [varchar](32) NULL,
    [YourReference] [varchar](32) NULL,
    [Notes] [ntext] NULL,
    [TBCreated] [datetime] NULL,
    [TBModified] [datetime] NULL,
    [TBCreatedID] [int] NULL,
    [TBModifiedID] [int] NULL,
    [CRRefType] [int] NULL,
    [CRRefID] [int] NULL,
    [TBGuid] [uniqueidentifier] NULL
);

CREATE TABLE [dbo].[MM4_IM_StatOfAccount](
    [Db] [varchar](20) NULL,
    [StatOfAccountId] [int] NULL,
    [Job] [varchar](10) NULL,
    [StatOfAccountNo] [varchar](10) NULL,
    [Description] [varchar](128) NULL,
    [CreationDate] [datetime] NULL,
    [IssueDate] [datetime] NULL,
    [InvoiceDate] [datetime] NULL,
    [Issued] [char](1) NULL,
    [Invoiced] [char](1) NULL,
    [Customer] [varchar](12) NULL,
    [TotalAmount] [float] NULL,
    [GoodsTotalAmount] [float] NULL,
    [ServicesTotalAmount] [float] NULL,
    [LabourTotalAmount] [float] NULL,
    [GoodsMarkupAmount] [float] NULL,
    [LabourMarkupAmount] [float] NULL,
    [ServicesMarkupAmount] [float] NULL,
    [GoodsDiscountsAmount] [float] NULL,
    [LabourDiscountsAmount] [float] NULL,
    [ServicesDiscountsAmount] [float] NULL,
    [GoodsNetAmount] [float] NULL,
    [ServicesNetAmount] [float] NULL,
    [LabourNetAmount] [float] NULL,
    [FurtherDiscount] [float] NULL,
    [FurtherDiscountAmount] [float] NULL,
    [AllowancesAmount] [float] NULL,
    [Currency] [varchar](8) NULL,
    [FixingDate] [datetime] NULL,
    [Fixing] [float] NULL,
    [FixingIsManual] [char](1) NULL,
    [TotalAmountBaseCurr] [float] NULL,
    [InvoicingGroupCode] [varchar](8) NULL,
    [Printed] [char](1) NULL,
    [TBCreated] [datetime] NOT NULL,
    [TBModified] [datetime] NOT NULL,
    [OtherTotalAmount] [float] NULL,
    [OtherMarkupAmount] [float] NULL,
    [OtherDiscountsAmount] [float] NULL,
    [OtherNetAmount] [float] NULL,
    [TotalCost] [float] NULL,
    [GoodsTotalCost] [float] NULL,
    [ServicesTotalCost] [float] NULL,
    [LabourTotalCost] [float] NULL,
    [OtherTotalCost] [float] NULL,
    [TotalMargin] [float] NULL,
    [GoodsTotalMargin] [float] NULL,
    [ServicesTotalMargin] [float] NULL,
    [LabourTotalMargin] [float] NULL,
    [OtherTotalMargin] [float] NULL,
    [TotalPercMargin] [float] NULL,
    [GoodsTotalPercMargin] [float] NULL,
    [ServicesTotalPercMargin] [float] NULL,
    [LabourTotalPercMargin] [float] NULL,
    [OtherTotalPercMargin] [float] NULL,
    [TotalAmountOriginal] [float] NULL,
    [TotalCostOriginal] [float] NULL,
    [TotalMarginOriginal] [float] NULL,
    [AddAmount] [float] NULL,
    [DeltaMargin] [float] NULL,
    [chkGoods] [char](1) NULL,
    [chkLabour] [char](1) NULL,
    [chkServices] [char](1) NULL,
    [chkOther] [char](1) NULL,
    [RipAll] [char](1) NULL,
    [chkUseRip] [char](1) NULL,
    [TBCreatedID] [int] NULL,
    [TBModifiedID] [int] NULL,
    [InvoicePreviewDate] [datetime] NULL,
    [CRRefType] [int] NULL,
    [CRRefID] [int] NULL,
    [TBGuid] [uniqueidentifier] NULL,
    [SentByEMail] [char](1) NULL
);

"@

try {
    # Creare la connessione
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()

    # Creare e eseguire il comando per la creazione delle tabelle
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = $SqlQuery
    
    Write-Host "Creazione tabelle in corso..." -ForegroundColor Yellow
    $command.ExecuteNonQuery()
    Write-Host "Tabelle create con successo!" -ForegroundColor Green

    # Importare i dati da ogni database sorgente
    foreach ($sourceDb in $SourceDatabases) {
        Write-Host "elaboro da $sourceDb" -ForegroundColor Yellow 
        # Query per verificare l'esistenza del database sorgente
        $checkDbQuery = @"
        IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '$sourceDb')
        SELECT 1 ELSE SELECT 0
"@
        $command.CommandText = $checkDbQuery
        $dbExists = $command.ExecuteScalar()

        if ($dbExists -eq 1) {
            Write-Host "Importazione dati da $sourceDb in corso..." -ForegroundColor Yellow

            # Query per verificare l'esistenza della tabella MA_Jobs nel database sorgente
            $checkTableQuery = @"
            IF EXISTS (SELECT 1 
                      FROM $sourceDb.sys.tables 
                      WHERE name = 'MA_Jobs')
            SELECT 1 ELSE SELECT 0
"@
            $command.CommandText = $checkTableQuery
            $tableExists = $command.ExecuteScalar()
           
            if ($tableExists -eq 1) {
                # Query per l'importazione dei dati
                $ImportQuery = @"
                INSERT INTO VedMaster.dbo.MM4_MA_Jobs (
                    [Db], [Job], [Description], [GroupCode], [Customer], 
                    [CreationDate], [ExpectedStartingDate], [StartingDate], 
                    [ExpectedDeliveryDate], [DeliveryDate], [Contract], 
                    [ContactPerson], [Price], [Collected], [ExpectedCost], 
                    [MachineHours], [DepreciationPerc], [Inhouse], [Disabled], 
                    [Notes], [JobType], [ParentJob], [TBGuid], [TBCreated], 
                    [TBModified], [IM_JobStatus], [ContractCode], [ProjectCode], 
                    [TBCreatedID], [TBModifiedID], [IM_JobSubStatus], [EIJobCode], 
                    [IM_JobId], [IM_CRRefType], [IM_CRRefID]
                )
                SELECT 
                    '$sourceDb' as [Db], 
                    [Job], [Description], [GroupCode], [Customer], 
                    [CreationDate], [ExpectedStartingDate], [StartingDate], 
                    [ExpectedDeliveryDate], [DeliveryDate], [Contract], 
                    [ContactPerson], [Price], [Collected], [ExpectedCost], 
                    [MachineHours], [DepreciationPerc], [Inhouse], [Disabled], 
                    [Notes], [JobType], [ParentJob], [TBGuid], [TBCreated], 
                    [TBModified], [IM_JobStatus], [ContractCode], [ProjectCode], 
                    [TBCreatedID], [TBModifiedID], [IM_JobSubStatus], [EIJobCode], 
                    [IM_JobId], [IM_CRRefType], [IM_CRRefID]
                FROM $sourceDb.dbo.MA_Jobs;

                INSERT INTO VedMaster.dbo.MM4_IM_Employees (
                    [Db], [Employee], [Name], [Address], [Qualification], 
                    [ZipCode], [City], [County], [Telephone1], [Telephone2], 
                    [OrdinaryCost], [OvertimeCost], [TravelExpenses], 
                    [SickLeaveCost], [VacationLeaveCost], [FiscalCode], 
                    [Document1], [Document2], [Document1Type], [Document2Type], 
                    [Disabled], [CustomCost1], [CustomCost2], [CustomCost3], 
                    [CustomCost4], [TBCreated], [TBModified], [TBCreatedID], 
                    [TBModifiedID], [Login], [Manager], [TypeAccessJobs], 
                    [email], [WRStatus], [AppRole], [Region]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [Employee], [Name], [Address], [Qualification], 
                    [ZipCode], [City], [County], [Telephone1], [Telephone2], 
                    [OrdinaryCost], [OvertimeCost], [TravelExpenses], 
                    [SickLeaveCost], [VacationLeaveCost], [FiscalCode], 
                    [Document1], [Document2], [Document1Type], [Document2Type], 
                    [Disabled], [CustomCost1], [CustomCost2], [CustomCost3], 
                    [CustomCost4], [TBCreated], [TBModified], [TBCreatedID], 
                    [TBModifiedID], [Login], [Manager], [TypeAccessJobs], 
                    [email], [WRStatus], [AppRole], [Region]
                FROM $sourceDb.dbo.IM_Employees;

                INSERT INTO VedMaster.dbo.MM4_IM_ComponentsLists (
                    [Db], [ComponentsList], [Description], [CreationDate], 
                    [LastChangeDate], [ReferenceQuantity], [HourlyRate], 
                    [UnitTime], [BaseUoM], [IsUpdated], [ComponentSubListsTotalTime], 
                    [TimesAndCostsAreBlocked], [AccessoriesCostTotalAmount], 
                    [ServicesCostTotalAmount], [ChargesCostTotalAmount], 
                    [GoodsCostTotalAmount], [OtherCostTotalAmount], 
                    [LabourCostTotalAmount], [ComponentSubListsCost], 
                    [GoodsMarkupPerc], [ServicesMarkupPerc], [OtherMarkupPerc], 
                    [LabourMarkupPerc], [ChargesMarkupPerc], [MarkupIsInDoc], 
                    [ComponentCostTotalAmount], [TBCreated], [TBModified], 
                    [Disabled], [DisableCreationItem], [Note], [TBCreatedID], 
                    [TBModifiedID], [FixedComponentCostTotalAmount], [FixedUnitTime]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [ComponentsList], [Description], [CreationDate], 
                    [LastChangeDate], [ReferenceQuantity], [HourlyRate], 
                    [UnitTime], [BaseUoM], [IsUpdated], [ComponentSubListsTotalTime], 
                    [TimesAndCostsAreBlocked], [AccessoriesCostTotalAmount], 
                    [ServicesCostTotalAmount], [ChargesCostTotalAmount], 
                    [GoodsCostTotalAmount], [OtherCostTotalAmount], 
                    [LabourCostTotalAmount], [ComponentSubListsCost], 
                    [GoodsMarkupPerc], [ServicesMarkupPerc], [OtherMarkupPerc], 
                    [LabourMarkupPerc], [ChargesMarkupPerc], [MarkupIsInDoc], 
                    [ComponentCostTotalAmount], [TBCreated], [TBModified], 
                    [Disabled], [DisableCreationItem], [Note], [TBCreatedID], 
                    [TBModifiedID], [FixedComponentCostTotalAmount], [FixedUnitTime]
                FROM $sourceDb.dbo.IM_ComponentsLists;
                
                INSERT INTO VedMaster.dbo.MM4_IM_Specifications (
                    [Db], [Specification], [Description], [Disabled], 
                    [Version], [TBCreated], [TBModified], 
                    [TBCreatedID], [TBModifiedID]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [Specification], [Description], [Disabled], 
                    [Version], [TBCreated], [TBModified], 
                    [TBCreatedID], [TBModifiedID]
                FROM $sourceDb.dbo.IM_Specifications;

                INSERT INTO VedMaster.dbo.MM4_IM_QuotationRequests (
                    [Db], [QuotationRequestId], [QuotationRequestNo], [CreationDate],
                    [Customer], [Contact], [UseContact], [ValidityEndingDate],
                    [RequestReference], [Description], [DetailedDescription], [Specification],
                    [QuotationIsIssued], [FeasibilityDate], [FeasibilityManager], [Feasible],
                    [Note], [QuotationManager], [CustomerBank], [CompanyBank],
                    [CompanyCurrentAccount], [SendDocumentsTo], [SendPaymentsTo], [Language],
                    [PriceList], [TaxCode], [NetOfTax], [Closed], [CustomerReference],
                    [CustomerRefPerson], [Printed], [CustomerEngineer], [TBCreated],
                    [TBModified], [QuotationRequestStatus], [TBCreatedID], [TBModifiedID],
                    [TBGuid]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [QuotationRequestId], [QuotationRequestNo], [CreationDate],
                    [Customer], [Contact], [UseContact], [ValidityEndingDate],
                    [RequestReference], [Description], [DetailedDescription], [Specification],
                    [QuotationIsIssued], [FeasibilityDate], [FeasibilityManager], [Feasible],
                    [Note], [QuotationManager], [CustomerBank], [CompanyBank],
                    [CompanyCurrentAccount], [SendDocumentsTo], [SendPaymentsTo], [Language],
                    [PriceList], [TaxCode], [NetOfTax], [Closed], [CustomerReference],
                    [CustomerRefPerson], [Printed], [CustomerEngineer], [TBCreated],
                    [TBModified], [QuotationRequestStatus], [TBCreatedID], [TBModifiedID],
                    [TBGuid]
                FROM $sourceDb.dbo.IM_QuotationRequests;


                INSERT INTO VedMaster.dbo.MM4_IM_JobQuotations (
                    [Db], [JobQuotationId], [Customer], [JobQuotationNo], [QuotationReference],
                    [CreationDate], [HourlyRate], [MarkupPerc], [Specification], [ValidityEndingDate],
                    [Contact], [UseContact], [LabourMarkup], [UseSpecificationPrice], [Description],
                    [Storage], [ExpectedStartingDate], [ExpectedEndingDate], [WorksEndingDate],
                    [Simulation], [SimDate], [SimPurchaseRequestNo], [SimPurchaseRequestId],
                    [OriginalJobQuotationId], [TaxCode], [Payment], [CustomerBank], [CompanyBank],
                    [CompanyCurrentAccount], [Presentation], [Language], [PriceList],
                    [SendDocumentsTo], [SendPaymentsTo], [NetOfTax], [SalesPerson], [Currency],
                    [FixingDate], [Fixing], [FixingIsManual], [UnitValueIsCalculated],
                    [QuotationRequestId], [UseSpecificationQty], [JobQuotaRevNo], [JobQuotaFinal],
                    [JobQuotaParentId], [TBCreated], [TBModified], [JobQuotaPreferentialRev],
                    [JobQuotaStatus], [EmployeeReference], [JobReference], [TBCreatedID],
                    [TBModifiedID], [AcceptanceDate], [AcquireProbabilityDate], [AcquireProbabilityPerc],
                    [CRRefType], [CRRefID], [TBGuid], [JobQuotationGroup], [JobGroup]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [JobQuotationId], [Customer], [JobQuotationNo], [QuotationReference],
                    [CreationDate], [HourlyRate], [MarkupPerc], [Specification], [ValidityEndingDate],
                    [Contact], [UseContact], [LabourMarkup], [UseSpecificationPrice], [Description],
                    [Storage], [ExpectedStartingDate], [ExpectedEndingDate], [WorksEndingDate],
                    [Simulation], [SimDate], [SimPurchaseRequestNo], [SimPurchaseRequestId],
                    [OriginalJobQuotationId], [TaxCode], [Payment], [CustomerBank], [CompanyBank],
                    [CompanyCurrentAccount], [Presentation], [Language], [PriceList],
                    [SendDocumentsTo], [SendPaymentsTo], [NetOfTax], [SalesPerson], [Currency],
                    [FixingDate], [Fixing], [FixingIsManual], [UnitValueIsCalculated],
                    [QuotationRequestId], [UseSpecificationQty], [JobQuotaRevNo], [JobQuotaFinal],
                    [JobQuotaParentId], [TBCreated], [TBModified], [JobQuotaPreferentialRev],
                    [JobQuotaStatus], [EmployeeReference], [JobReference], [TBCreatedID],
                    [TBModifiedID], [AcceptanceDate], [AcquireProbabilityDate], [AcquireProbabilityPerc],
                    [CRRefType], [CRRefID], [TBGuid], [JobQuotationGroup], [JobGroup]
                FROM $sourceDb.dbo.IM_JobQuotations;

                INSERT INTO VedMaster.dbo.MM4_IM_WorkingReports (
                    [Db], [WorkingReportId], [WorkingReportNo], [WorkingReportDate], [PostingDate],
                    [Customer], [Payment], [PostedToAccounting], [Issued], [Posted], [Printed],
                    [InvoiceFollows], [WRReason], [StubBook], [Job], [PostedToCostAccounting],
                    [WorkingReportType], [LabourHourlyRate], [CallServiceCost], [DNId], [DNNo],
                    [PriceList], [CustomerBank], [CompanyBank], [AccTpl], [TaxJournal],
                    [CallService], [Labour], [Description], [InvRsn], [StorageStubBook],
                    [StoragePhase1], [StoragePhase2], [SpecificatorPhase1], [SpecificatorPhase2],
                    [SaleDocGenerated], [PostedToInventory], [EntryId], [BalanceFromEmployeesTab],
                    [BalanceFromActualitiesTab], [Currency], [FixingDate], [Fixing], [FixingIsManual],
                    [WorkingReportTypology], [Employee], [Qualification], [TBCreated], [TBModified],
                    [TBCreatedID], [TBModifiedID], [ExternalReference], [TBGuid], [Status],
                    [SourceCreated], [SourceModified], [SentByEMail]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [WorkingReportId], [WorkingReportNo], [WorkingReportDate], [PostingDate],
                    [Customer], [Payment], [PostedToAccounting], [Issued], [Posted], [Printed],
                    [InvoiceFollows], [WRReason], [StubBook], [Job], [PostedToCostAccounting],
                    [WorkingReportType], [LabourHourlyRate], [CallServiceCost], [DNId], [DNNo],
                    [PriceList], [CustomerBank], [CompanyBank], [AccTpl], [TaxJournal],
                    [CallService], [Labour], [Description], [InvRsn], [StorageStubBook],
                    [StoragePhase1], [StoragePhase2], [SpecificatorPhase1], [SpecificatorPhase2],
                    [SaleDocGenerated], [PostedToInventory], [EntryId], [BalanceFromEmployeesTab],
                    [BalanceFromActualitiesTab], [Currency], [FixingDate], [Fixing], [FixingIsManual],
                    [WorkingReportTypology], [Employee], [Qualification], [TBCreated], [TBModified],
                    [TBCreatedID], [TBModifiedID], [ExternalReference], [TBGuid], [Status],
                    [SourceCreated], [SourceModified], [SentByEMail]
                FROM $sourceDb.dbo.IM_WorkingReports;


                INSERT INTO VedMaster.dbo.MM4_IM_WorksProgressReport (
                    [Db], [WPRId], [WPRNo], [Description], [Job], [CreationDate], [Note],
                    [Invoiced], [GeneratedDocType], [TotalAmount], [CollectedTotalAmount],
                    [WithholdingTaxTotalAmount], [CollectingTotalAmount], [WithholdingTaxTaxableAmount],
                    [InvoicingTaxableAmount], [TaxTotalAmount], [InvoiceTotalAmount], [InvoiceId],
                    [TaxCode], [Offset], [TaxJournal], [AccTpl], [Payment], [InvoiceDescriptionLine1],
                    [InvoiceDescriptionLine2], [InvoiceDescriptionLine3], [Currency], [FixingDate],
                    [Fixing], [FixingIsManual], [TaxableAmountDocCurr], [TaxAmountDocCurr],
                    [InvoicedTotalAmountBaseCurr], [CollectingTotalAmountBaseCurr], [DiscountFormula],
                    [Discount1], [Discount2], [DiscountedTotalAmount], [ParentJobTotalAmount],
                    [VariantJobTotalAmount], [OATAMBJobTotalAmount], [InvoiceWillNotFollow],
                    [TBCreated], [TBModified], [EnablesRowChange], [TBCreatedID], [TBModifiedID],
                    [InvoicePreviewDate], [TBGuid]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [WPRId], [WPRNo], [Description], [Job], [CreationDate], [Note],
                    [Invoiced], [GeneratedDocType], [TotalAmount], [CollectedTotalAmount],
                    [WithholdingTaxTotalAmount], [CollectingTotalAmount], [WithholdingTaxTaxableAmount],
                    [InvoicingTaxableAmount], [TaxTotalAmount], [InvoiceTotalAmount], [InvoiceId],
                    [TaxCode], [Offset], [TaxJournal], [AccTpl], [Payment], [InvoiceDescriptionLine1],
                    [InvoiceDescriptionLine2], [InvoiceDescriptionLine3], [Currency], [FixingDate],
                    [Fixing], [FixingIsManual], [TaxableAmountDocCurr], [TaxAmountDocCurr],
                    [InvoicedTotalAmountBaseCurr], [CollectingTotalAmountBaseCurr], [DiscountFormula],
                    [Discount1], [Discount2], [DiscountedTotalAmount], [ParentJobTotalAmount],
                    [VariantJobTotalAmount], [OATAMBJobTotalAmount], [InvoiceWillNotFollow],
                    [TBCreated], [TBModified], [EnablesRowChange], [TBCreatedID], [TBModifiedID],
                    [InvoicePreviewDate], [TBGuid]
                FROM $sourceDb.dbo.IM_WorksProgressReport;

                INSERT INTO VedMaster.dbo.MM4_IM_PurchaseRequest (
                    [Db], [PurchaseRequestId], [PurchaseRequestNo], [CreationDate],
                    [OriginDocType], [Final], [Simulation], [OriginalPurchReqId],
                    [TaxableAmount], [TaxAmount], [Amount], [DiscountTotalAmount],
                    [GoodsTotalAmount], [SimulatedValueType], [ManageQuotasDiscount],
                    [ManageQuotasAllowances], [NettingStorage], [NettingSpecificatorType],
                    [NettingSpecificator], [TBCreated], [TBModified], [TBCreatedID],
                    [TBModifiedID], [Applier], [Notes], [ServicesTotalAmount], [TBGuid]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [PurchaseRequestId], [PurchaseRequestNo], [CreationDate],
                    [OriginDocType], [Final], [Simulation], [OriginalPurchReqId],
                    [TaxableAmount], [TaxAmount], [Amount], [DiscountTotalAmount],
                    [GoodsTotalAmount], [SimulatedValueType], [ManageQuotasDiscount],
                    [ManageQuotasAllowances], [NettingStorage], [NettingSpecificatorType],
                    [NettingSpecificator], [TBCreated], [TBModified], [TBCreatedID],
                    [TBModifiedID], [Applier], [Notes], [ServicesTotalAmount], [TBGuid]
                FROM $sourceDb.dbo.IM_PurchaseRequest;

                INSERT INTO VedMaster.dbo.MM4_IM_DeliveryRequest (
                    [Db], [DeliveryRequestId], [DeliveryRequestNo], [CreationDate],
                    [Applier], [Description], [Job], [StoragePO], [StoragePL],
                    [EvaluationStatus], [EvaluationDate], [ApprovalStatus], [Note],
                    [Ordered], [RequiredDeliveryDate], [TBCreated], [TBModified],
                    [TBCreatedID], [TBModifiedID], [TBGuid]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [DeliveryRequestId], [DeliveryRequestNo], [CreationDate],
                    [Applier], [Description], [Job], [StoragePO], [StoragePL],
                    [EvaluationStatus], [EvaluationDate], [ApprovalStatus], [Note],
                    [Ordered], [RequiredDeliveryDate], [TBCreated], [TBModified],
                    [TBCreatedID], [TBModifiedID], [TBGuid]
                FROM $sourceDb.dbo.IM_DeliveryRequest;
                
                INSERT INTO VedMaster.dbo.MM4_MA_PurchaseOrd (
                    [Db], [InternalOrdNo], [ExternalOrdNo], [OrderDate], [ExpectedDeliveryDate],
                    [ConfirmedDeliveryDate], [Supplier], [Language], [OurReference], [YourReference],
                    [Payment], [SupplierBank], [CompanyBank], [SendDocumentsTo], [NetOfTax],
                    [Currency], [FixingDate], [FixingIsManual], [Fixing], [Area], [Salesperson],
                    [Notes], [Paid], [Delivered], [Printed], [SentByEMail], [Cancelled],
                    [PurchaseOrdId], [Job], [CostCenter], [AccTpl], [TaxJournal], [InvRsn],
                    [StubBook], [StoragePhase1], [SpecificatorPhase1], [StoragePhase2],
                    [SpecificatorPhase2], [NonStandardPayment], [UseBusinessYear], [SubcontractorOrder],
                    [CompanyCA], [LastSubId], [CustSuppType], [Specificator1Type], [Specificator2Type],
                    [ProductLine], [TBGuid], [AccGroup], [SupplierCA], [TBCreated], [TBModified],
                    [PaymentAddress], [ContractCode], [ProjectCode], [BarcodeSegment], [TBCreatedID],
                    [TBModifiedID], [Receipt], [Autorizzato], [DataAutorizzazione], [chSpedito],
                    [chDataSped], [chGiaAutoriz], [chGiaSpedito], [TaxCommunicationGroup],
                    [SentByPostaLite], [Archived]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [InternalOrdNo], [ExternalOrdNo], [OrderDate], [ExpectedDeliveryDate],
                    [ConfirmedDeliveryDate], [Supplier], [Language], [OurReference], [YourReference],
                    [Payment], [SupplierBank], [CompanyBank], [SendDocumentsTo], [NetOfTax],
                    [Currency], [FixingDate], [FixingIsManual], [Fixing], [Area], [Salesperson],
                    [Notes], [Paid], [Delivered], [Printed], [SentByEMail], [Cancelled],
                    [PurchaseOrdId], [Job], [CostCenter], [AccTpl], [TaxJournal], [InvRsn],
                    [StubBook], [StoragePhase1], [SpecificatorPhase1], [StoragePhase2],
                    [SpecificatorPhase2], [NonStandardPayment], [UseBusinessYear], [SubcontractorOrder],
                    [CompanyCA], [LastSubId], [CustSuppType], [Specificator1Type], [Specificator2Type],
                    [ProductLine], [TBGuid], [AccGroup], [SupplierCA], [TBCreated], [TBModified],
                    [PaymentAddress], [ContractCode], [ProjectCode], [BarcodeSegment], [TBCreatedID],
                    [TBModifiedID], [Receipt], [Autorizzato], [DataAutorizzazione], [chSpedito],
                    [chDataSped], [chGiaAutoriz], [chGiaSpedito], [TaxCommunicationGroup],
                    [SentByPostaLite], [Archived]
                FROM $sourceDb.dbo.MA_PurchaseOrd;


                INSERT INTO VedMaster.dbo.MM4_IM_SubcontractOrd (
                    [Db], [SubcontractOrdId], [SubcontractOrdNo], [ExternalOrdNo], [OrderDate],
                    [ExpectedTestDate], [ExpectedEndingDate], [Supplier], [Job], [SubcontractOrdStatus],
                    [Currency], [FixingDate], [FixingIsManual], [Fixing], [Payment], [Cancelled],
                    [Delivered], [Paid], [AccTpl], [AccGroup], [CostCenter], [ContractCode],
                    [ProjectCode], [SupplierBank], [CompanyBank], [SupplierCA], [CompanyCA],
                    [Language], [PaymentAddress], [TaxJournal], [TaxCode], [Description],
                    [OurReference], [YourReference], [Notes], [Printed], [WithholdingPaymentDate],
                    [TBCreated], [TBModified], [TBCreatedID], [TBModifiedID], [OriginCostsSubcontract],
                    [CodeService], [NetOfTax], [TBGuid]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [SubcontractOrdId], [SubcontractOrdNo], [ExternalOrdNo], [OrderDate],
                    [ExpectedTestDate], [ExpectedEndingDate], [Supplier], [Job], [SubcontractOrdStatus],
                    [Currency], [FixingDate], [FixingIsManual], [Fixing], [Payment], [Cancelled],
                    [Delivered], [Paid], [AccTpl], [AccGroup], [CostCenter], [ContractCode],
                    [ProjectCode], [SupplierBank], [CompanyBank], [SupplierCA], [CompanyCA],
                    [Language], [PaymentAddress], [TaxJournal], [TaxCode], [Description],
                    [OurReference], [YourReference], [Notes], [Printed], [WithholdingPaymentDate],
                    [TBCreated], [TBModified], [TBCreatedID], [TBModifiedID], [OriginCostsSubcontract],
                    [CodeService], [NetOfTax], [TBGuid]
                FROM $sourceDb.dbo.IM_SubcontractOrd;


                INSERT INTO VedMaster.dbo.MM4_IM_SubcontractWorksProgressReport (
                    [Db], [SubcontractWPRId], [SubcontractWPRNo], [ExternalWPRNo], [SubcontractWPRDate],
                    [SubcontractOrdId], [Supplier], [Job], [SubcontractWPRStatus], [Currency],
                    [FixingDate], [FixingIsManual], [Fixing], [Payment], [Paid], [AccTpl],
                    [AccGroup], [CostCenter], [ContractCode], [ProjectCode], [SupplierBank],
                    [CompanyBank], [SupplierCA], [CompanyCA], [Language], [PaymentAddress],
                    [TaxJournal], [TaxCode], [Description], [ExternalDescription], [OurReference],
                    [YourReference], [Notes], [TBCreated], [TBModified], [TBCreatedID],
                    [TBModifiedID], [CRRefType], [CRRefID], [TBGuid]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [SubcontractWPRId], [SubcontractWPRNo], [ExternalWPRNo], [SubcontractWPRDate],
                    [SubcontractOrdId], [Supplier], [Job], [SubcontractWPRStatus], [Currency],
                    [FixingDate], [FixingIsManual], [Fixing], [Payment], [Paid], [AccTpl],
                    [AccGroup], [CostCenter], [ContractCode], [ProjectCode], [SupplierBank],
                    [CompanyBank], [SupplierCA], [CompanyCA], [Language], [PaymentAddress],
                    [TaxJournal], [TaxCode], [Description], [ExternalDescription], [OurReference],
                    [YourReference], [Notes], [TBCreated], [TBModified], [TBCreatedID],
                    [TBModifiedID], [CRRefType], [CRRefID], [TBGuid]
                FROM $sourceDb.dbo.IM_SubcontractWorksProgressReport;

                INSERT INTO VedMaster.dbo.MM4_IM_StatOfAccount (
                    [Db], [StatOfAccountId], [Job], [StatOfAccountNo], [Description], [CreationDate],
                    [IssueDate], [InvoiceDate], [Issued], [Invoiced], [Customer], [TotalAmount],
                    [GoodsTotalAmount], [ServicesTotalAmount], [LabourTotalAmount], [GoodsMarkupAmount],
                    [LabourMarkupAmount], [ServicesMarkupAmount], [GoodsDiscountsAmount],
                    [LabourDiscountsAmount], [ServicesDiscountsAmount], [GoodsNetAmount],
                    [ServicesNetAmount], [LabourNetAmount], [FurtherDiscount], [FurtherDiscountAmount],
                    [AllowancesAmount], [Currency], [FixingDate], [Fixing], [FixingIsManual],
                    [TotalAmountBaseCurr], [InvoicingGroupCode], [Printed], [TBCreated], [TBModified],
                    [OtherTotalAmount], [OtherMarkupAmount], [OtherDiscountsAmount], [OtherNetAmount],
                    [TotalCost], [GoodsTotalCost], [ServicesTotalCost], [LabourTotalCost],
                    [OtherTotalCost], [TotalMargin], [GoodsTotalMargin], [ServicesTotalMargin],
                    [LabourTotalMargin], [OtherTotalMargin], [TotalPercMargin], [GoodsTotalPercMargin],
                    [ServicesTotalPercMargin], [LabourTotalPercMargin], [OtherTotalPercMargin],
                    [TotalAmountOriginal], [TotalCostOriginal], [TotalMarginOriginal], [AddAmount],
                    [DeltaMargin], [chkGoods], [chkLabour], [chkServices], [chkOther], [RipAll],
                    [chkUseRip], [TBCreatedID], [TBModifiedID], [InvoicePreviewDate], [CRRefType],
                    [CRRefID], [TBGuid], [SentByEMail]
                )
                SELECT 
                    '$sourceDb' as [Db],
                    [StatOfAccountId], [Job], [StatOfAccountNo], [Description], [CreationDate],
                    [IssueDate], [InvoiceDate], [Issued], [Invoiced], [Customer], [TotalAmount],
                    [GoodsTotalAmount], [ServicesTotalAmount], [LabourTotalAmount], [GoodsMarkupAmount],
                    [LabourMarkupAmount], [ServicesMarkupAmount], [GoodsDiscountsAmount],
                    [LabourDiscountsAmount], [ServicesDiscountsAmount], [GoodsNetAmount],
                    [ServicesNetAmount], [LabourNetAmount], [FurtherDiscount], [FurtherDiscountAmount],
                    [AllowancesAmount], [Currency], [FixingDate], [Fixing], [FixingIsManual],
                    [TotalAmountBaseCurr], [InvoicingGroupCode], [Printed], [TBCreated], [TBModified],
                    [OtherTotalAmount], [OtherMarkupAmount], [OtherDiscountsAmount], [OtherNetAmount],
                    [TotalCost], [GoodsTotalCost], [ServicesTotalCost], [LabourTotalCost],
                    [OtherTotalCost], [TotalMargin], [GoodsTotalMargin], [ServicesTotalMargin],
                    [LabourTotalMargin], [OtherTotalMargin], [TotalPercMargin], [GoodsTotalPercMargin],
                    [ServicesTotalPercMargin], [LabourTotalPercMargin], [OtherTotalPercMargin],
                    [TotalAmountOriginal], [TotalCostOriginal], [TotalMarginOriginal], [AddAmount],
                    [DeltaMargin], [chkGoods], [chkLabour], [chkServices], [chkOther], [RipAll],
                    [chkUseRip], [TBCreatedID], [TBModifiedID], [InvoicePreviewDate], [CRRefType],
                    [CRRefID], [TBGuid], [SentByEMail]
                FROM $sourceDb.dbo.IM_StatOfAccount;
                

"@
                $command.CommandText = $ImportQuery
                $rowsAffected = $command.ExecuteNonQuery()
                Write-Host "Importazione da $sourceDb completata! Righe importate: $rowsAffected" -ForegroundColor Green
            }
            else {
                Write-Host "Attenzione: La tabella MA_Jobs non esiste nel database $sourceDb" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "Attenzione: Il database $sourceDb non esiste" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "Errore durante l'operazione:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    # Chiudere la connessione
    if ($connection.State -eq 'Open') {
        $connection.Close()
    }
}