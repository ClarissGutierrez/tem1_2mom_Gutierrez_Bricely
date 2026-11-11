USE superstore;

CREATE OR REPLACE VIEW productos_rank AS
WITH prod AS (
  SELECT product_id, MAX(product_name) AS producto, MAX(category) AS categoria,
         SUM(quantity) AS unidades, SUM(sales) AS ventas, SUM(profit) AS ganancia
  FROM ventas
  GROUP BY product_id
)
SELECT product_id, producto, categoria, unidades, ventas, ganancia,
       ganancia / ventas * 100 AS margen_pct,
       RANK() OVER (PARTITION BY categoria ORDER BY ganancia DESC) AS pos_categoria,
       SUM(ganancia) OVER (PARTITION BY categoria ORDER BY ganancia DESC) AS ganancia_acum_cat,
       RANK() OVER (ORDER BY unidades DESC) AS rank_unidades,
       DENSE_RANK() OVER (ORDER BY ganancia / ventas) AS rank_rentabilidad
FROM prod;

SELECT categoria, pos_categoria, product_id, producto, ROUND(ventas, 2) AS ventas,
       ROUND(ganancia, 2) AS ganancia, ROUND(margen_pct, 2) AS margen_pct,
       ROUND(ganancia_acum_cat, 2) AS ganancia_acum_cat
FROM productos_rank
WHERE pos_categoria <= 5
ORDER BY categoria, pos_categoria;

SELECT rank_unidades, product_id, producto, categoria, unidades, ROUND(ventas, 2) AS ventas,
       ROUND(ganancia, 2) AS ganancia, ROUND(margen_pct, 2) AS margen_pct
FROM productos_rank
WHERE rank_unidades <= 5
ORDER BY rank_unidades;

SELECT rank_rentabilidad, product_id, producto, categoria, ROUND(ventas, 2) AS ventas,
       ROUND(ganancia, 2) AS ganancia, ROUND(margen_pct, 2) AS margen_pct
FROM productos_rank
WHERE rank_rentabilidad <= 5
ORDER BY rank_rentabilidad;
