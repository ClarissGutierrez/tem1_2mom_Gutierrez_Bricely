# Examen Práctico 2do Momento – Apache Hive

## Descripción

Análisis del dataset Sample Superstore utilizando Apache Hive. Contiene 9.994 registros de ventas y 21 columnas.

## Objetivo

Cargar, organizar y analizar los datos mediante consultas HiveQL.

## Requisitos

- Docker Desktop
- Apache Hive 4.0.1
- Archivo `Sample - Superstore.csv`

## Ejecución

Iniciar Hive con Docker:

```bash
docker run -d --name hive4_superstore -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 apache/hive:4.0.1
```

Convertir el CSV a UTF-8 desde PowerShell:

```powershell
$t = [IO.File]::ReadAllText("Sample - Superstore.csv", [Text.Encoding]::GetEncoding(1252))
[IO.File]::WriteAllText("superstore.csv", $t, (New-Object Text.UTF8Encoding $false))
docker cp superstore.csv hive4_superstore:/tmp/superstore.csv
```

Ejecutar la primera pregunta:

```bash
docker cp pregunta1.sql hive4_superstore:/tmp/pregunta1.sql
docker exec hive4_superstore beeline -u "jdbc:hive2://localhost:10000/" -f /tmp/pregunta1.sql
```

Para las siguientes preguntas se utilizan los mismos dos comandos, cambiando `pregunta1.sql` por el archivo correspondiente.

## Pregunta 1. Modelo de datos

Se creó una tabla temporal para leer el CSV y una tabla `ventas` en formato ORC con los tipos de datos correspondientes.

### Diccionario de datos

| Campo | Tipo Hive | Descripción y restricciones |
|---|---|---|
| row_id | INT | ID de fila, único |
| order_id | STRING | ID del pedido, puede repetirse |
| order_date | DATE | Fecha del pedido, no nula |
| ship_date | DATE | Fecha de envío, posterior o igual al pedido |
| ship_mode | STRING | Tipo de envío |
| customer_id | STRING | ID del cliente |
| customer_name | STRING | Nombre del cliente |
| segment | STRING | Segmento del cliente |
| country | STRING | País |
| city | STRING | Ciudad |
| state | STRING | Estado |
| postal_code | STRING | Código postal de 5 dígitos |
| region | STRING | Región |
| product_id | STRING | ID del producto |
| category | STRING | Categoría |
| sub_category | STRING | Subcategoría |
| product_name | STRING | Nombre del producto |
| sales | DECIMAL(12,4) | Venta, valor positivo esperado |
| quantity | INT | Cantidad, mínimo 1 |
| discount | DECIMAL(4,2) | Descuento entre 0 y 1 |
| profit | DECIMAL(12,4) | Ganancia, puede ser negativa |

**Consulta:** `pregunta1.sql`

**Resultado:** Se cargaron 9.994 registros, con 5.009 órdenes y 793 clientes únicos. Las ventas fueron 2.297.200,86 y las ganancias 286.397,02.

**Interpretación:** Se conservaron todos los registros y se corrigió el formato de fechas y códigos postales.

**Conclusión:** La tabla quedó preparada para los análisis.

## Pregunta 2. Calidad de datos

Se revisaron registros duplicados, nulos, fechas, ventas y descuentos.

**Consulta:** `pregunta2.sql`

| Control | Resultado |
|---|---|
| Registros | 9.994 |
| ID duplicados | 0 |
| Órdenes únicas | 5.009 |
| Clientes únicos | 793 |
| Valores nulos o vacíos | 0 |
| Fechas inválidas | 0 |
| Envíos anteriores al pedido | 0 |
| Ventas menores o iguales a cero | 0 |
| Descuentos fuera de rango | 0 |

**Tratamiento:** Si se encontraran errores, se revisarían los datos originales para corregirlos o excluir los registros afectados.

**Interpretación:** No se encontraron inconsistencias en los controles realizados.

**Conclusión:** Los datos pueden utilizarse para los siguientes análisis.

## Pregunta 3. Ventas por región

Se agruparon las ventas y ganancias por región y año. Se utilizaron CTE, `LAG()` para la variación anual y `RANK()` para la clasificación.

