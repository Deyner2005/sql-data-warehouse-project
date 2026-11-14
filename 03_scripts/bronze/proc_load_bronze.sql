USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
    @ruta_datasets NVARCHAR(400) = N'C:\Users\deyne\Desktop\sql-data-warehouse-project\01_datasets'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @inicio_proceso DATETIME2 = SYSDATETIME();
    DECLARE @inicio_tabla   DATETIME2;
    DECLARE @filas          INT;
    DECLARE @sql            NVARCHAR(MAX);
    DECLARE @ruta           NVARCHAR(500);

    PRINT '============================================================';
    PRINT ' CARGA DE LA CAPA BRONZE';
    PRINT ' Inicio : ' + CONVERT(NVARCHAR(19), @inicio_proceso, 120);
    PRINT ' Ruta   : ' + @ruta_datasets;
    PRINT '============================================================';

    BEGIN TRY
        IF DB_ID('DataWarehouse') IS NULL
            THROW 50000, 'La base de datos DataWarehouse no existe. Ejecute init_database.sql.', 1;

        BEGIN TRANSACTION;

        SET @inicio_tabla = SYSDATETIME();
        SET @ruta = @ruta_datasets + N'\source_crm\cust_info.csv';

        TRUNCATE TABLE bronze.crm_cust_info;

        SET @sql = N'BULK INSERT bronze.crm_cust_info FROM ' + QUOTENAME(@ruta, '''') +
                   N' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        SELECT @filas = COUNT(*) FROM bronze.crm_cust_info;
        PRINT '>> bronze.crm_cust_info         : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();
        SET @ruta = @ruta_datasets + N'\source_crm\prd_info.csv';

        TRUNCATE TABLE bronze.crm_prd_info;

        SET @sql = N'BULK INSERT bronze.crm_prd_info FROM ' + QUOTENAME(@ruta, '''') +
                   N' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        SELECT @filas = COUNT(*) FROM bronze.crm_prd_info;
        PRINT '>> bronze.crm_prd_info          : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();
        SET @ruta = @ruta_datasets + N'\source_crm\sales_details.csv';

        TRUNCATE TABLE bronze.crm_sales_details;

        SET @sql = N'BULK INSERT bronze.crm_sales_details FROM ' + QUOTENAME(@ruta, '''') +
                   N' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        SELECT @filas = COUNT(*) FROM bronze.crm_sales_details;
        PRINT '>> bronze.crm_sales_details     : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();
        SET @ruta = @ruta_datasets + N'\source_erp\CUST_AZ12.csv';

        TRUNCATE TABLE bronze.erp_cust_az12;

        SET @sql = N'BULK INSERT bronze.erp_cust_az12 FROM ' + QUOTENAME(@ruta, '''') +
                   N' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        SELECT @filas = COUNT(*) FROM bronze.erp_cust_az12;
        PRINT '>> bronze.erp_cust_az12         : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();
        SET @ruta = @ruta_datasets + N'\source_erp\LOC_A101.csv';

        TRUNCATE TABLE bronze.erp_loc_a101;

        SET @sql = N'BULK INSERT bronze.erp_loc_a101 FROM ' + QUOTENAME(@ruta, '''') +
                   N' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        SELECT @filas = COUNT(*) FROM bronze.erp_loc_a101;
        PRINT '>> bronze.erp_loc_a101          : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        SET @inicio_tabla = SYSDATETIME();
        SET @ruta = @ruta_datasets + N'\source_erp\PX_CAT_G1V2.csv';

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        SET @sql = N'BULK INSERT bronze.erp_px_cat_g1v2 FROM ' + QUOTENAME(@ruta, '''') +
                   N' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        SELECT @filas = COUNT(*) FROM bronze.erp_px_cat_g1v2;
        PRINT '>> bronze.erp_px_cat_g1v2       : ' + CAST(@filas AS VARCHAR(20)) + ' filas, ' +
              CAST(DATEDIFF(MILLISECOND, @inicio_tabla, SYSDATETIME()) AS VARCHAR(20)) + ' ms';

        COMMIT TRANSACTION;

        PRINT '------------------------------------------------------------';
        PRINT ' Carga finalizada correctamente.';
        PRINT ' Duración total: ' + CAST(DATEDIFF(SECOND, @inicio_proceso, SYSDATETIME()) AS VARCHAR(20)) + ' s';
        PRINT '============================================================';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT '************************************************************';
        PRINT ' ERROR EN LA CARGA DE BRONZE';
        PRINT ' Mensaje : ' + ERROR_MESSAGE();
        PRINT ' Línea   : ' + CAST(ERROR_LINE() AS VARCHAR(20));
        PRINT '************************************************************';
        THROW;
    END CATCH
END;
GO

PRINT '>> proc_load_bronze.sql finalizado: procedimiento bronze.load_bronze creado.';
GO
