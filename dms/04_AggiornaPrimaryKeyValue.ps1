# =============================================================================
# 04_AggiornaPrimaryKeyValue.ps1 - FASE 1
# Aggiorna PrimaryKeyValue sui cloni DMS con gli offset ERP
# Opera sui cloni: gpxnetdmsclone, furmanetdmsclone, vedbondifedmsclone
# vedcontabdmsclone e' la base (offset 0), non viene toccato
# =============================================================================

$ServerInstance = "192.168.0.3\SQL2008"
$SqlUsername = "sa"
$SqlPassword = "stream"

Add-Type -AssemblyName System.Data

function Execute-SqlNonQuery {
    param([string]$Query, [string]$Database)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 600
        $result = $cmd.ExecuteNonQuery()
        return $result
    }
    catch {
        Write-Host "    ERRORE: $_" -ForegroundColor Red
        return -1
    }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

function Invoke-SqlScalar {
    param([string]$Query, [string]$Database)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$Database;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
        $cmd.CommandTimeout = 300
        return $cmd.ExecuteScalar()
    }
    catch {
        Write-Host "    ERRORE: $_" -ForegroundColor Red
        return $null
    }
    finally { if ($conn -and $conn.State -eq 'Open') { $conn.Close() } }
}

# =============================================================================
# MAPPA OFFSET ERP PER IdType E DATABASE
# Derivata dall'analisi di TAG_CrMaps (script 02)
# =============================================================================

$OffsetMap = @{
    "gpxnetdmsclone" = @{
        "SaleDocId"          = 400000
        "PurchaseDocId"      = 100000
        "PurchaseOrdId"      = 100000
        "CustQuotaId"        = 100000
        "SuppQuotaId"        = 100000
        "EntryId"            = 1000000
        "WorkingReportId"    = 400000
    }
    "furmanetdmsclone" = @{
        "SaleDocId"          = 200000
        "PurchaseDocId"      = 200000
        "PurchaseOrdId"      = 200000
        "SuppQuotaId"        = 200000
        "EntryId"            = 500000
        "WorkingReportId"    = 1000000
        "JobQuotationId"     = 200000
        "MeasuresBookId"     = 200000
        "QuotationRequestId" = 500000
        "PurchaseRequestId"  = 500000
        "SaleOrdId"          = 200000
    }
    "vedbondifedmsclone" = @{
        "SaleDocId"          = 300000
        "PurchaseDocId"      = 300000
        "PurchaseOrdId"      = 300000
        "CustQuotaId"        = 300000
        "SuppQuotaId"        = 300000
        "EntryId"            = 600000
        "WorkingReportId"    = 600000
        "JobQuotationId"     = 300000
        "MeasuresBookId"     = 300000
        "QuotationRequestId" = 600000
        "SaleOrdId"          = 300000
    }
}

# Tipi che NON richiedono rimappatura
# JournalEntryId, PymtSchedId, FeeId: solo vedcontab (base)
# Item, Employee, Job, CustSuppType, Specification, CompanyId: codici stringa
# IdRam: non rinumerato
# SaleOrdId su gpxnet: escluso dalla rinumerazione (unica sorgente ordini)

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "FASE 1: AGGIORNAMENTO PrimaryKeyValue SUI CLONI DMS" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

