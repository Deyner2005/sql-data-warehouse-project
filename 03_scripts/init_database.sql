USE master;
GO

IF DB_ID('DataWarehouse') IS NULL
BEGIN
    PRINT '>> Creando la base de datos DataWarehouse...';
    CREATE DATABASE DataWarehouse;
END
ELSE
BEGIN
    PRINT '>> La base de datos DataWarehouse ya existe.';
END;
GO

USE DataWarehouse;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
BEGIN
    PRINT '>> Creando el esquema bronze...';
    EXEC ('CREATE SCHEMA bronze AUTHORIZATION dbo;');
END;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
BEGIN
    PRINT '>> Creando el esquema silver...';
    EXEC ('CREATE SCHEMA silver AUTHORIZATION dbo;');
END;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    PRINT '>> Creando el esquema gold...';
    EXEC ('CREATE SCHEMA gold AUTHORIZATION dbo;');
END;
GO

PRINT '>> Esquemas disponibles:';
SELECT name AS esquema
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold')
ORDER BY name;
GO

PRINT '>> init_database.sql finalizado correctamente.';
GO
