--documenti di vendita
select max(saledocid) from VEDMaster.dbo.ma_saledoc
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801088
--intrastat
select max(IntrastatId) from VEDMaster.dbo.MA_Intra
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801091
--movimenti di magazzino
select max(EntryId) from VEDMaster.dbo.MA_InventoryEntries
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801093
--ordini clienti
select max(SaleOrdId) from VEDMaster.dbo.MA_SaleOrd
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801098
--offerte clienti
select max(CustQuotaId) from VEDMaster.dbo.MA_CustQuotas
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801099
--ordini fornitori
select max(PurchaseOrdId) from VEDMaster.dbo.MA_PurchaseOrd
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801100
--acquisti
select max(PurchaseDocId) from VEDMaster.dbo.MA_PurchaseDoc
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801108
--offerte fornitore
select max(SuppQuotaId) from VEDMaster.dbo.MA_SuppQuotas
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801109
--lifo/fifo
select max(ReceiptBatchId) from VEDMaster.dbo.MA_ReceiptsBatch
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801115

--PERFETTO

--rda
select max(PurchaseRequestId) from VEDMaster.dbo.IM_PurchaseRequest
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801104
--rapportini
select max(WorkingReportId) from VEDMaster.dbo.IM_WorkingReports
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801188
--libretti misure (da creare)
select max(MeasuresBookId) from VEDMaster.dbo.IM_MeasuresBooks
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801290
--Sal (da creare)
select max(WPRId) from VEDMaster.dbo.IM_WorksProgressReport
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801291
--Estratto conto (da creare)
select max(StatOfAccountId) from VEDMaster.dbo.IM_StatOfAccount
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801292
--Richieste offerta cliente (da creare)
select max(QuotationRequestId) from VEDMaster.dbo.IM_QuotationRequests
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801318
--Richieste Jobs (da creare)
select max(IM_JobId) from VEDMaster.dbo.MA_Jobs
select * from VEDMaster.dbo.MA_IDNumbers where CodeTYpe = 3801316
