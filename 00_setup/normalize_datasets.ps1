$ErrorActionPreference = 'Stop'

$raiz = Split-Path -Parent $PSScriptRoot
$datasets = Join-Path $raiz '01_datasets'

$archivos = Get-ChildItem $datasets -Recurse -Filter *.csv
foreach ($archivo in $archivos) {
    $bytes = [System.IO.File]::ReadAllBytes($archivo.FullName)

    if ($bytes.Length -eq 0) {
        Write-Host "OMITIDO (vacio): $($archivo.Name)"
        continue
    }

    if ($bytes.Length -ge 2 -and $bytes[-2] -eq 13 -and $bytes[-1] -eq 10) {
        Write-Host "OK: $($archivo.Name)"
        continue
    }

    $final = if ($bytes[-1] -eq 10) { [byte[]](13) } else { [byte[]](13, 10) }

    $stream = [System.IO.File]::Open($archivo.FullName, 'Append', 'Write')
    try {
        $stream.Write($final, 0, $final.Length)
    }
    finally {
        $stream.Dispose()
    }

    Write-Host "CORREGIDO: $($archivo.Name)"
}

Write-Host ''
Write-Host 'Normalizacion finalizada. Vuelve a ejecutar EXEC bronze.load_bronze;'
