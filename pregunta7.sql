USE superstore;

CREATE OR REPLACE VIEW tendencia_mensual AS
WITH mensual AS (
  SELECT date_format(order_date, 'yyyy-MM') AS mes,
         ROUND(SUM(sales), 2) AS ventas, ROUND(SUM(profit), 2) AS ganancia
  FROM ventas
  GROUP BY date_format(order_date, 'yyyy-MM')
)
SELECT mes, ventas, ganancia,
       ROUND((ventas - LAG(ventas, 1) OVER (ORDER BY mes))
             / NULLIF(LAG(ventas, 1) OVER (ORDER BY mes), 0) * 100, 2) AS var_mes_ant_pct,
       ROUND((ventas - LAG(ventas, 12) OVER (ORDER BY mes))
             / NULLIF(LAG(ventas, 12) OVER (ORDER BY mes), 0) * 100, 2) AS var_anio_ant_pct,
       IF(COUNT(*) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) = 3,
          ROUND(AVG(ventas) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2), NULL) AS prom_movil_3m,
       RANK() OVER (ORDER BY ventas DESC) AS rank_mayor,
       RANK() OVER (ORDER BY ventas) AS rank_menor
FROM mensual;

SELECT mes, ventas, ganancia, var_mes_ant_pct, var_anio_ant_pct, prom_movil_3m
FROM tendencia_mensual
ORDER BY mes;

SELECT 'Mayor' AS tipo, rank_mayor AS posicion, mes, ventas, ganancia
FROM tendencia_mensual WHERE rank_mayor <= 3
UNION ALL
SELECT 'Menor', rank_menor, mes, ventas, ganancia
FROM tendencia_mensual WHERE rank_menor <= 3
ORDER BY tipo, posicion;
