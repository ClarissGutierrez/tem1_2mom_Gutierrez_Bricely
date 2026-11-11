USE superstore;

SELECT t.col AS campo, SUM(IF(t.v IS NULL OR trim(t.v) = '', 1, 0)) AS nulos_o_vacios
FROM stg_superstore
LATERAL VIEW stack(21,
  'row_id', row_id, 'order_id', order_id, 'order_date', order_date, 'ship_date', ship_date,
  'ship_mode', ship_mode, 'customer_id', customer_id, 'customer_name', customer_name,
  'segment', segment, 'country', country, 'city', city, 'state', state,
  'postal_code', postal_code, 'region', region, 'product_id', product_id,
  'category', category, 'sub_category', sub_category, 'product_name', product_name,
  'sales', sales, 'quantity', quantity, 'discount', discount, 'profit', profit
) t AS col, v
GROUP BY t.col;

SELECT 'total_registros' AS control, COUNT(*) AS cantidad, 'Referencia' AS tratamiento FROM ventas
UNION ALL
SELECT 'row_id_duplicados', COUNT(*) - COUNT(DISTINCT row_id), 'Conservar un registro por row_id' FROM ventas
UNION ALL
SELECT 'ordenes_unicas', COUNT(DISTINCT order_id), 'Referencia' FROM ventas
UNION ALL
SELECT 'clientes_unicos', COUNT(DISTINCT customer_id), 'Referencia' FROM ventas
UNION ALL
SELECT 'fechas_invalidas', COUNT(*), 'Excluir o corregir desde la fuente'
FROM stg_superstore
WHERE unix_timestamp(order_date, 'M/d/yyyy') IS NULL OR unix_timestamp(ship_date, 'M/d/yyyy') IS NULL
UNION ALL
SELECT 'envio_anterior_a_pedido', COUNT(*), 'Excluir o intercambiar fechas'
FROM ventas WHERE ship_date < order_date
UNION ALL
SELECT 'ventas_menores_o_iguales_a_cero', COUNT(*), 'Excluir del analisis de ventas'
FROM ventas WHERE sales <= 0
UNION ALL
SELECT 'descuento_fuera_de_0_a_1', COUNT(*), 'Excluir o limitar a 0-1'
FROM ventas WHERE discount < 0 OR discount > 1;
