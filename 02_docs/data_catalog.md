# Catálogo de datos

Tablas y vistas del data warehouse, con sus columnas, tipos y reglas aplicadas.

Base de datos: `DataWarehouse`.

## Bronze

Copia fiel de los CSV, sin claves, índices ni transformaciones. Todas las columnas son
`NVARCHAR` para evitar rechazos durante la carga.

### bronze.crm_cust_info

Origen: `01_datasets/source_crm/cust_info.csv`.

| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| `cst_id` | `NVARCHAR(20)` | Sí | Identificador del cliente. |
| `cst_key` | `NVARCHAR(50)` | Sí | Número de cliente (`AW00011000`). |
| `cst_firstname` | `NVARCHAR(100)` | Sí | Nombre. |
| `cst_lastname` | `NVARCHAR(100)` | Sí | Apellido. |
| `cst_marital_status` | `NVARCHAR(20)` | Sí | Estado civil (`M`, `S`). |
| `cst_gndr` | `NVARCHAR(20)` | Sí | Género (`M`, `F`). |
| `cst_create_date` | `NVARCHAR(30)` | Sí | Fecha de alta. |

### bronze.crm_prd_info

Origen: `01_datasets/source_crm/prd_info.csv`.

| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| `prd_id` | `NVARCHAR(20)` | Sí | Identificador del producto. |
| `prd_key` | `NVARCHAR(50)` | Sí | Clave con categoría y código. |
| `prd_nm` | `NVARCHAR(150)` | Sí | Nombre. |
| `prd_cost` | `NVARCHAR(20)` | Sí | Costo unitario. |
| `prd_line` | `NVARCHAR(20)` | Sí | Línea (`M`, `R`, `S`, `T`). |
| `prd_start_dt` | `NVARCHAR(30)` | Sí | Inicio de vigencia. |
| `prd_end_dt` | `NVARCHAR(30)` | Sí | Fin de vigencia. |

### bronze.crm_sales_details

Origen: `01_datasets/source_crm/sales_details.csv`.

| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| `sls_ord_num` | `NVARCHAR(30)` | Sí | Número de pedido. |
| `sls_prd_key` | `NVARCHAR(50)` | Sí | Clave del producto vendido. |
| `sls_cust_id` | `NVARCHAR(20)` | Sí | Identificador del cliente. |
| `sls_order_dt` | `NVARCHAR(20)` | Sí | Fecha del pedido (`AAAAMMDD`). |
| `sls_ship_dt` | `NVARCHAR(20)` | Sí | Fecha de envío (`AAAAMMDD`). |
| `sls_due_dt` | `NVARCHAR(20)` | Sí | Fecha de vencimiento (`AAAAMMDD`). |
| `sls_sales` | `NVARCHAR(30)` | Sí | Monto total. |
| `sls_quantity` | `NVARCHAR(20)` | Sí | Cantidad. |
| `sls_price` | `NVARCHAR(30)` | Sí | Precio unitario. |

### bronze.erp_cust_az12

Origen: `01_datasets/source_erp/CUST_AZ12.csv`.

| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| `cid` | `NVARCHAR(50)` | Sí | Identificador del cliente, con prefijo `NAS`. |
| `bdate` | `NVARCHAR(30)` | Sí | Fecha de nacimiento. |
| `gen` | `NVARCHAR(20)` | Sí | Género. |

### bronze.erp_loc_a101

Origen: `01_datasets/source_erp/LOC_A101.csv`.

| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| `cid` | `NVARCHAR(50)` | Sí | Identificador del cliente, con guiones. |
| `cntry` | `NVARCHAR(50)` | Sí | País. |

### bronze.erp_px_cat_g1v2

Origen: `01_datasets/source_erp/PX_CAT_G1V2.csv`.

| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | `NVARCHAR(20)` | Sí | Identificador de categoría (`AC_BR`). |
| `cat` | `NVARCHAR(100)` | Sí | Categoría. |
| `subcat` | `NVARCHAR(100)` | Sí | Subcategoría. |
| `maintenance` | `NVARCHAR(20)` | Sí | Requiere mantenimiento (`Yes` / `No`). |

## Silver

Datos limpios, estandarizados y con tipos definitivos. La carga es truncar y cargar.

### silver.crm_cust_info

| Columna | Tipo | Nulo | Descripción | Regla |
|---|---|---|---|---|
| `cst_id` | `INT` | No | Identificador del cliente. | Se convierte a entero y se excluyen nulos o vacíos. |
| `cst_key` | `NVARCHAR(50)` | No | Número de cliente. | `TRIM`. |
| `cst_firstname` | `NVARCHAR(50)` | No | Nombre. | `TRIM`. |
| `cst_lastname` | `NVARCHAR(50)` | No | Apellido. | `TRIM`. |
| `cst_marital_status` | `NVARCHAR(20)` | No | Estado civil. | `S` → `Single`, `M` → `Married`, otro → `n/a`. |
| `cst_gndr` | `NVARCHAR(20)` | No | Género. | `M` → `Male`, `F` → `Female`, otro → `n/a`. |
| `cst_create_date` | `DATE` | Sí | Fecha de alta. | `TRY_CONVERT`. |

En caso de duplicados se conserva una fila por `cst_id`, la de mayor `cst_create_date`.

### silver.crm_prd_info

| Columna | Tipo | Nulo | Descripción | Regla |
|---|---|---|---|---|
| `prd_id` | `INT` | No | Identificador del producto. | Se convierte a entero. |
| `cat_id` | `NVARCHAR(20)` | No | Identificador de categoría. | Primeros cinco caracteres de `prd_key`, con `-` → `_`. |
| `prd_key` | `NVARCHAR(50)` | No | Clave del producto. | Se toma desde el carácter 7. |
| `prd_nm` | `NVARCHAR(100)` | No | Nombre. | `TRIM`. |
| `prd_cost` | `INT` | No | Costo unitario. | Nulo o negativo → `0`. |
| `prd_line` | `NVARCHAR(30)` | No | Línea. | `M` → `Mountain`, `R` → `Road`, `S` → `Other Sales`, `T` → `Touring`, otro → `n/a`. |
| `prd_start_dt` | `DATE` | Sí | Inicio de vigencia. | `TRY_CONVERT`. |
| `prd_end_dt` | `DATE` | Sí | Fin de vigencia. | Día anterior al siguiente `prd_start_dt` del mismo producto. |

### silver.crm_sales_details

| Columna | Tipo | Nulo | Descripción | Regla |
|---|---|---|---|---|
| `sls_ord_num` | `NVARCHAR(30)` | No | Número de pedido. | `TRIM`. |
| `sls_prd_key` | `NVARCHAR(50)` | No | Clave del producto. | `TRIM`. |
| `sls_cust_id` | `INT` | Sí | Identificador del cliente. | Se convierte a entero. |
| `sls_order_dt` | `DATE` | Sí | Fecha del pedido. | `AAAAMMDD` → `DATE`; si es inválida, `NULL`. |
| `sls_ship_dt` | `DATE` | Sí | Fecha de envío. | `AAAAMMDD` → `DATE`; si es inválida, `NULL`. |
| `sls_due_dt` | `DATE` | Sí | Fecha de vencimiento. | `AAAAMMDD` → `DATE`; si es inválida, `NULL`. |
| `sls_sales` | `INT` | Sí | Monto total. | Si es nulo, menor o igual a cero, o distinto de `quantity × price`, se recalcula. |
| `sls_quantity` | `INT` | Sí | Cantidad. | Se convierte a entero. |
| `sls_price` | `INT` | Sí | Precio unitario. | Si es nulo o menor o igual a cero, se deriva de `sales / quantity`. |

### silver.erp_cust_az12

