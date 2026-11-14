# Convenciones de nombres

Reglas usadas para nombrar esquemas, tablas, vistas y columnas.

## Principios generales

- Los objetos se nombran en inglés; la documentación va en español.
- Formato `snake_case`: minúsculas y guion bajo (`crm_sales_details`, `sales_amount`).
- No se repite la capa en el nombre porque ya la indica el esquema
  (`silver.crm_cust_info`, no `silver_silver_crm_cust_info`).
- Se evitan palabras reservadas como `order`, `date`, `user` o `status`.
- Los nombres no superan los 63 caracteres.
- Tablas en singular (`crm_cust_info`) y dimensiones en plural (`dim_customers`).
- Un mismo concepto conserva el mismo nombre en todas las capas.

## Tablas

Formato: `<sistema_origen>_<entidad>`, por ejemplo `crm_cust_info`.

- `sistema_origen`: `crm` o `erp`.
- `entidad`: nombre original del archivo o tabla, en minúsculas y sin modificarlo
  (`cust_info`, `prd_info`, `sales_details`, `loc_a101`, `px_cat_g1v2`).

### Bronze

- Se mantiene el nombre del archivo en minúsculas y se antepone el sistema:
  `cust_info.csv` pasa a `bronze.crm_cust_info`.
- Las columnas conservan el nombre original del CSV, en minúsculas y con `_`.
- No se agregan claves, índices ni restricciones: Bronze es una copia de la fuente.
- Los tipos son permisivos (`NVARCHAR`) para no rechazar registros.

### Silver

- El nombre de tabla es el mismo de Bronze, solo cambia el esquema:
  `silver.crm_cust_info`.
- Las columnas usan tipos definitivos (`INT`, `DATE`, `NVARCHAR(n)`).
- Se permiten columnas derivadas con nombre descriptivo, por ejemplo `cat_id`.
- Se aplican reglas de calidad, pero no modelado dimensional.

### Gold

- Dimensiones: `dim_<entidad_en_plural>` (`dim_customers`, `dim_products`).
- Hechos: `fact_<proceso>` (`fact_sales`).
- Reportes: `report_<entidad>_<métrica>` (por ejemplo, `report_sales_monthly`).
- No se usan prefijos de sistema de origen porque Gold ya está integrado.

## Columnas

- Clave natural: `<entidad>_id` (`customer_id`, `product_id`).
- Número de negocio: `<entidad>_number` (`customer_number`, `product_number`).
- Clave subrogada: `<entidad>_key` (`customer_key`, `product_key`).
- Fechas: `<evento>_date` en Gold y `<evento>_dt` en Bronze y Silver.
- Montos: `<concepto>_amount` (`sales_amount`).
- Cantidades: `<concepto>` o `<concepto>_quantity` (`quantity`).
- Booleanos: `<concepto>_flag`.
- Texto descriptivo: `<concepto>_name` o `<concepto>_desc`.

Además:

- No se usan abreviaturas ambiguas: `quantity` en lugar de `qty`, `amount` en lugar de `amt`.
- El nombre no incluye el tipo de dato (`customer_name`, no `customer_name_varchar`).
- Las columnas calculadas se explican en el catálogo de datos.

## Claves subrogadas

- Se llaman `<entidad>_key`, son `INT` y se generan en Gold con
  `ROW_NUMBER() OVER (ORDER BY <clave_natural>)`.
- No tienen significado de negocio; solo identifican una fila de la dimensión.
- La clave natural se conserva para trazabilidad y para unir con Silver.

## Columnas técnicas

Se dejaron definidas para futuras extensiones, aunque el alcance actual no las implementa
porque no hay historización:

- `dwh_load_date` (`DATETIME2`): fecha y hora de carga.
- `dwh_source_system` (`NVARCHAR(20)`): sistema de origen.
- `dwh_batch_id` (`UNIQUEIDENTIFIER`): identificador del lote.

## Procedimientos almacenados

Formato `load_<capa>`:

- `<capa>` es `bronze` o `silver`, y el procedimiento vive en el esquema de esa capa.
- Ejemplos: `bronze.load_bronze`, `silver.load_silver`.

Reglas:

- El esquema del procedimiento es la capa donde vive (`bronze`, `silver`, `gold`).
- Se usa `CREATE OR ALTER PROCEDURE` para que el script sea idempotente.
- Los errores se manejan con `BEGIN TRY ... BEGIN CATCH`, `ERROR_MESSAGE()` y `THROW`.
- Los procedimientos de carga informan duración y filas con `PRINT`.

## Otros objetos

- Esquemas: `bronze`, `silver`, `gold`.
- Vistas: mismo nombre de la tabla que representan (`dim_customers`).
- Índices: `ix_<tabla>_<columnas>`.
- Clave primaria: `pk_<tabla>`.
- Clave foránea: `fk_<tabla>_<tabla_referenciada>`.
- Archivos SQL: `<tipo>_<capa>.sql` (`ddl_silver.sql`, `proc_load_bronze.sql`).

## Archivos y Git

- Archivos y carpetas en minúsculas con `_`.
- Carpetas numeradas por orden de ejecución: `00_setup`, `01_datasets`, `02_docs`,
  `03_scripts`, `04_tests`.
- Rama principal `main`; para trabajo temporal, `feat/<tema>` o `fix/<tema>`.
- Commits en español, en imperativo y con un cambio lógico por commit.
