# ============================================
# SCRIPT: Verifica TAG_CrMaps
# ============================================
# Versione: 1.0
# Data: 2025-01-29
# Descrizione: Verifica lo stato delle mappature ID in TAG_CrMaps
#              e identifica eventuali problemi prima dell'aggiornamento CrossReferences
# ============================================

# Carica la configurazione
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\00_Config.ps1"

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  VERIFICA TAG_CrMaps" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

$issues = @()
$warnings = @()

foreach ($db in $Global:CloneDatabases) {
    Write-ColorOutput "Analizzando database: $db" "Yellow"
    $offset = Get-DatabaseOffset -DatabaseName $db
    Write-ColorOutput "  Offset atteso: $offset" "Gray"

    # Verifica esistenza tabella TAG_CrMaps
    if (-not (Test-TableExists -Database $db -TableName "TAG_CrMaps")) {
        $issues += "[$db] Tabella TAG_CrMaps NON ESISTE!"
        Write-ColorOutput "  TAG_CrMaps: NON ESISTE" "Red"
        continue
    }

    # Conta record totali
    $totalCount = Execute-SqlScalar -Query "SELECT COUNT(*) FROM $db.dbo.TAG_CrMaps"
    Write-ColorOutput "  Record totali in TAG_CrMaps: $totalCount" "White"

    if ($totalCount -eq 0) {
        $issues += "[$db] TAG_CrMaps e' VUOTA!"
        Write-ColorOutput "  ATTENZIONE: Tabella vuota!" "Red"
        continue
    }

    # Analisi per DocumentType
    $queryByType = @"
SELECT
    DocumentType,
    COUNT(*) as RecordCount,
    MIN(OldId) as MinOldId,
    MAX(OldId) as MaxOldId,
    MIN(NewDocId) as MinNewId,
    MAX(NewDocId) as MaxNewId
FROM $db.dbo.TAG_CrMaps
GROUP BY DocumentType
ORDER BY DocumentType
"@

    $dataByType = Execute-SqlReader -Query $queryByType -Database $db

    if ($dataByType -and $dataByType.Rows.Count -gt 0) {
        Write-ColorOutput "  Distribuzione per DocumentType:" "White"

        foreach ($row in $dataByType.Rows) {
            $docType = $row.DocumentType
            $count = $row.RecordCount
            $minOld = $row.MinOldId
            $maxOld = $row.MaxOldId
            $minNew = $row.MinNewId
            $maxNew = $row.MaxNewId

            # Verifica che l'offset sia corretto
            $expectedMinNew = $minOld + $offset
            $expectedMaxNew = $maxOld + $offset

            $offsetOK = ($minNew -eq $expectedMinNew) -and ($maxNew -eq $expectedMaxNew)
            $status = if ($offsetOK) { "[OK]" } else { "[!!]" }
            $color = if ($offsetOK) { "Green" } else { "Red" }

            Write-ColorOutput "    DocType $docType : $count record (Old: $minOld-$maxOld -> New: $minNew-$maxNew) $status" $color

            if (-not $offsetOK) {
                $warnings += "[$db] DocType $docType: Offset non corretto. Atteso +$offset, trovato differenza di $($minNew - $minOld)"
            }
        }
    }

    # Verifica DocumentTypes presenti vs attesi
    $queryDocTypes = "SELECT DISTINCT DocumentType FROM $db.dbo.TAG_CrMaps"
    $presentTypes = Execute-SqlReader -Query $queryDocTypes -Database $db

    $presentTypesList = @()
    if ($presentTypes -and $presentTypes.Rows.Count -gt 0) {
        foreach ($row in $presentTypes.Rows) {
            $presentTypesList += $row.DocumentType
        }
    }

    Write-ColorOutput "  DocumentTypes presenti: $($presentTypesList.Count)" "White"

    # Verifica cross-reference con TAG_DocumentTypesCr
    if (Test-TableExists -Database $db -TableName "TAG_DocumentTypesCr") {
        $queryMissingMap = @"
SELECT DISTINCT cm.DocumentType
FROM $db.dbo.TAG_CrMaps cm
LEFT JOIN $db.dbo.TAG_DocumentTypesCr dt ON dt.EnumValue = cm.DocumentType
WHERE dt.EnumValue IS NULL
"@
        $missingMaps = Execute-SqlReader -Query $queryMissingMap -Database $db

        if ($missingMaps -and $missingMaps.Rows.Count -gt 0) {
            Write-ColorOutput "  DocumentTypes in TAG_CrMaps senza mappatura in TAG_DocumentTypesCr:" "Yellow"
            foreach ($row in $missingMaps.Rows) {
                Write-ColorOutput "    - $($row.DocumentType)" "Yellow"
                $warnings += "[$db] DocumentType $($row.DocumentType) non ha mappatura in TAG_DocumentTypesCr"
            }
        }
        else {
            Write-ColorOutput "  Tutti i DocumentTypes hanno mappatura in TAG_DocumentTypesCr" "Green"
        }
    }
    else {
        $issues += "[$db] Tabella TAG_DocumentTypesCr NON ESISTE! Eseguire prima 01_CreaMappaDocTypeCompleta.ps1"
        Write-ColorOutput "  TAG_DocumentTypesCr: NON ESISTE" "Red"
    }

    Write-Host ""
}

