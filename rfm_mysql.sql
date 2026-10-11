-- 1) Table
CREATE DATABASE IF NOT EXISTS rfm_project;
USE rfm_project;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id         VARCHAR(10) PRIMARY KEY,
  customer_id      VARCHAR(10) NOT NULL,
  order_date       DATE NOT NULL,
  product_category VARCHAR(30),
  quantity         INT,
  unit_price       DECIMAL(10,2),
  order_value      DECIMAL(12,2),
  city             VARCHAR(30),
  payment_method   VARCHAR(20)
);

-- 2) Import (agar LOAD DATA error de to Workbench: Table Data Import Wizard use kar)
-- SET GLOBAL local_infile = 1;  -- ek baar, root se
-- Path apna daal (forward slashes use kar):
LOAD DATA LOCAL INFILE 'C:/path/to/ecommerce_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- 3) Check (expected: 12523 rows, 2000 customers)
SELECT COUNT(*) AS total_orders, COUNT(DISTINCT customer_id) AS customers FROM orders;

-- 4) RFM scores (MySQL 8+)
CREATE OR REPLACE VIEW rfm_scores AS
WITH base AS (
  SELECT customer_id,
         DATEDIFF('2026-10-01', MAX(order_date)) AS recency,
         COUNT(order_id)                         AS frequency,
         SUM(order_value)                        AS monetary
  FROM orders
  GROUP BY customer_id
),
scored AS (
  SELECT *,
         NTILE(5) OVER (ORDER BY recency DESC)  AS r_score,
         NTILE(5) OVER (ORDER BY frequency)     AS f_score,
         NTILE(5) OVER (ORDER BY monetary)      AS m_score
  FROM base
)
SELECT *,
  CASE
    WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
    WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
    WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
    WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
    ELSE 'Needs Attention'
  END AS segment
FROM scored;

-- 5) Tableau ke liye export
SELECT * FROM rfm_scores;
