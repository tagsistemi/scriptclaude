# ============================================
# DIAGNOSTICA Cross-References per Fatture sui DB clone
# ============================================
# Scopo: Verificare lo stato dei riferimenti incrociati per le fatture
# ============================================

$serverName = "192.168.0.3\SQL2008"
$userName = "sa"
$password = "stream"

$databases = @("furmanetclone", "gpxnetclone", "vedbondifeclone")

# ReferenceCode per fatture in MA_CrossReferences
$fattureRefCodes = @(
    27066385,  # Fattura Accompagnatoria
    27066386,  # Fattura Accompagnatoria a Correzione
    27066387,  # Fattura Immediata
    27066388,  # Fattura a Correzione
    27066389,  # Nota di Credito
    27066390,  # Nota di Debito
    27066396,  # Fattura di Acconto
    27066397   # Fattura ProForma
)
$fattureRefCodesSQL = $fattureRefCodes -join ", "

# EnumValue (Specie Archivio) per fatture in TAG_CrMaps
$fattureEnumValues = @(
    3801091,  # Fattura Accompagnatoria
    3801094,  # Fattura Accompagnatoria a Correzione
    3801095,  # Fattura Immediata
    3801096,  # Fattura a Correzione
    3801097,  # Nota di Credito
    3801101,  # Nota di Debito
    3801102,  # Fattura di Acconto
    3801103   # Fattura ProForma
)
$fattureEnumValuesSQL = $fattureEnumValues -join ", "

# Tutti i SaleDoc EnumValues (DDT + fatture + resi ecc.)
$allSaleDocEnumValues = @(
    3801088, 3801089, 3801090, 3801091, 3801094, 3801095, 3801096,
    3801097, 3801101, 3801102, 3801103, 3801104, 3801105, 3801106,
    3801107, 3801108, 3801110
)
$allSaleDocEnumSQL = $allSaleDocEnumValues -join ", "

# Tutti i SaleDoc ReferenceCode
$allSaleDocRefCodes = @(
    27066383, 27066384, 27066385, 27066386, 27066387, 27066388, 27066389,
    27066390, 27066391, 27066392, 27066393, 27066394, 27066395, 27066396,
    27066397, 27066398, 27066382, 27066381
)
$allSaleDocRefSQL = $allSaleDocRefCodes -join ", "

function Execute-SqlReader {
    param ([string]$query, [string]$connString)
    $results = @()
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 300
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $row = @{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $row[$reader.GetName($i)] = $reader.GetValue($i)
            }
            $results += [PSCustomObject]$row
        }
        $reader.Close()
        $conn.Close()
    } catch {
        Write-Host "  ERRORE: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
    }
    return $results
}

