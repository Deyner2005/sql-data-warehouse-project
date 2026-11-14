USE DataWarehouse;
GO

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO
CREATE TABLE silver.crm_cust_info (
    cst_id              INT             NOT NULL,
    cst_key             NVARCHAR(50)    NOT NULL,
    cst_firstname       NVARCHAR(50)    NULL,
    cst_lastname        NVARCHAR(50)    NULL,
    cst_marital_status  NVARCHAR(20)    NOT NULL,
    cst_gndr            NVARCHAR(20)    NOT NULL,
    cst_create_date     DATE            NULL,
    CONSTRAINT pk_crm_cust_info PRIMARY KEY (cst_id)
);
GO

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO
CREATE TABLE silver.crm_prd_info (
    prd_id          INT             NOT NULL,
    cat_id          NVARCHAR(20)    NOT NULL,
    prd_key         NVARCHAR(50)    NOT NULL,
    prd_nm          NVARCHAR(100)   NOT NULL,
    prd_cost        INT             NOT NULL,
    prd_line        NVARCHAR(30)    NOT NULL,
    prd_start_dt    DATE            NULL,
    prd_end_dt      DATE            NULL,
    CONSTRAINT pk_crm_prd_info PRIMARY KEY (prd_id)
);
GO

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(30)    NOT NULL,
    sls_prd_key     NVARCHAR(50)    NOT NULL,
    sls_cust_id     INT             NULL,
    sls_order_dt    DATE            NULL,
    sls_ship_dt     DATE            NULL,
    sls_due_dt      DATE            NULL,
    sls_sales       INT             NULL,
    sls_quantity    INT             NULL,
    sls_price       INT             NULL
);
GO

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO
CREATE TABLE silver.erp_cust_az12 (
    cid     NVARCHAR(50)    NOT NULL,
    bdate   DATE            NULL,
    gen     NVARCHAR(20)    NOT NULL,
    CONSTRAINT pk_erp_cust_az12 PRIMARY KEY (cid)
);
GO

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO
CREATE TABLE silver.erp_loc_a101 (
    cid     NVARCHAR(50)    NOT NULL,
    cntry   NVARCHAR(50)    NOT NULL,
    CONSTRAINT pk_erp_loc_a101 PRIMARY KEY (cid)
);
GO

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO
CREATE TABLE silver.erp_px_cat_g1v2 (
    id          NVARCHAR(20)    NOT NULL,
    cat         NVARCHAR(50)    NOT NULL,
    subcat      NVARCHAR(50)    NOT NULL,
    maintenance NVARCHAR(20)    NOT NULL,
    CONSTRAINT pk_erp_px_cat_g1v2 PRIMARY KEY (id)
);
GO

PRINT '>> ddl_silver.sql finalizado: 6 tablas creadas en el esquema silver.';
GO
