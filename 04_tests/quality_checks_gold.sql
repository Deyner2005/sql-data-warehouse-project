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
    'dim_customers: claves subrogadas duplicadas',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT customer_key
    FROM gold.dim_customers
    GROUP BY customer_key
    HAVING COUNT(*) > 1
) AS duplicados;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'dim_customers: customer_id duplicado o nulo',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT customer_id
    FROM gold.dim_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1 OR customer_id IS NULL
) AS duplicados;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'dim_customers: filas con customer_key nulo',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM gold.dim_customers
WHERE customer_key IS NULL;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'dim_customers: clientes sin país asignado',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM gold.dim_customers
WHERE country IS NULL OR TRIM(country) = '';

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'dim_products: claves subrogadas duplicadas',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT product_key
    FROM gold.dim_products
    GROUP BY product_key
    HAVING COUNT(*) > 1
) AS duplicados;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'dim_products: product_number duplicado o nulo',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT product_number
    FROM gold.dim_products
    GROUP BY product_number
    HAVING COUNT(*) > 1 OR product_number IS NULL
) AS duplicados;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'dim_products: productos sin categoría',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM gold.dim_products
WHERE category IS NULL OR TRIM(category) = '';

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'dim_products: filas distintas de los productos vigentes en Silver',
    '0',
    CAST(ABS(
        (SELECT COUNT(*) FROM gold.dim_products) -
        (SELECT COUNT(*) FROM silver.crm_prd_info WHERE prd_end_dt IS NULL)
    ) AS NVARCHAR(20)),
    CASE WHEN (SELECT COUNT(*) FROM gold.dim_products) =
              (SELECT COUNT(*) FROM silver.crm_prd_info WHERE prd_end_dt IS NULL)
         THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'fact_sales: ventas con product_key nulo o huérfano',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
       ON f.product_key = p.product_key
WHERE f.product_key IS NULL OR p.product_key IS NULL;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'fact_sales: ventas con customer_key nulo o huérfano',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
       ON f.customer_key = c.customer_key
WHERE f.customer_key IS NULL OR c.customer_key IS NULL;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'fact_sales: sales_amount <> quantity * price',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM gold.fact_sales
WHERE sales_amount <> quantity * price;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'fact_sales: cantidad o precio no positivos',
    '0',
    CAST(COUNT(*) AS NVARCHAR(20)),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM gold.fact_sales
WHERE quantity IS NULL OR quantity <= 0
   OR price IS NULL OR price <= 0
   OR sales_amount IS NULL OR sales_amount <= 0;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'fact_sales: filas distintas de Silver (ventas perdidas o duplicadas)',
    '0',
    CAST(ABS(
        (SELECT COUNT(*) FROM gold.fact_sales) -
        (SELECT COUNT(*) FROM silver.crm_sales_details)
    ) AS NVARCHAR(20)),
    CASE WHEN (SELECT COUNT(*) FROM gold.fact_sales) =
              (SELECT COUNT(*) FROM silver.crm_sales_details)
         THEN 'PASS' ELSE 'FAIL' END;

INSERT INTO #resultados (chequeo, esperado, obtenido, estado)
SELECT
    'fact_sales: monto total distinto de Silver',
    '0',
    CAST(ABS(
        (SELECT ISNULL(SUM(sales_amount), 0) FROM gold.fact_sales) -
        (SELECT ISNULL(SUM(sls_sales), 0) FROM silver.crm_sales_details)
    ) AS NVARCHAR(20)),
    CASE WHEN (SELECT ISNULL(SUM(sales_amount), 0) FROM gold.fact_sales) =
              (SELECT ISNULL(SUM(sls_sales), 0) FROM silver.crm_sales_details)
         THEN 'PASS' ELSE 'FAIL' END;

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
PRINT ' RESULTADO GOLD: ' + CAST(@total - @fallidos AS VARCHAR(10)) + '/' +
      CAST(@total AS VARCHAR(10)) + ' chequeos aprobados.';
PRINT '============================================================';

IF @fallidos > 0
BEGIN
    DECLARE @mensaje NVARCHAR(200) =
        N'Validación de calidad de Gold fallida: ' + CAST(@fallidos AS NVARCHAR(10)) +
        N' chequeo(s) con estado FAIL.';
    RAISERROR(@mensaje, 16, 1);
END
ELSE
BEGIN
    PRINT '>> TODOS LOS CHEQUEOS DE GOLD PASARON (PASS).';
END;
GO
