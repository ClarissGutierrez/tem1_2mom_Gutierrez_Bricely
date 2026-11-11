USE superstore;

SELECT CASE WHEN discount = 0 THEN 'Sin descuento'
            WHEN discount <= 0.20 THEN 'Bajo'
            WHEN discount <= 0.50 THEN 'Medio'
            ELSE 'Alto' END AS rango,
       COUNT(*) AS registros,
       ROUND(SUM(sales), 2) AS ventas,
       ROUND(SUM(profit), 2) AS ganancia,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margen_pct,
       SUM(IF(profit < 0, 1, 0)) AS con_perdidas,
       ROUND(SUM(IF(profit <= 0, 1, 0)) / COUNT(*) * 100, 2) AS no_rentables_pct,
       ROUND(AVG(discount) * 100, 2) AS desc_prom_pct
FROM ventas
GROUP BY CASE WHEN discount = 0 THEN 'Sin descuento'
              WHEN discount <= 0.20 THEN 'Bajo'
              WHEN discount <= 0.50 THEN 'Medio'
              ELSE 'Alto' END
ORDER BY desc_prom_pct;

SELECT category AS categoria, sub_category AS subcategoria,
       COUNT(*) AS registros,
       ROUND(AVG(discount) * 100, 2) AS desc_prom_pct,
       SUM(IF(profit < 0, 1, 0)) AS con_perdidas,
       ROUND(SUM(IF(profit < 0, profit, 0)), 2) AS perdida_total,
       ROUND(SUM(profit), 2) AS ganancia
FROM ventas
GROUP BY category, sub_category
ORDER BY perdida_total
LIMIT 5;

SELECT category AS categoria,
       COUNT(*) AS registros,
       ROUND(AVG(discount) * 100, 2) AS desc_prom_pct,
       SUM(IF(profit < 0, 1, 0)) AS con_perdidas,
       ROUND(SUM(IF(profit < 0, profit, 0)), 2) AS perdida_total,
       ROUND(SUM(profit), 2) AS ganancia
FROM ventas
GROUP BY category
ORDER BY perdida_total;