**Consulta:** `pregunta3.sql`

| Región | Ventas | Ganancia | Margen |
|---|---|---|---|
| West | 725.457,82 | 108.418,45 | 14,94 % |
| East | 678.781,24 | 91.522,78 | 13,48 % |
| Central | 501.239,89 | 39.706,36 | 7,92 % |
| South | 391.721,91 | 46.749,43 | 11,93 % |

**Interpretación:** West tiene las mayores ventas y ganancias. South registra las menores ventas y Central tiene el margen más bajo.

**Conclusión:** West presenta el mejor desempeño general. Central necesita revisar su rentabilidad.

## Pregunta 4. Segmentación RFM

Se clasificaron los clientes utilizando:

- **Recency:** días desde la última compra, respecto al 30/12/2017.
- **Frequency:** cantidad de órdenes únicas.
- **Monetary:** total de ventas por cliente.

Se utilizaron puntuaciones de 1 a 5 mediante `NTILE(5)`.

**Criterios:**

- Alto valor: R ≥ 4 y M ≥ 4.
- En riesgo: R ≤ 2 y (F ≥ 3 o M ≥ 3).
- Recurrente: F ≥ 4, si no pertenece a los anteriores.
- Otros: clientes restantes.

**Consulta:** `pregunta4.sql`

| Segmento | Clientes | Ventas |
|---|---|---|
| Alto valor | 146 | 760.684,20 |
| En riesgo | 196 | 689.323,63 |
| Otros | 326 | 461.967,25 |
| Recurrente | 125 | 385.225,78 |

**Interpretación:** Los clientes de alto valor generan el 33,11 % de las ventas. Los clientes en riesgo representan el 30,01 % y llevan más tiempo sin comprar.

**Conclusión:** Es importante mantener a los clientes de alto valor y recuperar a los clientes en riesgo.

## Evidencias

Las capturas de ejecución y resultados de cada pregunta están guardadas en la carpeta `evidencias`.

## Pregunta 5. Ranking de productos según rentabilidad

### Estrategia
[pregunta5.sql](pregunta5.sql) crea la vista `productos_rank` con CTE, agrupando por `product_id` (1.862 productos). Cada producto lleva ventas, ganancia y margen (ganancia / ventas × 100), más cuatro columnas de posición:
- `RANK()` por ganancia dentro de su categoría (`pos_categoria`).
- `SUM() OVER` acumulado de la ganancia por categoría (`ganancia_acum_cat`).
- `RANK()` por unidades vendidas, `SUM(quantity)` (`rank_unidades`).
- `DENSE_RANK()` por margen, de menor a mayor (`rank_rentabilidad`).

Tres consultas filtran los 5 mejores de cada ranking. Criterio de menor rentabilidad: **margen más bajo**. 32 `product_id` tienen más de un nombre; se toma uno con `MAX`. Ninguno tiene más de una categoría, y las ventas de la vista suman 2.297.200,86.

```
docker cp pregunta5.sql hive4_superstore:/tmp/pregunta5.sql
docker exec hive4_superstore beeline -u "jdbc:hive2://localhost:10000/" -f /tmp/pregunta5.sql
```

### Resultados principales (ejecutados en Hive)

Mayor ganancia por categoría (primer lugar de cada una):

| Categoría | Producto | Ganancia | Margen % | Acumulado top 5 |
|---|---|---|---|---|
| Technology | Canon imageCLASS 2200 Advanced Copier | 25.199,93 | 40,91 | 45.275,07 |
| Office Supplies | Fellowes PB500 Electric Punch Plastic Comb Binding Machine | 7.753,04 | 28,24 | 19.181,73 |
| Furniture | Hon Deluxe Fabric Upholstered Stacking Chairs | 1.927,44 | 18,12 | 7.721,02 |

Mayor volumen de ventas (por unidades, `SUM(quantity)`; el importe de ventas es información adicional):