| Columna | Tipo | Nulo | Descripción | Regla |
|---|---|---|---|---|
| `cid` | `NVARCHAR(50)` | No | Identificador del cliente. | Se quita el prefijo `NAS`. |
| `bdate` | `DATE` | Sí | Fecha de nacimiento. | Futura o anterior a 1926 → `NULL`. |
| `gen` | `NVARCHAR(20)` | No | Género. | `M`/`Male` → `Male`, `F`/`Female` → `Female`, otro → `n/a`. |

### silver.erp_loc_a101

| Columna | Tipo | Nulo | Descripción | Regla |
|---|---|---|---|---|
| `cid` | `NVARCHAR(50)` | No | Identificador del cliente. | Se quitan los guiones. |
| `cntry` | `NVARCHAR(50)` | No | País. | `US`/`USA` → `United States`, `DE` → `Germany`, vacío → `n/a`. |

### silver.erp_px_cat_g1v2

| Columna | Tipo | Nulo | Descripción | Regla |
|---|---|---|---|---|
| `id` | `NVARCHAR(20)` | No | Identificador de categoría. | `TRIM`. |
| `cat` | `NVARCHAR(50)` | No | Categoría. | `TRIM`. |
| `subcat` | `NVARCHAR(50)` | No | Subcategoría. | `TRIM`. |
| `maintenance` | `NVARCHAR(20)` | No | Mantenimiento. | `TRIM`; vacío → `n/a`. |

## Gold

Vistas con el modelo estrella.

### gold.dim_customers

| Columna | Tipo | Descripción |
|---|---|---|
| `customer_key` | `INT` | Clave subrogada (PK). |
| `customer_id` | `INT` | Identificador natural. |
| `customer_number` | `NVARCHAR(50)` | Número de cliente (`cst_key`). |
| `first_name` | `NVARCHAR(50)` | Nombre. |
| `last_name` | `NVARCHAR(50)` | Apellido. |
| `country` | `NVARCHAR(50)` | País. |
| `marital_status` | `NVARCHAR(20)` | Estado civil. |
| `gender` | `NVARCHAR(20)` | Género del CRM; si es `n/a`, se usa el del ERP. |
| `birthdate` | `DATE` | Fecha de nacimiento. |
| `create_date` | `DATE` | Fecha de alta. |

### gold.dim_products

| Columna | Tipo | Descripción |
|---|---|---|
| `product_key` | `INT` | Clave subrogada (PK). |
| `product_id` | `INT` | Identificador natural. |
| `product_number` | `NVARCHAR(50)` | Clave del producto (`prd_key`). |
| `product_name` | `NVARCHAR(100)` | Nombre. |
| `category_id` | `NVARCHAR(20)` | Identificador de categoría. |
| `category` | `NVARCHAR(50)` | Categoría. |
| `subcategory` | `NVARCHAR(50)` | Subcategoría. |
| `maintenance` | `NVARCHAR(20)` | Requiere mantenimiento. |
| `cost` | `INT` | Costo unitario. |
| `product_line` | `NVARCHAR(30)` | Línea. |
| `start_date` | `DATE` | Inicio de vigencia. |

Solo se incluyen productos vigentes (`prd_end_dt IS NULL`).

### gold.fact_sales

| Columna | Tipo | Descripción |
|---|---|---|
| `order_number` | `NVARCHAR(30)` | Número de pedido (clave degenerada). |
| `product_key` | `INT` | FK a `gold.dim_products`. |
| `customer_key` | `INT` | FK a `gold.dim_customers`. |
| `order_date` | `DATE` | Fecha del pedido. |
| `shipping_date` | `DATE` | Fecha de envío. |
| `due_date` | `DATE` | Fecha de vencimiento. |
| `sales_amount` | `INT` | Monto de la línea. |
| `quantity` | `INT` | Cantidad vendida. |
| `price` | `INT` | Precio unitario. |

Granularidad: una fila por línea de pedido.
