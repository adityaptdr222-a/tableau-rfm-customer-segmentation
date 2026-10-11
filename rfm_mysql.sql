-- =====================================================================
-- Project : Customer Segmentation using RFM Analysis
-- Database: MySQL 8+
-- Dataset : Synthetic Indian e-commerce orders (12,523 orders, 2,000 customers)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Database and table setup
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS rfm_project;
USE rfm_project;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id         VARCHAR(10) PRIMARY KEY,
  customer_id      VARCHAR(10) NOT NULL,
  order_date       DATE        NOT NULL,
  product_category VARCHAR(30),
  quantity         INT,
  unit_price       DECIMAL(10,2),
  order_value      DECIMAL(12,2),
  city             VARCHAR(30),
  payment_method   VARCHAR(20)
);

-- ---------------------------------------------------------------------
-- 2. Data import
-- Update the file path before running. Use forward slashes.
-- If LOAD DATA is blocked, enable it with: SET GLOBAL local_infile = 1;
-- Alternatively, use MySQL Workbench: Table Data Import Wizard.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/ecommerce_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- ---------------------------------------------------------------------
-- 3. Data validation
-- Expected result: 12523 orders, 2000 customers
-- ---------------------------------------------------------------------
SELECT COUNT(*)                    AS total_orders,
       COUNT(DISTINCT customer_id) AS customers
FROM orders;

-- ---------------------------------------------------------------------
-- 4. RFM scoring
-- Recency   : days since last order (reference date: 2026-10-01)
-- Frequency : number of orders
-- Monetary  : total spend
-- Each metric is scored 1-5 using NTILE (5 = best).
-- Recency is ordered DESC so that fewer days since last order
-- receives a higher score.
-- ---------------------------------------------------------------------
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
         NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
         NTILE(5) OVER (ORDER BY frequency)    AS f_score,
         NTILE(5) OVER (ORDER BY monetary)     AS m_score
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

-- ---------------------------------------------------------------------
-- 5. Output for Tableau
-- ---------------------------------------------------------------------
SELECT * FROM rfm_scores;
