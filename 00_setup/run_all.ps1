param(
    [string]$Servidor = 'localhost'
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$scripts = Join-Path $raiz '03_scripts'
$tests = Join-Path $raiz '04_tests'

function Invoke-Sql {
    param([string]$Ruta)

    & sqlcmd -S $Servidor -E -C -b -i $Ruta
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo al ejecutar: $Ruta"
    }
}

Write-Host '=== 1/7 Normalizando datasets ===' -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'normalize_datasets.ps1')

Write-Host '=== 2/7 Creando base de datos y esquemas ===' -ForegroundColor Cyan
Invoke-Sql (Join-Path $scripts 'init_database.sql')

Write-Host '=== 3/7 Creando objetos de Bronze ===' -ForegroundColor Cyan
Invoke-Sql (Join-Path $scripts 'bronze\ddl_bronze.sql')
Invoke-Sql (Join-Path $scripts 'bronze\proc_load_bronze.sql')

Write-Host '=== 4/7 Creando objetos de Silver ===' -ForegroundColor Cyan
Invoke-Sql (Join-Path $scripts 'silver\ddl_silver.sql')
Invoke-Sql (Join-Path $scripts 'silver\proc_load_silver.sql')

Write-Host '=== 5/7 Creando vistas de Gold ===' -ForegroundColor Cyan
Invoke-Sql (Join-Path $scripts 'gold\ddl_gold.sql')

Write-Host '=== 6/7 Cargando datos ===' -ForegroundColor Cyan
Invoke-Sql (Join-Path $scripts 'run_pipeline.sql')

Write-Host '=== 7/7 Validando calidad ===' -ForegroundColor Cyan
Invoke-Sql (Join-Path $tests 'quality_checks_silver.sql')
Invoke-Sql (Join-Path $tests 'quality_checks_gold.sql')

Write-Host ''
Write-Host '=== Resumen de filas ===' -ForegroundColor Cyan
& sqlcmd -S $Servidor -E -C -d DataWarehouse -W -Q @"
SET NOCOUNT ON;
SELECT 'bronze.crm_cust_info' AS objeto, COUNT(*) AS filas FROM bronze.crm_cust_info
UNION ALL SELECT 'bronze.crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL SELECT 'bronze.crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL SELECT 'bronze.erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
UNION ALL SELECT 'bronze.erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
UNION ALL SELECT 'bronze.erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2
UNION ALL SELECT 'silver.crm_cust_info', COUNT(*) FROM silver.crm_cust_info
UNION ALL SELECT 'silver.crm_prd_info', COUNT(*) FROM silver.crm_prd_info
UNION ALL SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'silver.erp_cust_az12', COUNT(*) FROM silver.erp_cust_az12
UNION ALL SELECT 'silver.erp_loc_a101', COUNT(*) FROM silver.erp_loc_a101
UNION ALL SELECT 'silver.erp_px_cat_g1v2', COUNT(*) FROM silver.erp_px_cat_g1v2
UNION ALL SELECT 'gold.dim_customers', COUNT(*) FROM gold.dim_customers
UNION ALL SELECT 'gold.dim_products', COUNT(*) FROM gold.dim_products
UNION ALL SELECT 'gold.fact_sales', COUNT(*) FROM gold.fact_sales;
"@

Write-Host ''
Write-Host 'Proyecto ejecutado y validado correctamente.' -ForegroundColor Green
