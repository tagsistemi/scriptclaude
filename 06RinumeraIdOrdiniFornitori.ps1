# Usa $PSScriptRoot combinato con il nome della sottocartella
$scriptPath = Join-Path $PSScriptRoot "06rinumeraIdordinifornitori"  # dove "scripts" è il nome della tua sottocartella
# Lista degli script da eseguire in ordine
$scripts = @(
    "01disableconstraints.ps1",
    "02rinumeraIdordinifornitoriCr.ps1",
    "03enableconstraints.ps1"
)

# Esegui gli script in sequenza
foreach ($script in $scripts) {
    Write-Host "Executing $script..." -ForegroundColor Yellow
    try {
        & "$scriptPath\$script"
        Write-Host "Successfully completed $script" -ForegroundColor Green
    }
    catch {
        Write-Host "Error executing ${script}:" -ForegroundColor Red
        # Decommentare la linea seguente se vuoi che si fermi al primo errore
        # break
    }
    Write-Host "----------------------------------------"
}

Write-Host "All scripts execution completed."