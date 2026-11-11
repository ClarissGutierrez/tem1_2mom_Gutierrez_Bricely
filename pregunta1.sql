CREATE DATABASE IF NOT EXISTS superstore;
USE superstore;

DROP TABLE IF EXISTS stg_superstore;
CREATE TABLE stg_superstore (
  row_id STRING, order_id STRING, order_date STRING, ship_date STRING,
  ship_mode STRING, customer_id STRING, customer_name STRING, segment STRING,
  country STRING, city STRING, state STRING, postal_code STRING, region STRING,
  product_id STRING, category STRING, sub_category STRING, product_name STRING,
  sales STRING, quantity STRING, discount STRING, profit STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"')
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count' = '1');

LOAD DATA LOCAL INPATH '/tmp/superstore.csv' OVERWRITE INTO TABLE stg_superstore;

DROP TABLE IF EXISTS ventas;
CREATE TABLE ventas (
  row_id INT, order_id STRING, order_date DATE, ship_date DATE,
  ship_mode STRING, customer_id STRING, customer_name STRING, segment STRING,
  country STRING, city STRING, state STRING, postal_code STRING, region STRING,
  product_id STRING, category STRING, sub_category STRING, product_name STRING,
  sales DECIMAL(12,4), quantity INT, discount DECIMAL(4,2), profit DECIMAL(12,4)
)
STORED AS ORC;

INSERT INTO TABLE ventas
SELECT
  CAST(row_id AS INT), order_id,
  CAST(from_unixtime(unix_timestamp(order_date, 'M/d/yyyy'), 'yyyy-MM-dd') AS DATE),
  CAST(from_unixtime(unix_timestamp(ship_date, 'M/d/yyyy'), 'yyyy-MM-dd') AS DATE),
  ship_mode, customer_id, customer_name, segment, country, city, state,
  lpad(postal_code, 5, '0'), region, product_id, category, sub_category, product_name,
  CAST(sales AS DECIMAL(12,4)), CAST(quantity AS INT),
  CAST(discount AS DECIMAL(4,2)), CAST(profit AS DECIMAL(12,4))
FROM stg_superstore;