| Pos. | Producto | Unidades | Ventas |
|---|---|---|---|
| 1 | Logitech P710e Mobile Speakerphone | 75 | 11.203,76 |
| 2 | Xerox 1908 | 70 | 2.167,35 |
| 3 | GBC Premium Transparent Covers with Diagonal Lined Pattern | 67 | 780,46 |
| 4 (empate) | Situations Contoured Folding Chairs, 4/Set | 64 | 3.641,27 |
| 4 (empate) | Ibico Recycled Linen-Style Covers | 64 | 2.068,82 |

Menor rentabilidad (margen): Eureka Disposable Bags (−275 %), Bush Westfield Bookcases (−210 %), Euro Pro Shark Stick Mini Vacuum (−190,71 %), Okidata B401 Printer (−140 %) y Zebra GK420t Printer (−133,33 %).

### Interpretación
En Technology, el Canon imageCLASS 2200 es el producto con más ganancia (25.199,93, margen de 41 %). Entre los productos con más unidades, el Xerox 1908 vende 70 unidades con margen de 46 %, pero otros como las Situations Contoured Folding Chairs (6 %) y los GBC Premium Covers (6 %) dejan poco margen. Los cinco de menor margen venden poco, pero todos pierden dinero; el Zebra GK420t, por ejemplo, pierde 938,28 con 703,71 en ventas.

### Conclusión
El producto más vendido en unidades (Logitech P710e, 75) no es el que más ingresa ni el que más gana. Las unidades vendidas no garantizan rentabilidad, y los productos con margen muy negativo deberían revisarse o retirarse.

## Pregunta 6. Impacto de los descuentos

### Estrategia
[pregunta6.sql](pregunta6.sql) tiene tres consultas sobre `ventas`. La primera clasifica cada registro con `CASE` según su descuento (sin descuento = 0, bajo ≤ 0,20, medio ≤ 0,50, alto > 0,50) y calcula ventas, ganancia, margen, registros con pérdidas (`profit < 0`), porcentaje de no rentables (`profit <= 0`) y descuento promedio. La segunda y la tercera suman las pérdidas por subcategoría (las 5 peores) y por categoría.

```
docker cp pregunta6.sql hive4_superstore:/tmp/pregunta6.sql
docker exec hive4_superstore beeline -u "jdbc:hive2://localhost:10000/" -f /tmp/pregunta6.sql
```

### Resultados principales (ejecutados en Hive)

| Rango | Registros | Ventas | Ganancia | Margen % | Con pérdidas | No rentables % | Desc. prom. % |
|---|---|---|---|---|---|---|---|
| Sin descuento | 4.798 | 1.087.908,47 | 320.987,60 | 29,51 | 0 | 0,63 | 0,00 |
| Bajo | 3.803 | 846.522,24 | 100.785,47 | 11,91 | 523 | 14,33 | 19,68 |
| Medio | 537 | 298.541,41 | −58.817,00 | −19,70 | 492 | 94,04 | 36,70 |
| Alto | 856 | 64.228,74 | −76.559,05 | −119,20 | 856 | 100,00 | 71,89 |

Los registros suman 9.994 y las ventas 2.297.200,86, igual que la Pregunta 1.

Subcategorías con más pérdidas (suma de los `profit` negativos): Binders (−38.510,50; 613 registros con pérdida; descuento promedio 37,23 %), Tables (−32.412,15; ganancia total negativa), Machines (−30.118,67), Bookcases (−12.152,21) y Chairs (−9.880,84). Por categoría, Furniture acumula más pérdidas (−60.936,11) y tiene el mayor descuento promedio (17,39 %); Office Supplies tiene más registros con pérdida (886).

### Interpretación
Hasta un descuento de 20 % las ventas siguen siendo rentables (margen 11,91 %). Con descuento medio el margen ya es negativo, y con descuento alto los 856 registros pierden dinero: vendieron 64.228,74 y perdieron 76.559,05. Binders, Tables y Machines tienen descuentos promedio de 26 % a 37 %, y son las subcategorías con más pérdidas.

### Conclusión
Sí: los descuentos altos están asociados con más operaciones no rentables. El porcentaje sube de 0,63 % sin descuento a 14,33 % (bajo), 94,04 % (medio) y 100 % (alto). Conviene limitar los descuentos por encima de 20 %, sobre todo en Binders, Tables y Machines.
