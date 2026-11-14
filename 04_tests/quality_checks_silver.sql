USE DataWarehouse;
GO

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#resultados') IS NOT NULL
    DROP TABLE #resultados;

CREATE TABLE #resultados (
    orden       INT IDENTITY(1, 1),
    chequeo     NVARCHAR(200),
    esperado    NVARCHAR(100),
    obtenido    NVARCHAR(100),
    estado      NVARCHAR(10)
);

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Clientes sin cst_id (nulos o vacíos)',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_cust_info
WHERE cst_id IS NULL;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Clientes duplicados por cst_id',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT cst_id
    FROM silver.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1
) AS duplicados;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Género fuera del dominio {Male, Female, n/a}',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'n/a');

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Estado civil fuera del dominio {Single, Married, n/a}',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a');

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Clientes con fecha de alta futura',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_cust_info
WHERE cst_create_date > CAST(GETDATE() AS DATE);

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Productos duplicados por prd_id',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT prd_id
    FROM silver.crm_prd_info
    GROUP BY prd_id
    HAVING COUNT(*) > 1
) AS duplicados;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Productos con costo negativo',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_prd_info
WHERE prd_cost < 0;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Productos con fin de vigencia anterior al inicio',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Productos sin categoría válida (cat_id)',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_prd_info
WHERE cat_id IS NULL OR cat_id = '' OR prd_key IS NULL OR prd_key = '';

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Ventas donde sales <> quantity * price',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Ventas con cantidad o precio no positivos',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_sales_details
WHERE sls_quantity IS NULL OR sls_quantity <= 0
   OR sls_price IS NULL OR sls_price <= 0
   OR sls_sales IS NULL OR sls_sales <= 0;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Ventas con fechas incoherentes (envío/vencimiento antes del pedido)',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_sales_details
WHERE sls_ship_dt < sls_order_dt
   OR sls_due_dt < sls_order_dt
   OR sls_due_dt < sls_ship_dt;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Ventas con producto inexistente en Silver',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_sales_details AS s
LEFT JOIN silver.crm_prd_info AS p
       ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Ventas con cliente inexistente en Silver',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.crm_sales_details AS s
LEFT JOIN silver.crm_cust_info AS c
       ON s.sls_cust_id = c.cst_id
WHERE c.cst_id IS NULL;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Ventas perdidas entre Bronze y Silver',
    '0',
    CAST(ABS(
        (SELECT COUNT(*) FROM silver.crm_sales_details) -
        (SELECT COUNT(*) FROM bronze.crm_sales_details)
    ) AS NVARCHAR(20)),
    CASE WHEN (SELECT COUNT(*) FROM silver.crm_sales_details) =
              (SELECT COUNT(*) FROM bronze.crm_sales_details)
         THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'CID de ERP con prefijo NAS sin limpiar',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Fechas de nacimiento fuera de rango (futuras o < 1926)',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.erp_cust_az12
WHERE bdate > CAST(GETDATE() AS DATE)
   OR bdate < '1926-01-01';

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Países vacíos o sin estandarizar',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.erp_loc_a101
WHERE cntry IS NULL OR TRIM(cntry) = '';

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'CID de ubicación con guiones sin limpiar',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'Categorías duplicadas por id',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT id
    FROM silver.erp_px_cat_g1v2
    GROUP BY id
    HAVING COUNT(*) > 1
) AS duplicados;

SELECT
    orden       AS [#],
    chequeo    AS [Chequeo],
    esperado    AS [Esperado],
    obtenido    AS [Obtenido],
    estado      AS [Estado]
FROM #resultados
ORDER BY orden;

DECLARE @fallidos INT = (SELECT COUNT(*) FROM #resultados WHERE estado = 'FAIL');
DECLARE @total    INT = (SELECT COUNT(*) FROM #resultados);

PRINT '';
PRINT '============================================================';
PRINT ' RESULTADO SILVER: ' + CAST(@total - @fallidos AS VARCHAR(10)) + '/' +
      CAST(@total AS VARCHAR(10)) + ' chequeos aprobados.';
PRINT '============================================================';

IF @fallidos > 0
BEGIN
    DECLARE @mensaje NVARCHAR(200) =
        N'Validación de calidad de Silver fallida: ' + CAST(@fallidos AS NVARCHAR(10)) +
        N' chequeo(s) con estado FAIL.';
    RAISERROR(@mensaje, 16, 1);
END
ELSE
BEGIN
    PRINT '>> TODOS LOS CHEQUEOS DE SILVER PASARON (PASS).';
END;
GO
