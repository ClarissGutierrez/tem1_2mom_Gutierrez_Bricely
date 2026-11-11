USE superstore;

CREATE OR REPLACE VIEW pareto_productos AS
WITH prod AS (
  SELECT product_id, MAX(product_name) AS producto,
         SUM(sales) AS ventas, SUM(profit) AS ganancia
  FROM ventas
  GROUP BY product_id
)
SELECT product_id, producto, ventas, ganancia,
       ROW_NUMBER() OVER (ORDER BY ventas DESC, product_id) AS pos_ventas,
       ventas / SUM(ventas) OVER () * 100 AS pct_ventas,
       SUM(ventas) OVER (ORDER BY ventas DESC, product_id
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / SUM(ventas) OVER () * 100 AS acum_ventas,
       ROW_NUMBER() OVER (ORDER BY ganancia DESC, product_id) AS pos_ganancia,
       ganancia / SUM(ganancia) OVER () * 100 AS pct_ganancia,
       SUM(ganancia) OVER (ORDER BY ganancia DESC, product_id
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / SUM(ganancia) OVER () * 100 AS acum_ganancia
FROM prod;

SELECT 'Ventas' AS analisis, (SELECT COUNT(*) FROM pareto_productos) AS productos_total,
       MIN(pos_ventas) AS productos_80,
       ROUND(MIN(pos_ventas) / (SELECT COUNT(*) FROM pareto_productos) * 100, 2) AS pct_productos
FROM pareto_productos WHERE acum_ventas >= 80
UNION ALL
SELECT 'Ganancia', (SELECT COUNT(*) FROM pareto_productos), MIN(pos_ganancia),
       ROUND(MIN(pos_ganancia) / (SELECT COUNT(*) FROM pareto_productos) * 100, 2)
FROM pareto_productos WHERE acum_ganancia >= 80;

SELECT pos_ventas, product_id, producto, ROUND(ventas, 2) AS ventas,
       ROUND(pct_ventas, 2) AS pct, ROUND(acum_ventas, 2) AS pct_acum
FROM pareto_productos WHERE pos_ventas <= 10 ORDER BY pos_ventas;

SELECT pos_ganancia, product_id, producto, ROUND(ganancia, 2) AS ganancia,
       ROUND(pct_ganancia, 2) AS pct, ROUND(acum_ganancia, 2) AS pct_acum
FROM pareto_productos WHERE pos_ganancia <= 10 ORDER BY pos_ganancia;

SELECT COUNT(*) AS productos, ROUND(SUM(ventas), 2) AS ventas_total, ROUND(SUM(ganancia), 2) AS ganancia_total,
       SUM(IF(ganancia < 0, 1, 0)) AS productos_con_perdida,
       ROUND(SUM(IF(ganancia > 0, ganancia, 0)), 2) AS ganancia_positiva,
       ROUND(SUM(IF(ganancia < 0, ganancia, 0)), 2) AS perdida_total
FROM pareto_productos;