# Verifica consistenza cross-database
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  VERIFICA CONSISTENZA TRA DATABASE" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

# Controlla se ci sono range di ID che si sovrappongono
$allRanges = @()

foreach ($db in $Global:CloneDatabases) {
    if (Test-TableExists -Database $db -TableName "TAG_CrMaps") {
        $queryRanges = @"
SELECT
    DocumentType,
    MIN(NewDocId) as MinNewId,
    MAX(NewDocId) as MaxNewId
FROM $db.dbo.TAG_CrMaps
GROUP BY DocumentType
"@
        $ranges = Execute-SqlReader -Query $queryRanges -Database $db

        if ($ranges -and $ranges.Rows.Count -gt 0) {
            foreach ($row in $ranges.Rows) {
                $allRanges += [PSCustomObject]@{
                    Database = $db
                    DocumentType = $row.DocumentType
                    MinNewId = $row.MinNewId
                    MaxNewId = $row.MaxNewId
                }
            }
        }
    }
}

# Cerca sovrapposizioni
$overlaps = @()
for ($i = 0; $i -lt $allRanges.Count; $i++) {
    for ($j = $i + 1; $j -lt $allRanges.Count; $j++) {
        $r1 = $allRanges[$i]
        $r2 = $allRanges[$j]

        if ($r1.DocumentType -eq $r2.DocumentType) {
            # Stesso DocumentType - verifica sovrapposizione
            if (($r1.MinNewId -le $r2.MaxNewId) -and ($r2.MinNewId -le $r1.MaxNewId)) {
                $overlaps += "DocType $($r1.DocumentType): $($r1.Database) ($($r1.MinNewId)-$($r1.MaxNewId)) si sovrappone con $($r2.Database) ($($r2.MinNewId)-$($r2.MaxNewId))"
            }
        }
    }
}

if ($overlaps.Count -gt 0) {
    Write-ColorOutput "SOVRAPPOSIZIONI RILEVATE:" "Red"
    foreach ($overlap in $overlaps) {
        Write-ColorOutput "  - $overlap" "Red"
        $issues += $overlap
    }
}
else {
    Write-ColorOutput "Nessuna sovrapposizione di range rilevata" "Green"
}

Write-Host ""

# Riepilogo finale
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  RIEPILOGO VERIFICA" "Cyan"
Write-ColorOutput "============================================" "Cyan"
Write-Host ""

if ($issues.Count -gt 0) {
    Write-ColorOutput "PROBLEMI CRITICI ($($issues.Count)):" "Red"
    foreach ($issue in $issues) {
        Write-ColorOutput "  - $issue" "Red"
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-ColorOutput "AVVISI ($($warnings.Count)):" "Yellow"
    foreach ($warning in $warnings) {
        Write-ColorOutput "  - $warning" "Yellow"
    }
    Write-Host ""
}

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-ColorOutput "Nessun problema rilevato. TAG_CrMaps e' pronta per l'aggiornamento dei CrossReferences." "Green"
}
elseif ($issues.Count -eq 0) {
    Write-ColorOutput "TAG_CrMaps presenta alcuni avvisi ma puo' essere usata." "Yellow"
}
else {
    Write-ColorOutput "ATTENZIONE: Risolvere i problemi critici prima di procedere!" "Red"
}

Write-Host ""
Write-ColorOutput "============================================" "Cyan"
Write-ColorOutput "  VERIFICA COMPLETATA" "Cyan"
Write-ColorOutput "============================================" "Cyan"
