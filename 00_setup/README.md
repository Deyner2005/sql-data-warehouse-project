# Configuración del entorno

Pasos para ejecutar el proyecto desde cero.

## Requisitos

- SQL Server 2017 o superior (probado con SQL Server 2025 Developer Edition en `localhost`).
- `sqlcmd` con ODBC Driver 18.
- Git, solo si se va a clonar el repositorio.
- Visual Studio Code con la extensión de SQL Server, opcional.

## Ubicación del proyecto

Los scripts asumen esta ruta:

```
C:\Users\deyne\Desktop\sql-data-warehouse-project
```

La ruta de los CSV está en el parámetro `@ruta_datasets` del procedimiento
`bronze.load_bronze`. Si el proyecto se mueve, hay que actualizar ese valor o pasarlo al
ejecutar:

```sql
EXEC bronze.load_bronze @ruta_datasets = N'D:\otra\ruta\01_datasets';
```

## Permisos de la carpeta de datos

`BULK INSERT` usa la cuenta del servicio de SQL Server (`NT Service\MSSQLSERVER`), no la del
usuario de Windows. Si la carpeta está dentro del perfil del usuario, el servicio puede no
tener acceso. Se resuelve con:

```powershell
icacls "C:\Users\deyne\Desktop\sql-data-warehouse-project\01_datasets" `
       /grant "NT SERVICE\MSSQLSERVER:(OI)(CI)RX" /T
```

Para comprobar el acceso:

```sql
SELECT TOP 10 *
FROM OPENROWSET(
    BULK 'C:\Users\deyne\Desktop\sql-data-warehouse-project\01_datasets\source_crm\cust_info.csv',
    SINGLE_CLOB
) AS archivo;
```

Si devuelve filas, el servicio ya puede leer los archivos.

## Salto de línea de los CSV

Tres archivos de origen no terminan en salto de línea y por eso `BULK INSERT` pierde su último
registro. Se corrige una sola vez con:

```powershell
powershell -ExecutionPolicy Bypass -File "00_setup\normalize_datasets.ps1"
```

El script solo agrega el `CRLF` final cuando falta; no cambia los datos.

## Orden de ejecución

```powershell
$s = "C:\Users\deyne\Desktop\sql-data-warehouse-project\03_scripts"

sqlcmd -S localhost -E -C -i "$s\init_database.sql"

sqlcmd -S localhost -E -C -i "$s\bronze\ddl_bronze.sql"
sqlcmd -S localhost -E -C -i "$s\bronze\proc_load_bronze.sql"
sqlcmd -S localhost -E -C -i "$s\silver\ddl_silver.sql"
sqlcmd -S localhost -E -C -i "$s\silver\proc_load_silver.sql"
sqlcmd -S localhost -E -C -i "$s\gold\ddl_gold.sql"
```

Después se cargan los datos:

```powershell
sqlcmd -S localhost -E -C -Q "EXEC bronze.load_bronze; EXEC silver.load_silver;"
```

## Validación

```powershell
sqlcmd -S localhost -E -C -i "04_tests\quality_checks_silver.sql"
sqlcmd -S localhost -E -C -i "04_tests\quality_checks_gold.sql"
```

Conteo rápido de filas:

```sql
USE DataWarehouse;

SELECT 'bronze.crm_cust_info' AS tabla, COUNT(*) AS filas FROM bronze.crm_cust_info
UNION ALL SELECT 'bronze.crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL SELECT 'bronze.crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL SELECT 'silver.crm_cust_info', COUNT(*) FROM silver.crm_cust_info
UNION ALL SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'gold.dim_customers', COUNT(*) FROM gold.dim_customers
UNION ALL SELECT 'gold.dim_products', COUNT(*) FROM gold.dim_products
UNION ALL SELECT 'gold.fact_sales', COUNT(*) FROM gold.fact_sales;
```

## Problemas comunes

- **Error de certificado al conectar:** `sqlcmd` 18 cifra por defecto y el certificado es
  autofirmado. Agregar `-C` a la conexión.
- **`BULK INSERT` sin permisos:** aplicar el `icacls` de este documento.
- **Acentos dañados:** los CSV son UTF-8, así que la carga usa `CODEPAGE = '65001'`.
- **`String or binary data would be truncated`:** alguna columna `NVARCHAR` quedó corta;
  ampliarla en el DDL de Bronze y volver a cargar.
- **Gold vacío:** no se ejecutó `silver.load_silver`, que es de donde leen las vistas.

## Reejecución

Los scripts se pueden correr varias veces sin duplicar nada: `init_database.sql` crea la base y
los esquemas solo si no existen, los `ddl_*.sql` recrean los objetos y los `proc_*.sql` usan
`CREATE OR ALTER`. Los procedimientos truncan antes de insertar.
