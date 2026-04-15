-- =====================================================
-- RFM CUSTOMER SEGMENTATION PROJECT
-- Author: Belal Ahmed
-- Tools: BigQuery (SQL)
-- Description: Merge sales data, calculate RFM metrics,
--              segment customers, and prepare dashboard data
-- =====================================================


-- =====================================================
-- STEP 1: MERGE ALL MONTHLY SALES INTO ONE TABLE
-- =====================================================

CREATE OR REPLACE TABLE `gen-lang-client-0136341181.sales.sales_2025` AS

SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202501`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202502`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202503`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202504`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202505`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202506`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202507`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202508`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202509`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202510`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202511`

UNION ALL
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
FROM `gen-lang-client-0136341181.sales.sales202512`;


-- =====================================================
-- STEP 2: CALCULATE RFM METRICS & SEGMENT CUSTOMERS
-- =====================================================

CREATE OR REPLACE TABLE `gen-lang-client-0136341181.sales.rfm_final` AS

WITH rfm_base AS (
  SELECT
    CustomerID,

    -- Recency: Days since last purchase
    DATE_DIFF(
      (SELECT MAX(OrderDate) FROM `gen-lang-client-0136341181.sales.sales_2025`),
      MAX(OrderDate),
      DAY
    ) AS Recency,

    -- Frequency: Number of orders
    COUNT(OrderID) AS Frequency,

    -- Monetary: Total spending
    SUM(OrderValue) AS Monetary

  FROM `gen-lang-client-0136341181.sales.sales_2025`
  GROUP BY CustomerID
),

rfm_scores AS (
  SELECT *,
    NTILE(5) OVER (ORDER BY Recency DESC) AS R_score,
    NTILE(5) OVER (ORDER BY Frequency) AS F_score,
    NTILE(5) OVER (ORDER BY Monetary) AS M_score
  FROM rfm_base
)

SELECT *,
  CONCAT(
    CAST(R_score AS STRING),
    CAST(F_score AS STRING),
    CAST(M_score AS STRING)
  ) AS RFM_Score,

  CASE
    WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
    WHEN R_score >= 3 AND F_score >= 3 THEN 'Loyal Customers'
    WHEN R_score = 5 THEN 'New Customers'
    WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
    WHEN R_score <= 2 AND F_score <= 2 THEN 'Lost Customers'
    ELSE 'Others'
  END AS Segment

FROM rfm_scores;


-- =====================================================
-- STEP 3: PREPARE DATA FOR POWER BI DASHBOARD
-- =====================================================

CREATE OR REPLACE TABLE `gen-lang-client-0136341181.sales.rfm_dashboard` AS

SELECT 
  Segment AS rfm_segment,
  COUNT(*) AS customer_count

FROM `gen-lang-client-0136341181.sales.rfm_final`

GROUP BY Segment
ORDER BY customer_count DESC;