# Examen Práctico 2do Momento – Superstore con Apache Hive

## Descripción
Proyecto individual de procesamiento y análisis del dataset Sample Superstore (9.994 filas, 21 columnas) usando Apache Hive.

## Objetivo
Modelar, cargar y analizar los datos de ventas con HiveQL. Este avance cubre la Pregunta 1: diseño del modelo de datos y carga.

## Requisitos
- Docker Desktop
- Imagen `apache/hive:4.0.1`
- Archivo `Sample - Superstore.csv` en la raíz del proyecto (codificado en Windows-1252, se convierte a UTF-8 antes de cargar)

## Procedimiento
1. Levantar Hive:
   ```
   docker run -d --name hive4_superstore -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 apache/hive:4.0.1
   ```
2. Convertir el CSV a UTF-8 (PowerShell) y copiarlo al contenedor:
   ```
   $t = [IO.File]::ReadAllText("Sample - Superstore.csv", [Text.Encoding]::GetEncoding(1252))
   [IO.File]::WriteAllText("superstore.csv", $t, (New-Object Text.UTF8Encoding $false))
   docker cp superstore.csv hive4_superstore:/tmp/superstore.csv
   ```
3. Ejecutar el script:
   ```
   docker cp pregunta1.sql hive4_superstore:/tmp/pregunta1.sql
   docker exec hive4_superstore beeline -u "jdbc:hive2://localhost:10000/" -f /tmp/pregunta1.sql
   ```

[pregunta1.sql](pregunta1.sql) carga el CSV en `stg_superstore` (todo STRING, con `OpenCSVSerde`) y llena la tabla analítica `ventas` (ORC) con los tipos correctos.

## Pregunta 1. Diseño e implementación del modelo de datos

### Diccionario de datos

| Campo CSV | Columna Hive | Tipo | Descripción | Restricciones |
|---|---|---|---|---|
| Row ID | row_id | INT | Identificador de fila | Único, no nulo |
| Order ID | order_id | STRING | Identificador del pedido | No nulo, se repite por línea |
| Order Date | order_date | DATE | Fecha del pedido | No nula, ≤ ship_date |
| Ship Date | ship_date | DATE | Fecha de envío | No nula, ≥ order_date |
| Ship Mode | ship_mode | STRING | Modalidad de envío | No nulo |
| Customer ID | customer_id | STRING | Identificador del cliente | No nulo |
| Customer Name | customer_name | STRING | Nombre del cliente | No nulo |
| Segment | segment | STRING | Segmento del cliente | No nulo |
| Country | country | STRING | País | No nulo |
| City | city | STRING | Ciudad | No nulo |
| State | state | STRING | Estado | No nulo |
| Postal Code | postal_code | STRING | Código postal de 5 dígitos | Texto, conserva ceros iniciales |
| Region | region | STRING | Región (Central, East, South, West) | No nulo |
| Product ID | product_id | STRING | Identificador del producto | No nulo |
| Category | category | STRING | Categoría | No nulo |
| Sub-Category | sub_category | STRING | Subcategoría | No nulo |
| Product Name | product_name | STRING | Nombre del producto | No nulo, puede tener comas |
| Sales | sales | DECIMAL(12,4) | Importe de la venta | Esperado > 0 |
| Quantity | quantity | INT | Unidades vendidas | Esperado ≥ 1 |
| Discount | discount | DECIMAL(4,2) | Descuento (fracción) | Esperado entre 0 y 1 |
| Profit | profit | DECIMAL(12,4) | Ganancia | Puede ser negativa |

### Resultados
Consultas ejecutadas en Hive sobre `superstore.ventas`:

| Verificación | Resultado |
|---|---|
| Registros en `stg_superstore` y `ventas` | 9.994 y 9.994 |
| `row_id` únicos | 9.994 |
| Rango de fechas | 2014-01-03 a 2017-12-30 |
| Fechas o números nulos | 0 |
| Órdenes / clientes únicos | 5.009 / 793 |
| Ventas / ganancia total | 2.297.200,86 / 286.397,02 |

Los totales coinciden con los calculados directamente sobre el CSV.

### Conclusión
Se cargaron los 9.994 registros sin pérdidas ni nulos. Se usó una tabla de paso en STRING porque el CSV trae fechas `M/d/yyyy`, comillas y códigos postales con ceros perdidos (438 de 4 dígitos, completados con `lpad`). La tabla `ventas` queda tipada y en ORC, lista para las siguientes preguntas.

## Pregunta 2. Auditoría de calidad e integridad de datos

### Estrategia
Con [pregunta2.sql](pregunta2.sql): una consulta con `stack` sobre `stg_superstore` cuenta nulos o vacíos en las 21 columnas, y otra reúne en una tabla (`UNION ALL`) los controles de duplicados, fechas, ventas y descuentos. Las fechas inválidas se buscan en `stg_superstore`, porque en `ventas` ya estarían convertidas. El resto se revisa en `ventas`.

Ejecución:
```
docker cp pregunta2.sql hive4_superstore:/tmp/pregunta2.sql
docker exec hive4_superstore beeline -u "jdbc:hive2://localhost:10000/" -f /tmp/pregunta2.sql
```

### Resultados (ejecutados en Hive)

| Control | Cantidad | Tratamiento propuesto |
|---|---|---|
| Total de registros | 9.994 | Referencia |
| `row_id` duplicados | 0 | Conservar un registro por `row_id` |
| Órdenes únicas | 5.009 | Referencia |
| Clientes únicos | 793 | Referencia |
| Nulos o vacíos (21 columnas) | 0 en todas | Imputar o excluir según el campo |
| Fechas inválidas | 0 | Excluir o corregir desde la fuente |
| Envío anterior al pedido | 0 | Excluir o intercambiar fechas |
| Ventas ≤ 0 | 0 | Excluir del análisis de ventas |
| Descuento fuera de 0–1 | 0 | Excluir o limitar a 0–1 |

### Interpretación

Los 9.994 registros no presentan duplicados, valores nulos ni errores en fechas, ventas o descuentos. Esto indica que los datos tienen buena calidad para realizar los análisis.

### Conclusión
Los datos son consistentes y se pueden usar sin limpieza adicional en las siguientes preguntas.
