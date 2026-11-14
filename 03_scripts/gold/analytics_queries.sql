USE DataWarehouse;
GO

SET NOCOUNT ON;

PRINT '=== 1. Ventas por año ===';
SELECT
    YEAR(order_date)            AS anio,
    COUNT(*)                    AS lineas,
    SUM(quantity)               AS unidades,
    SUM(sales_amount)           AS ventas,
    CAST(AVG(sales_amount) AS DECIMAL(18, 2)) AS ticket_promedio_linea
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY anio;
GO

PRINT '=== 2. Ventas por mes ===';
SELECT
    DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS mes,
    COUNT(*)                    AS lineas,
    SUM(sales_amount)           AS ventas
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
ORDER BY mes;
GO

PRINT '=== 3. Top 10 productos por ingresos ===';
SELECT TOP (10)
    p.product_number,
    p.product_name,
    p.category,
    p.subcategory,
    SUM(f.quantity)     AS unidades,
    SUM(f.sales_amount) AS ventas
FROM gold.fact_sales AS f
INNER JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
GROUP BY p.product_number, p.product_name, p.category, p.subcategory
ORDER BY ventas DESC;
GO

PRINT '=== 4. Ventas por país ===';
SELECT
    c.country,
    COUNT(DISTINCT c.customer_id) AS clientes,
    COUNT(*)                      AS lineas,
    SUM(f.sales_amount)           AS ventas
FROM gold.fact_sales AS f
INNER JOIN gold.dim_customers AS c
        ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY ventas DESC;
GO

PRINT '=== 5. Ventas por categoría ===';
SELECT
    p.category,
    p.subcategory,
    SUM(f.quantity)     AS unidades,
    SUM(f.sales_amount) AS ventas
FROM gold.fact_sales AS f
INNER JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
GROUP BY p.category, p.subcategory
ORDER BY ventas DESC;
GO

PRINT '=== 6. Top 10 clientes por gasto ===';
SELECT TOP (10)
    c.customer_id,
    c.customer_number,
    c.first_name + ' ' + c.last_name AS cliente,
    c.country,
    COUNT(*)            AS lineas,
    SUM(f.sales_amount) AS total_comprado
FROM gold.fact_sales AS f
INNER JOIN gold.dim_customers AS c
        ON f.customer_key = c.customer_key
GROUP BY c.customer_id, c.customer_number, c.first_name, c.last_name, c.country
ORDER BY total_comprado DESC;
GO

PRINT '=== 7. Productos vigentes sin ventas ===';
SELECT
    p.product_number,
    p.product_name,
    p.category,
    p.product_line
FROM gold.dim_products AS p
LEFT JOIN gold.fact_sales AS f
       ON p.product_key = f.product_key
WHERE f.product_key IS NULL
ORDER BY p.product_name;
GO

PRINT '=== 8. Indicadores generales ===';
SELECT
    COUNT(*)                                    AS lineas_de_venta,
    COUNT(DISTINCT order_number)                AS pedidos,
    COUNT(DISTINCT customer_key)                AS clientes_con_compra,
    SUM(quantity)                               AS unidades,
    SUM(sales_amount)                           AS ventas_totales,
    CAST(SUM(sales_amount) / COUNT(DISTINCT order_number) AS DECIMAL(18, 2)) AS ticket_promedio_pedido
FROM gold.fact_sales;
GO
