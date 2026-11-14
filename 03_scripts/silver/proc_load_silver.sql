USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @inicio_proceso DATETIME2 = SYSDATETIME();
    DECLARE @inicio_tabla   DATETIME2;
    DECLARE @filas          INT;

    PRINT '============================================================';
    PRINT ' CARGA DE LA CAPA SILVER';
    PRINT ' Inicio : ' + CONVERT(NVARCHAR(19), @inicio_proceso, 120);
    PRINT '============================================================';

    BEGIN TRY
        IF DB_ID('DataWarehouse') IS NULL
            THROW 50000, 'La base de datos DataWarehouse no existe. Ejecute init_database.sql.', 1;

        IF NOT EXISTS (SELECT 1 FROM bronze.crm_cust_info)
            THROW 50001, 'La capa Bronze está vacía. Ejecute EXEC bronze.load_bronze primero.', 1;

        BEGIN TRANSACTION;

        SET @inicio_tabla = SYSDATETIME();

        TRUNCATE TABLE silver.crm_cust_info;

        WITH deduplicado AS (
            SELECT
                TRY_CONVERT(INT, cst_id)                AS cst_id,
                TRIM(cst_key)                           AS cst_key,
                TRIM(cst_firstname)                     AS cst_firstname,
                TRIM(cst_lastname)                      AS cst_lastname,
                UPPER(TRIM(cst_marital_status))         AS marital_raw,
                UPPER(TRIM(cst_gndr))                   AS gndr_raw,
                TRY_CONVERT(DATE, cst_create_date)      AS cst_create_date,
                ROW_NUMBER() OVER (
                    PARTITION BY TRY_CONVERT(INT, cst_id)
                    ORDER BY TRY_CONVERT(DATE, cst_create_date) DESC
                ) AS rn
            FROM bronze.crm_cust_info
            WHERE NULLIF(TRIM(cst_id), '') IS NOT NULL
              AND TRY_CONVERT(INT, cst_id) IS NOT NULL
        )
        INSERT INTO silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            CASE marital_raw
                WHEN 'S' THEN 'Single'
                WHEN 'M' THEN 'Married'
                ELSE 'n/a'
            END,
            CASE gndr_raw
                WHEN 'M' THEN 'Male'
                WHEN 'F' THEN 'Female'
                ELSE 'n/a'
            END,
            cst_create_date
        FROM deduplicado
        WHERE rn = 1;

        SELECT @filas = COUNT(*) FROM silver.crm_cust_info;
        PRINT '>> silver.crm_cust_info        : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();

        TRUNCATE TABLE silver.crm_prd_info;

        WITH base AS (
            SELECT
                TRY_CONVERT(INT, prd_id)                        AS prd_id,
                REPLACE(SUBSTRING(TRIM(prd_key), 1, 5), '-', '_') AS cat_id,
                SUBSTRING(TRIM(prd_key), 7, LEN(TRIM(prd_key))) AS prd_key,
                TRIM(prd_nm)                                    AS prd_nm,
                TRY_CONVERT(INT, prd_cost)                      AS prd_cost,
                UPPER(TRIM(prd_line))                           AS prd_line,
                TRY_CONVERT(DATE, prd_start_dt)                 AS prd_start_dt,
                TRY_CONVERT(DATE, prd_end_dt)                   AS prd_end_dt
            FROM bronze.crm_prd_info
            WHERE NULLIF(TRIM(prd_id), '') IS NOT NULL
              AND TRY_CONVERT(INT, prd_id) IS NOT NULL
        ),
        vigencias AS (
            SELECT
                *,
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) AS siguiente_inicio
            FROM base
        )
        INSERT INTO silver.crm_prd_info (
            prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line,
            prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            CASE WHEN prd_cost IS NULL OR prd_cost < 0 THEN 0 ELSE prd_cost END,
            CASE prd_line
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END,
            prd_start_dt,
            CASE
                WHEN siguiente_inicio IS NOT NULL AND siguiente_inicio > prd_start_dt
                    THEN DATEADD(DAY, -1, siguiente_inicio)
                WHEN siguiente_inicio IS NOT NULL
                    THEN NULL
                WHEN prd_end_dt IS NOT NULL AND prd_end_dt >= prd_start_dt
                    THEN prd_end_dt
                ELSE NULL
            END
        FROM vigencias;

        SELECT @filas = COUNT(*) FROM silver.crm_prd_info;
        PRINT '>> silver.crm_prd_info         : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();

        TRUNCATE TABLE silver.crm_sales_details;

        WITH base AS (
            SELECT
                TRIM(sls_ord_num)   AS sls_ord_num,
                TRIM(sls_prd_key)   AS sls_prd_key,
                TRY_CONVERT(INT, sls_cust_id) AS sls_cust_id,
                CASE WHEN LEN(TRIM(sls_order_dt)) = 8
                     THEN TRY_CONVERT(DATE, sls_order_dt, 112) END AS sls_order_dt,
                CASE WHEN LEN(TRIM(sls_ship_dt)) = 8
                     THEN TRY_CONVERT(DATE, sls_ship_dt, 112) END AS sls_ship_dt,
                CASE WHEN LEN(TRIM(sls_due_dt)) = 8
                     THEN TRY_CONVERT(DATE, sls_due_dt, 112) END AS sls_due_dt,
                TRY_CONVERT(INT, sls_sales)    AS sls_sales,
                TRY_CONVERT(INT, sls_quantity) AS sls_quantity,
                TRY_CONVERT(INT, sls_price)    AS sls_price
            FROM bronze.crm_sales_details
        ),
        precios AS (
            SELECT
                *,
                CASE
                    WHEN sls_price IS NULL OR sls_price <= 0
                        THEN CAST(ROUND(CAST(ABS(sls_sales) AS DECIMAL(18, 2))
                                        / NULLIF(sls_quantity, 0), 0) AS INT)
                    ELSE sls_price
                END AS precio_corregido
            FROM base
        )
        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id,
            sls_order_dt, sls_ship_dt, sls_due_dt,
            sls_sales, sls_quantity, sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR sls_sales <> sls_quantity * ABS(precio_corregido)
                    THEN sls_quantity * ABS(precio_corregido)
                ELSE sls_sales
            END,
            sls_quantity,
            ABS(precio_corregido)
        FROM precios;

        SELECT @filas = COUNT(*) FROM silver.crm_sales_details;
        PRINT '>> silver.crm_sales_details    : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE
                WHEN UPPER(TRIM(cid)) LIKE 'NAS%'
                    THEN SUBSTRING(TRIM(cid), 4, LEN(TRIM(cid)))
                ELSE TRIM(cid)
            END,
            CASE
                WHEN TRY_CONVERT(DATE, bdate) > CAST(GETDATE() AS DATE)
                     OR TRY_CONVERT(DATE, bdate) < '1926-01-01'
                    THEN NULL
                ELSE TRY_CONVERT(DATE, bdate)
            END,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                ELSE 'n/a'
            END
        FROM bronze.erp_cust_az12
        WHERE NULLIF(TRIM(cid), '') IS NOT NULL;

        SELECT @filas = COUNT(*) FROM silver.erp_cust_az12;
        PRINT '>> silver.erp_cust_az12        : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(TRIM(cid), '-', ''),
            CASE
                WHEN NULLIF(TRIM(cntry), '') IS NULL   THEN 'n/a'
                WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
                WHEN UPPER(TRIM(cntry)) = 'DE'          THEN 'Germany'
                ELSE TRIM(cntry)
            END
        FROM bronze.erp_loc_a101
        WHERE NULLIF(TRIM(cid), '') IS NOT NULL;

        SELECT @filas = COUNT(*) FROM silver.erp_loc_a101;
        PRINT '>> silver.erp_loc_a101         : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT
            TRIM(id),
            TRIM(cat),
            TRIM(subcat),
            CASE WHEN NULLIF(TRIM(maintenance), '') IS NULL
                 THEN 'n/a' ELSE TRIM(maintenance) END
        FROM bronze.erp_px_cat_g1v2
        WHERE NULLIF(TRIM(id), '') IS NOT NULL;

        SELECT @filas = COUNT(*) FROM silver.erp_px_cat_g1v2;
        PRINT '>> silver.erp_px_cat_g1v2      : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        COMMIT TRANSACTION;

        PRINT '------------------------------------------------------------';
        PRINT ' Transformación finalizada correctamente.';
        PRINT ' Duración total: ' + CAST(DATEDIFF(SECOND, @inicio_proceso, SYSDATETIME()) AS VARCHAR(20)) + ' s';
        PRINT '============================================================';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT '************************************************************';
        PRINT ' ERROR EN LA CARGA DE SILVER';
        PRINT ' Mensaje : ' + ERROR_MESSAGE();
        PRINT ' Línea   : ' + CAST(ERROR_LINE() AS VARCHAR(20));
        PRINT '************************************************************';
        THROW;
    END CATCH
END;
GO

PRINT '>> proc_load_silver.sql finalizado: procedimiento silver.load_silver creado.';
GO
