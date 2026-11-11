USE superstore;

WITH anual AS (
  SELECT region, YEAR(order_date) AS anio,
         ROUND(SUM(sales), 2) AS ventas, ROUND(SUM(profit), 2) AS ganancia
  FROM ventas
  GROUP BY region, YEAR(order_date)
)
SELECT region, anio, ventas, ganancia,
       ROUND(ganancia / ventas * 100, 2) AS margen_pct,
       ROUND((ventas - LAG(ventas) OVER (PARTITION BY region ORDER BY anio))
             / LAG(ventas) OVER (PARTITION BY region ORDER BY anio) * 100, 2) AS var_ventas_pct
FROM anual
ORDER BY region, anio;

WITH total AS (
  SELECT region, ROUND(SUM(sales), 2) AS ventas, ROUND(SUM(profit), 2) AS ganancia
  FROM ventas
  GROUP BY region
)
SELECT region, ventas, ganancia,
       ROUND(ganancia / ventas * 100, 2) AS margen_pct,
       RANK() OVER (ORDER BY ventas DESC) AS rank_ventas,
       RANK() OVER (ORDER BY ganancia DESC) AS rank_ganancia,
       CASE WHEN RANK() OVER (ORDER BY ventas DESC) = 1 THEN 'MEJOR'
            WHEN RANK() OVER (ORDER BY ventas ASC) = 1 THEN 'PEOR'
            ELSE '' END AS desempeno
FROM total
ORDER BY rank_ventas;
