USE DataWarehouse;
GO

DROP VIEW IF EXISTS gold.dim_customers;
GO
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.cst_id)   AS customer_key,
    c.cst_id                                AS customer_id,
    c.cst_key                               AS customer_number,
    c.cst_firstname                         AS first_name,
    c.cst_lastname                          AS last_name,
    COALESCE(l.cntry, 'n/a')                AS country,
    c.cst_marital_status                    AS marital_status,
    CASE
        WHEN c.cst_gndr <> 'n/a' THEN c.cst_gndr
        ELSE COALESCE(e.gen, 'n/a')
    END                                     AS gender,
    e.bdate                                 AS birthdate,
    c.cst_create_date                       AS create_date
FROM silver.crm_cust_info AS c
LEFT JOIN silver.erp_cust_az12 AS e
       ON c.cst_key = e.cid
LEFT JOIN silver.erp_loc_a101 AS l
       ON c.cst_key = l.cid;
GO

DROP VIEW IF EXISTS gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.prd_start_dt, p.prd_key) AS product_key,
    p.prd_id                                AS product_id,
    p.prd_key                               AS product_number,
    p.prd_nm                                AS product_name,
    p.cat_id                                AS category_id,
    COALESCE(k.cat, 'n/a')                  AS category,
    COALESCE(k.subcat, 'n/a')               AS subcategory,
    COALESCE(k.maintenance, 'n/a')          AS maintenance,
    p.prd_cost                              AS cost,
    p.prd_line                              AS product_line,
    p.prd_start_dt                          AS start_date
FROM silver.crm_prd_info AS p
LEFT JOIN silver.erp_px_cat_g1v2 AS k
       ON p.cat_id = k.id
WHERE p.prd_end_dt IS NULL;
GO

DROP VIEW IF EXISTS gold.fact_sales;
GO
CREATE VIEW gold.fact_sales AS
SELECT
    s.sls_ord_num       AS order_number,
    pr.product_key      AS product_key,
    cu.customer_key     AS customer_key,
    s.sls_order_dt      AS order_date,
    s.sls_ship_dt       AS shipping_date,
    s.sls_due_dt        AS due_date,
    s.sls_sales         AS sales_amount,
    s.sls_quantity      AS quantity,
    s.sls_price         AS price
FROM silver.crm_sales_details AS s
LEFT JOIN gold.dim_products AS pr
       ON s.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
       ON s.sls_cust_id = cu.customer_id;
GO

PRINT '>> ddl_gold.sql finalizado: 3 vistas creadas en el esquema gold.';
GO
