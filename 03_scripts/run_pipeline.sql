USE DataWarehouse;
GO

SET NOCOUNT ON;

PRINT '>> Iniciando pipeline: Bronze -> Silver';
GO

EXEC bronze.load_bronze;
GO

EXEC silver.load_silver;
GO

PRINT '>> Pipeline finalizado. Ejecute los scripts de 04_tests para validar.';
GO