function Execute-SqlScalar {
    param ([string]$query, [string]$connString)
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $cmd.CommandTimeout = 300
        $result = $cmd.ExecuteScalar()
        $conn.Close()
        return $result
    } catch {
        Write-Host "  ERRORE: $_" -ForegroundColor Red
        if ($conn -and $conn.State -eq 'Open') { $conn.Close() }
        return $null
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTICA CROSS-REFERENCES FATTURE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

foreach ($db in $databases) {
    $connString = "Server=$serverName;Database=$db;User ID=$userName;Password=$password;"

    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "  DATABASE: $db" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host ""

    # ---- CHECK 1: TAG_CrMaps esiste? ----
    Write-Host "  --- CHECK 1: TAG_CrMaps ---" -ForegroundColor Cyan
    $tagExists = Execute-SqlScalar -query "SELECT COUNT(*) FROM sys.objects WHERE object_id = OBJECT_ID(N'TAG_CrMaps') AND type = 'U'" -connString $connString
    if ($tagExists -eq 0) {
        Write-Host "  TAG_CrMaps NON ESISTE!" -ForegroundColor Red
        Write-Host ""
        continue
    }

    $totalCrMaps = Execute-SqlScalar -query "SELECT COUNT(*) FROM TAG_CrMaps" -connString $connString
    Write-Host "  TAG_CrMaps totale record: $totalCrMaps" -ForegroundColor White

    # Quanti per tipo SaleDoc (tutti)?
    $saleDocCrMaps = Execute-SqlScalar -query "SELECT COUNT(*) FROM TAG_CrMaps WHERE DocumentType IN ($allSaleDocEnumSQL)" -connString $connString
    Write-Host "  TAG_CrMaps SaleDoc (tutti i tipi): $saleDocCrMaps" -ForegroundColor $(if ($saleDocCrMaps -gt 0) { "Green" } else { "Red" })

    # Quanti per tipo fattura specifico?
    $fattureCrMaps = Execute-SqlScalar -query "SELECT COUNT(*) FROM TAG_CrMaps WHERE DocumentType IN ($fattureEnumValuesSQL)" -connString $connString
    Write-Host "  TAG_CrMaps FATTURE (solo tipi fattura): $fattureCrMaps" -ForegroundColor $(if ($fattureCrMaps -gt 0) { "Green" } else { "Red" })

    # Distribuzione per DocumentType
    $crMapsByType = Execute-SqlReader -query @"
    SELECT cm.DocumentType, dt.Description, COUNT(*) as Cnt
    FROM TAG_CrMaps cm
    LEFT JOIN TAG_DocumentTypesCr dt ON dt.EnumValue = cm.DocumentType
    GROUP BY cm.DocumentType, dt.Description
    ORDER BY cm.DocumentType
"@ -connString $connString

    if ($crMapsByType) {
        Write-Host "  Distribuzione TAG_CrMaps per tipo:" -ForegroundColor Gray
        foreach ($row in $crMapsByType) {
            $desc = if ($row.Description) { $row.Description } else { "???" }
            $isFattura = if ($fattureEnumValues -contains $row.DocumentType) { " <-- FATTURA" } else { "" }
            Write-Host "    $($row.DocumentType) ($desc): $($row.Cnt)$isFattura" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # ---- CHECK 2: TAG_DocumentTypesCr ----
    Write-Host "  --- CHECK 2: TAG_DocumentTypesCr ---" -ForegroundColor Cyan
    $dtExists = Execute-SqlScalar -query "SELECT COUNT(*) FROM sys.objects WHERE object_id = OBJECT_ID(N'TAG_DocumentTypesCr') AND type = 'U'" -connString $connString
    if ($dtExists -eq 0) {
        Write-Host "  TAG_DocumentTypesCr NON ESISTE!" -ForegroundColor Red
        Write-Host ""
        continue
    }

    $fattureInDocTypes = Execute-SqlReader -query @"
    SELECT EnumValue, ReferenceCode, Description
    FROM TAG_DocumentTypesCr
    WHERE EnumValue IN ($fattureEnumValuesSQL)
    ORDER BY EnumValue
"@ -connString $connString

    if ($fattureInDocTypes.Count -gt 0) {
        Write-Host "  Tipi fattura presenti in TAG_DocumentTypesCr: $($fattureInDocTypes.Count)" -ForegroundColor Green
    } else {
        Write-Host "  NESSUN tipo fattura in TAG_DocumentTypesCr!" -ForegroundColor Red
    }
    Write-Host ""

    # ---- CHECK 3: MA_SaleDoc - fatture ----
    Write-Host "  --- CHECK 3: MA_SaleDoc (fatture) ---" -ForegroundColor Cyan
    $fatturePerType = Execute-SqlReader -query @"
    SELECT DocumentType, COUNT(*) as Cnt, MIN(SaleDocId) as MinId, MAX(SaleDocId) as MaxId
    FROM MA_SaleDoc
    WHERE DocumentType IN (3407874, 3407875, 3407876, 3407877, 3407883, 3407885, 3407886)
    GROUP BY DocumentType ORDER BY DocumentType
"@ -connString $connString

    if ($fatturePerType) {
        foreach ($row in $fatturePerType) {
            $typeName = switch ($row.DocumentType) {
                3407874 { "Fatt. Accompagnatoria" }
                3407875 { "Fatt. Immediata" }
                3407876 { "Nota di Credito" }
                3407877 { "Nota di Debito" }
                3407883 { "Fatt. di Acconto" }
                3407885 { "Fatt. Acc. a Correzione" }
                3407886 { "Fatt. a Correzione" }
                default { "Tipo $($row.DocumentType)" }
            }
            Write-Host "    $typeName (${$row.DocumentType}): $($row.Cnt) docs, ID range $($row.MinId)-$($row.MaxId)" -ForegroundColor White
        }
    } else {
        Write-Host "  NESSUNA fattura in MA_SaleDoc!" -ForegroundColor Red
    }
    Write-Host ""

    # ---- CHECK 4: Cross-references per fatture ----
    Write-Host "  --- CHECK 4: MA_CrossReferences per fatture ---" -ForegroundColor Cyan

    # Come DerivedDoc (fattura e destinazione: DDT -> Fattura)
    $crAsDerived = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM MA_CrossReferences
    WHERE DerivedDocType IN ($fattureRefCodesSQL)
"@ -connString $connString
    Write-Host "  CrossRef con fattura come DERIVED (es. DDT->Fattura): $crAsDerived" -ForegroundColor $(if ($crAsDerived -gt 0) { "Green" } else { "Red" })

    # Come OriginDoc (fattura e origine: Fattura -> NdC)
    $crAsOrigin = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM MA_CrossReferences
    WHERE OriginDocType IN ($fattureRefCodesSQL)
"@ -connString $connString
    Write-Host "  CrossRef con fattura come ORIGIN (es. Fattura->NdC): $crAsOrigin" -ForegroundColor $(if ($crAsOrigin -gt 0) { "Green" } else { "Red" })

    # Totale CrossRef per SaleDoc types (tutti, non solo fatture)
    $crAllSaleDoc = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM MA_CrossReferences
    WHERE OriginDocType IN ($allSaleDocRefSQL) OR DerivedDocType IN ($allSaleDocRefSQL)
"@ -connString $connString
    Write-Host "  CrossRef con qualsiasi SaleDoc type (DDT, fatture, resi...): $crAllSaleDoc" -ForegroundColor White

    # Distribuzione per tipo nei cross-ref
    $crDistrib = Execute-SqlReader -query @"
    SELECT 'Origin' as Side, OriginDocType as DocType, COUNT(*) as Cnt
    FROM MA_CrossReferences
    WHERE OriginDocType IN ($allSaleDocRefSQL)
    GROUP BY OriginDocType
    UNION ALL
    SELECT 'Derived' as Side, DerivedDocType as DocType, COUNT(*) as Cnt
    FROM MA_CrossReferences
    WHERE DerivedDocType IN ($allSaleDocRefSQL)
    GROUP BY DerivedDocType
    ORDER BY Side, DocType
"@ -connString $connString

    if ($crDistrib) {
        Write-Host "  Distribuzione CrossRef SaleDoc per tipo:" -ForegroundColor Gray
        foreach ($row in $crDistrib) {
            $isFattura = if ($fattureRefCodes -contains $row.DocType) { " <-- FATTURA" } else { "" }
            Write-Host "    $($row.Side) $($row.DocType): $($row.Cnt)$isFattura" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # ---- CHECK 5: Orfani - DerivedDocID che non esistono in MA_SaleDoc ----
    Write-Host "  --- CHECK 5: Orfani (ID che non matchano MA_SaleDoc) ---" -ForegroundColor Cyan
    $orphanDerived = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM MA_CrossReferences cr
    WHERE cr.DerivedDocType IN ($fattureRefCodesSQL)
      AND NOT EXISTS (SELECT 1 FROM MA_SaleDoc sd WHERE sd.SaleDocId = cr.DerivedDocID)
"@ -connString $connString
    Write-Host "  Fatture DerivedDocID orfani: $orphanDerived" -ForegroundColor $(if ($orphanDerived -eq 0) { "Green" } else { "Red" })

    $orphanOrigin = Execute-SqlScalar -query @"
    SELECT COUNT(*) FROM MA_CrossReferences cr
    WHERE cr.OriginDocType IN ($fattureRefCodesSQL)
      AND NOT EXISTS (SELECT 1 FROM MA_SaleDoc sd WHERE sd.SaleDocId = cr.OriginDocID)
"@ -connString $connString
    Write-Host "  Fatture OriginDocID orfani: $orphanOrigin" -ForegroundColor $(if ($orphanOrigin -eq 0) { "Green" } else { "Red" })

    # ---- CHECK 6: Campione cross-ref fatture ----
    Write-Host ""
    Write-Host "  --- CHECK 6: Campione CrossRef fatture ---" -ForegroundColor Cyan
    $sample = Execute-SqlReader -query @"
    SELECT TOP 5
        cr.OriginDocType, cr.OriginDocID,
        cr.DerivedDocType, cr.DerivedDocID,
        sd_o.DocNo as OriginDocNo, sd_o.DocumentType as OriginSaleDocType,
        sd_d.DocNo as DerivedDocNo, sd_d.DocumentType as DerivedSaleDocType
    FROM MA_CrossReferences cr
    LEFT JOIN MA_SaleDoc sd_o ON sd_o.SaleDocId = cr.OriginDocID
    LEFT JOIN MA_SaleDoc sd_d ON sd_d.SaleDocId = cr.DerivedDocID
    WHERE cr.DerivedDocType IN ($fattureRefCodesSQL)
       OR cr.OriginDocType IN ($fattureRefCodesSQL)
"@ -connString $connString

    if ($sample.Count -gt 0) {
        foreach ($row in $sample) {
            $originMatch = if ($row.OriginDocNo) { "OK ($($row.OriginDocNo))" } else { "ORFANO!" }
            $derivedMatch = if ($row.DerivedDocNo) { "OK ($($row.DerivedDocNo))" } else { "ORFANO!" }
            Write-Host "    Origin: $($row.OriginDocType)/$($row.OriginDocID) [$originMatch] -> Derived: $($row.DerivedDocType)/$($row.DerivedDocID) [$derivedMatch]" -ForegroundColor White
        }
    } else {
        Write-Host "    NESSUN cross-reference trovato per fatture!" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  FINE DIAGNOSTICA" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
