# Calidad de datos

Resultado del análisis de los seis archivos de origen y de las reglas aplicadas en Silver. Los
conteos salen de la ejecución del pipeline en SQL Server 2025.

## Resumen

- Archivos procesados: 6.
- Filas cargadas en Bronze: 116 294.
- Validaciones de Silver: 20 de 20 en PASS.
- Validaciones de Gold: 14 de 14 en PASS.
- Ventas con monto inconsistente después de Silver: 0.
- Claves huérfanas en `gold.fact_sales`: 0.

## Clientes (CRM)

- 4 registros con `cst_id` nulo o vacío: se excluyen.
- 6 filas adicionales en 5 grupos con `cst_id` duplicado: se conserva la de
  `cst_create_date` más reciente.
- 29 nombres o apellidos con espacios al inicio o al final: se aplica `TRIM`.
- 4 569 casos con género desconocido o vacío: se pasan a `n/a`.
- Estado civil: `S` se convierte en `Single` y `M` en `Married`.

Resultado: 18 494 filas en Bronze y 18 484 clientes únicos en Silver.

## Productos (CRM)

- 2 productos con `prd_cost` vacío: se reemplaza por `0`.
- 17 productos con `prd_line` desconocida: se pasan a `n/a`.
- 200 registros con `prd_end_dt` anterior a `prd_start_dt`: se recalcula la vigencia con
  `LEAD(prd_start_dt)`.
- 102 productos descontinuados: se excluyen de `gold.dim_products`.
- 7 productos sin categoría en el ERP: categoría, subcategoría y mantenimiento quedan en `n/a`.

Resultado: 397 productos en Silver y 295 vigentes en Gold.

## Ventas (CRM)

- 19 fechas de pedido inválidas o vacías: se convierten a `NULL`, sin descartar la venta.
- 12 registros con `sls_price` nulo o menor o igual a cero: el precio se deriva de
  `sales / quantity`.
- 13 registros con `sls_sales` nulo o menor o igual a cero: el monto se recalcula.
- 20 registros con `sls_sales` distinto de `quantity × price`: se recalcula el monto.

Resultado: 60 398 ventas, todas con `sales = quantity × price` y sin pérdida de filas.

## ERP

- 11 042 `cid` con prefijo `NAS`: se quita el prefijo para unir con `cst_key`.
- 18 484 `cid` con guiones: se eliminan los guiones.
- 35 fechas de nacimiento futuras o anteriores a 1926: se reemplazan por `NULL`.
- 337 países vacíos: se pasan a `n/a`.
- 4 091 casos con `US` o `USA`: se convierten en `United States`.
- 566 casos con `DE`: se convierten en `Germany`.

## Integridad referencial en Gold

- Ventas con producto inexistente: 0.
- Ventas con cliente inexistente: 0.
- Claves subrogadas duplicadas: 0.
- Productos no vigentes incluidos: 0.
- Filas de `fact_sales` distintas de Silver: 0.
- Diferencia de monto total entre Gold y Silver: 0.

## Modelo final

- `gold.dim_customers`: 18 484 filas.
- `gold.dim_products`: 295 filas.
- `gold.fact_sales`: 60 398 filas.
- Monto total vendido: 29 356 250.
- Unidades vendidas: 60 423.

## Conclusión

El pipeline carga el 100 % de las filas de origen en Bronze, depura y estandariza sin perder
ventas en Silver, y expone un modelo estrella consistente en Gold. Las 34 validaciones
automáticas terminan en PASS, así que los datos sirven para reportes y análisis.
