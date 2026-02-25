$serverInstance = "192.168.0.3\SQL2008"
$username = "sa" 
$password = "stream"

Write-Host "DIAGNOSTICA PROBLEMI MIGRAZIONE" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Confronto strutture MA_PurchaseDocSummary
Write-Host "`nStruttura MA_PurchaseDocSummary in gpxnetclone:" -ForegroundColor Yellow
$query = "SELECT TOP 10 COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MA_PurchaseDocSummary' ORDER BY ORDINAL_POSITION"
sqlcmd -S $serverInstance -U $username -P $password -d gpxnetclone -Q $query

Write-Host "`nStruttura MA_PurchaseDocSummary in VEDMaster:" -ForegroundColor Yellow  
sqlcmd -S $serverInstance -U $username -P $password -d VEDMaster -Q $query

# Test query problematica
Write-Host "`nTEST QUERY SEMPLIFICATA:" -ForegroundColor Green
$testQuery = "INSERT INTO MA_PurchaseDocSummary (PurchaseDocId, TaxableAmount) SELECT TOP 1 PurchaseDocId, TaxableAmount FROM [gpxnetclone].dbo.MA_PurchaseDocSummary"

try {
    sqlcmd -S $serverInstance -U $username -P $password -d VEDMaster -Q $testQuery
    Write-Host "Query semplificata OK!" -ForegroundColor Green
} catch {
    Write-Host "Errore anche in query semplificata: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nVerifica colonne problematiche:" -ForegroundColor Magenta
$checkQuery = "SELECT TOP 1 PurchaseDocId, PaymentTerm, StatisticalChargesCalc FROM [gpxnetclone].dbo.MA_PurchaseDocSummary"
sqlcmd -S $serverInstance -U $username -P $password -d VEDMaster -Q $checkQuery
