USE superstore;

CREATE OR REPLACE VIEW rfm_clientes AS
WITH base AS (
  SELECT customer_id, customer_name,
         DATEDIFF((SELECT MAX(order_date) FROM ventas), MAX(order_date)) AS recency,
         COUNT(DISTINCT order_id) AS frequency,
         SUM(sales) AS monetary
  FROM ventas
  GROUP BY customer_id, customer_name
),
puntos AS (
  SELECT *,
         NTILE(5) OVER (ORDER BY recency DESC) AS r,
         NTILE(5) OVER (ORDER BY frequency, monetary) AS f,
         NTILE(5) OVER (ORDER BY monetary) AS m
  FROM base
)
SELECT *, r + f + m AS rfm_total,
       CASE WHEN r >= 4 AND m >= 4 THEN 'Alto valor'
            WHEN r <= 2 AND (f >= 3 OR m >= 3) THEN 'En riesgo'
            WHEN f >= 4 THEN 'Recurrente'
            ELSE 'Otros' END AS segmento
FROM puntos;

SELECT customer_id, customer_name, recency, frequency, ROUND(monetary, 2) AS monetary, r, f, m, rfm_total, segmento
FROM rfm_clientes
ORDER BY rfm_total DESC, monetary DESC
LIMIT 10;

SELECT segmento, COUNT(*) AS clientes, ROUND(AVG(recency), 1) AS recency_prom,
       ROUND(AVG(frequency), 1) AS frecuencia_prom, ROUND(SUM(monetary), 2) AS ventas,
       ROUND(SUM(monetary) / SUM(SUM(monetary)) OVER () * 100, 2) AS pct_ventas
FROM rfm_clientes
GROUP BY segmento
ORDER BY ventas DESC;