foreach ($dmsClone in $OffsetMap.Keys | Sort-Object) {
    Write-Host "`n$("=" * 60)" -ForegroundColor Yellow
    Write-Host "DATABASE: $dmsClone" -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Yellow

    $offsets = $OffsetMap[$dmsClone]

    foreach ($idType in $offsets.Keys | Sort-Object) {
        $offset = $offsets[$idType]
        $likePattern = "${idType}:%"

        # Conta record da aggiornare
        $countQuery = "SELECT COUNT(*) FROM dbo.DMS_ErpDocument WHERE PrimaryKeyValue LIKE '$likePattern'"
        $count = Invoke-SqlScalar -Query $countQuery -Database $dmsClone

        if ($count -eq 0 -or $count -eq $null) {
            Write-Host "  $idType : 0 record - skip" -ForegroundColor DarkGray
            continue
        }

        Write-Host "  $idType : $count record, offset +$offset" -ForegroundColor White

        # UPDATE PrimaryKeyValue applicando l'offset al valore numerico
        # Pattern: "IdType:valore;" -> "IdType:(valore+offset);"
        # Gestisce solo pattern semplici con un solo campo
        $updateQuery = @"
UPDATE dbo.DMS_ErpDocument
SET PrimaryKeyValue =
    '$idType' + ':' +
    CAST(
        CAST(
            SUBSTRING(
                PrimaryKeyValue,
                CHARINDEX(':', PrimaryKeyValue) + 1,
                CHARINDEX(';', PrimaryKeyValue) - CHARINDEX(':', PrimaryKeyValue) - 1
            ) AS INT
        ) + $offset
    AS VARCHAR(20)) + ';'
WHERE PrimaryKeyValue LIKE '$likePattern'
  AND CHARINDEX(';', PrimaryKeyValue) > 0
  AND CHARINDEX(':', PrimaryKeyValue) > 0
  AND PrimaryKeyValue NOT LIKE '%:%:%'
  AND ISNUMERIC(
        SUBSTRING(
            PrimaryKeyValue,
            CHARINDEX(':', PrimaryKeyValue) + 1,
            CHARINDEX(';', PrimaryKeyValue) - CHARINDEX(':', PrimaryKeyValue) - 1
        )
      ) = 1
"@

        $updated = Execute-SqlNonQuery -Query $updateQuery -Database $dmsClone
        if ($updated -ge 0) {
            Write-Host "    Aggiornati: $updated record" -ForegroundColor Green
            if ($updated -ne $count) {
                $skipped = $count - $updated
                Write-Host "    Saltati: $skipped record (pattern non standard o non numerico)" -ForegroundColor Yellow
            }
        }
    }

    # Report record non rimappati (per verifica)
    Write-Host "`n  --- Verifica record NON rimappati ---" -ForegroundColor DarkGray
    $noRemapQuery = @"
SELECT
    CASE
        WHEN CHARINDEX(':', PrimaryKeyValue) > 0
        THEN LEFT(PrimaryKeyValue, CHARINDEX(':', PrimaryKeyValue) - 1)
        ELSE '(altro)'
    END AS IdType,
    COUNT(*) AS Cnt
FROM dbo.DMS_ErpDocument
WHERE ISNULL(PrimaryKeyValue, '') != ''
GROUP BY
    CASE
        WHEN CHARINDEX(':', PrimaryKeyValue) > 0
        THEN LEFT(PrimaryKeyValue, CHARINDEX(':', PrimaryKeyValue) - 1)
        ELSE '(altro)'
    END
ORDER BY Cnt DESC
"@
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$ServerInstance;Database=$dmsClone;User Id=$SqlUsername;Password=$SqlPassword;"
    try {
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($noRemapQuery, $conn)
        $cmd.CommandTimeout = 300
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $it = $reader["IdType"]
            $cnt = $reader["Cnt"]
            $wasRemapped = $offsets.ContainsKey([string]$it)
            $status = if ($wasRemapped) { "RIMAPPATO" } else { "invariato" }
            $color = if ($wasRemapped) { "Green" } else { "DarkGray" }
            Write-Host ("    {0,-25} {1,8} record  [{2}]" -f $it, $cnt, $status) -ForegroundColor $color
        }
        $reader.Close()
    }
    finally { if ($conn.State -eq 'Open') { $conn.Close() } }
}

Write-Host "`n"
Write-Host ("=" * 80) -ForegroundColor Green
Write-Host "FASE 1 COMPLETATA - PrimaryKeyValue aggiornati" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Green
