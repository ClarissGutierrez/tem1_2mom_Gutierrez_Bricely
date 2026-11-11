# Examen Práctico – Apache Hive

## Descripción

Análisis de **Sample Superstore** (9.994 registros, 21 campos) mediante Apache Hive y HiveQL.

## Objetivo

Cargar los datos y analizar su calidad, ventas, clientes, productos y rentabilidad.

## Requisitos

Docker Desktop, imagen `apache/hive:4.0.1` y archivo `Sample - Superstore.csv`.

## Ejecución

Iniciar Hive:

```bash
docker run -d --name hive4_superstore -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 apache/hive:4.0.1
```

Desde **PowerShell**, convertir el CSV a UTF-8 y copiarlo al contenedor:

```powershell
$t = [IO.File]::ReadAllText("Sample - Superstore.csv", [Text.Encoding]::GetEncoding(1252))
[IO.File]::WriteAllText("superstore.csv", $t, (New-Object Text.UTF8Encoding $false))
docker cp superstore.csv hive4_superstore:/tmp/superstore.csv
```

Ejecutar primero la Pregunta 1:

```bash
docker cp pregunta1.sql hive4_superstore:/tmp/pregunta1.sql
docker exec hive4_superstore beeline -u "jdbc:hive2://localhost:10000/" -f /tmp/pregunta1.sql
```

Para las preguntas 2 a 8, repetir los dos últimos comandos cambiando el número del archivo SQL. Las capturas de ejecución están en `evidencias/`.

## Pregunta 1. Modelo de datos

Se cargó el CSV en `stg_superstore` y se creó `ventas` en formato ORC, convirtiendo fechas, números y códigos postales. **SQL:** [pregunta1.sql](pregunta1.sql).

**Diccionario de datos**

| Columna | Tipo Hive | Descripción y restricción |
|---|---|---|
| row_id | INT | Identificador de fila, único |
| order_id | STRING | Identificador de pedido, puede repetirse |
| order_date | DATE | Fecha de pedido, no posterior al envío |
| ship_date | DATE | Fecha de envío, no anterior al pedido |
| ship_mode | STRING | Modalidad de envío |
| customer_id | STRING | Identificador del cliente |
| customer_name | STRING | Nombre del cliente |
| segment | STRING | Segmento del cliente |
| country | STRING | País |
| city | STRING | Ciudad |
| state | STRING | Estado |
| postal_code | STRING | Código postal, conserva ceros iniciales |
| region | STRING | Región |
| product_id | STRING | Identificador del producto |
| category | STRING | Categoría |
| sub_category | STRING | Subcategoría |
| product_name | STRING | Nombre del producto, puede contener comas |
| sales | DECIMAL(12,4) | Venta, se espera positiva |
| quantity | INT | Unidades, mínimo esperado 1 |
| discount | DECIMAL(4,2) | Descuento entre 0 y 1 |
| profit | DECIMAL(12,4) | Ganancia, puede ser negativa |

**Resultado:** 9.994 registros, 5.009 órdenes y 793 clientes; ventas de 2.297.200,86 y ganancias de 286.397,02. Los registros se conservaron y la tabla quedó lista para el análisis. [Evidencia](evidencias/pregunta1_registros.png).

## Pregunta 2. Calidad de datos

Se buscaron duplicados, nulos, fechas incorrectas, ventas no positivas y descuentos fuera de rango. **SQL:** [pregunta2.sql](pregunta2.sql). **Resultado:** 9.994 registros y 0 errores en los controles realizados. Ante errores, corresponde revisar el origen y corregir o excluir los datos afectados. **Conclusión:** los datos son aptos para el análisis. [Evidencia](evidencias/pregunta2_calidad.png).

## Pregunta 3. Evolución comercial por región

Se agruparon ventas y ganancias por región y año; `LAG()` calculó la variación anual y `RANK()` el orden regional. **SQL:** [pregunta3.sql](pregunta3.sql). **Resultado:** West lideró en ventas (725.457,82), South tuvo las menores (391.721,91) y Central el menor margen (7,92 %). **Conclusión:** vender más no siempre implica mayor rentabilidad. [Evidencia](evidencias/pregunta3_ranking.png).

## Pregunta 4. Segmentación RFM

Se calcularon recencia (hasta el 30/12/2017), órdenes únicas y ventas por cliente, con puntuaciones `NTILE(5)`. Criterios: alto valor (R≥4 y M≥4), en riesgo (R≤2 y (F≥3 o M≥3)), recurrente (F≥4, si no pertenece a los anteriores) y otros. **SQL:** [pregunta4.sql](pregunta4.sql). **Resultado:** 146 clientes de alto valor, 196 en riesgo, 125 recurrentes y 326 restantes. **Conclusión:** conviene mantener a los clientes de alto valor y recuperar los que están en riesgo. [Evidencia](evidencias/pregunta4_segmentos.png).

## Pregunta 5. Ranking de productos

Se calcularon posiciones, márgenes, unidades y ganancias acumuladas mediante `RANK()`, `DENSE_RANK()` y `SUM() OVER`. **SQL:** [pregunta5.sql](pregunta5.sql). **Resultado:** Canon imageCLASS 2200 lideró en ganancia (25.199,93) y Logitech P710e en unidades (75). Los cinco de menor margen tuvieron pérdidas. **Conclusión:** vender más unidades no garantiza mayor ganancia. [Evidencias](evidencias/pregunta5_categorias.png).

## Pregunta 6. Impacto de los descuentos

Se compararon descuentos de 0 %, bajos (hasta 20 %), medios (hasta 50 %) y altos (más de 50 %), calculando ventas, ganancias, márgenes y pérdidas por rango y categoría. **SQL:** [pregunta6.sql](pregunta6.sql). **Resultado:** las operaciones no rentables representaron 0,63 %, 14,33 %, 94,04 % y 100 %, respectivamente. Furniture acumuló las mayores pérdidas. **Conclusión:** los descuentos altos se relacionan con más operaciones no rentables. [Evidencia](evidencias/pregunta6_descuentos.png).

## Pregunta 7. Tendencias temporales

Se analizaron 48 meses con `LAG()` para variaciones mensuales e interanuales y promedio móvil de tres meses. **SQL:** [pregunta7.sql](pregunta7.sql). **Resultado:** noviembre de 2017 registró las mayores ventas (118.447,83) y febrero de 2014 las menores (4.519,89). **Conclusión:** las ventas muestran picos al final del año y caídas al inicio. [Evidencia](evidencias/pregunta7_ranking.png).

## Pregunta 8. Análisis Pareto

Se ordenaron productos por ventas y ganancias, calculando porcentajes individuales y acumulados con `SUM() OVER`. **SQL:** [pregunta8.sql](pregunta8.sql). **Resultado:** 414 productos (22,23 %) alcanzan el 80 % de las ventas y 164 (8,81 %) el 80 % de la ganancia neta, considerando las pérdidas. **Conclusión:** las ganancias están más concentradas que las ventas. [Evidencia](evidencias/pregunta8_resumen.png).

## Optimización

Se utilizó ORC para almacenamiento por columnas, tipos de datos adecuados y vistas para reutilizar cálculos. No se midieron tiempos comparativos de rendimiento.

## Conclusión general

Los análisis permitieron identificar clientes y productos importantes, diferencias entre regiones y el impacto de los descuentos en las ganancias.
