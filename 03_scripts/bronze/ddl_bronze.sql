USE DataWarehouse;
GO

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO
CREATE TABLE bronze.crm_cust_info (
    cst_id              NVARCHAR(20),
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(100),
    cst_lastname        NVARCHAR(100),
    cst_marital_status  NVARCHAR(20),
    cst_gndr            NVARCHAR(20),
    cst_create_date     NVARCHAR(30)
);
GO

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO
CREATE TABLE bronze.crm_prd_info (
    prd_id          NVARCHAR(20),
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(150),
    prd_cost        NVARCHAR(20),
    prd_line        NVARCHAR(20),
    prd_start_dt    NVARCHAR(30),
    prd_end_dt      NVARCHAR(30)
);
GO

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     NVARCHAR(30),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     NVARCHAR(20),
    sls_order_dt    NVARCHAR(20),
    sls_ship_dt     NVARCHAR(20),
    sls_due_dt      NVARCHAR(20),
    sls_sales       NVARCHAR(30),
    sls_quantity    NVARCHAR(20),
    sls_price       NVARCHAR(30)
);
GO

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO
CREATE TABLE bronze.erp_cust_az12 (
    cid     NVARCHAR(50),
    bdate   NVARCHAR(30),
    gen     NVARCHAR(20)
);
GO

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO
CREATE TABLE bronze.erp_loc_a101 (
    cid     NVARCHAR(50),
    cntry   NVARCHAR(50)
);
GO

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(20),
    cat         NVARCHAR(100),
    subcat      NVARCHAR(100),
    maintenance NVARCHAR(20)
);
GO

PRINT '>> ddl_bronze.sql finalizado: 6 tablas creadas en el esquema bronze.';
GO
