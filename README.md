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
