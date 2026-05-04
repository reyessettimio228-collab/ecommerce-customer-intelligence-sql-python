/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 05_product_profitability_analysis.sql
Purpose: Analyze product revenue, cost, profit, and margin performance
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script analyzes product profitability using the relational tables created
from the original Online Retail dataset.

The original dataset contains product prices but does not contain product costs.
For this reason, product_cost was simulated in the products table.

Main topics covered:

- product revenue;
- product cost;
- gross profit;
- profit margin;
- top products by revenue;
- top products by profit;
- low-margin products;
- high-volume low-profit products;
- country-level product profitability;
- profitability distribution.

===============================================================================
*/

-- =============================================================================
-- 1. Product profitability overview
-- =============================================================================

SELECT
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * p.product_cost), 2) AS total_product_cost,
    ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
    ROUND(
        100.0 * (
            SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
        ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS gross_margin_percentage
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
  AND oi.unit_price > 0;

-- =============================================================================
-- 2. Product-level profitability
-- =============================================================================

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(SUM(oi.quantity * p.product_cost), 2) AS product_cost,
    ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
    ROUND(
        100.0 * (
            SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
        ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS gross_margin_percentage
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
  AND oi.unit_price > 0
GROUP BY
    p.product_id,
    p.product_name
ORDER BY gross_profit DESC;

-- =============================================================================
-- 3. Top 25 products by revenue
-- =============================================================================

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(SUM(oi.quantity * p.product_cost), 2) AS product_cost,
    ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
    ROUND(
        100.0 * (
            SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
        ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS gross_margin_percentage
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
  AND oi.unit_price > 0
GROUP BY
    p.product_id,
    p.product_name
ORDER BY revenue DESC
LIMIT 25;

-- =============================================================================
-- 4. Top 25 products by gross profit
-- =============================================================================

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(SUM(oi.quantity * p.product_cost), 2) AS product_cost,
    ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
    ROUND(
        100.0 * (
            SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
        ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS gross_margin_percentage
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
  AND oi.unit_price > 0
GROUP BY
    p.product_id,
    p.product_name
ORDER BY gross_profit DESC
LIMIT 25;

-- =============================================================================
-- 5. Low-margin products
-- =============================================================================

WITH product_profitability AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
        ROUND(SUM(oi.quantity * p.product_cost), 2) AS product_cost,
        ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
        ROUND(
            100.0 * (
                SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
            ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
            2
        ) AS gross_margin_percentage
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
      AND oi.quantity > 0
      AND oi.unit_price > 0
    GROUP BY
        p.product_id,
        p.product_name
)

SELECT
    *
FROM product_profitability
WHERE revenue > 0
ORDER BY gross_margin_percentage ASC
LIMIT 25;

-- =============================================================================
-- 6. High-volume, low-profit products
-- =============================================================================

WITH product_profitability AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
        ROUND(SUM(oi.quantity * p.product_cost), 2) AS product_cost,
        ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
        ROUND(
            100.0 * (
                SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
            ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
            2
        ) AS gross_margin_percentage
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
      AND oi.quantity > 0
      AND oi.unit_price > 0
    GROUP BY
        p.product_id,
        p.product_name
),

ranked_products AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY units_sold DESC) AS volume_quartile,
        NTILE(4) OVER (ORDER BY gross_profit ASC) AS profit_quartile
    FROM product_profitability
)

SELECT
    product_id,
    product_name,
    units_sold,
    revenue,
    gross_profit,
    gross_margin_percentage,
    volume_quartile,
    profit_quartile
FROM ranked_products
WHERE volume_quartile = 1
  AND profit_quartile IN (1, 2)
ORDER BY units_sold DESC;

-- =============================================================================
-- 7. Profitability by country
-- =============================================================================

SELECT
    o.country,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(SUM(oi.quantity * p.product_cost), 2) AS product_cost,
    ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
    ROUND(
        100.0 * (
            SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
        ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS gross_margin_percentage,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
  AND oi.unit_price > 0
GROUP BY o.country
ORDER BY gross_profit DESC;

-- =============================================================================
-- 8. Profit contribution by product
-- =============================================================================

WITH product_profit AS (
    SELECT
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
      AND oi.quantity > 0
      AND oi.unit_price > 0
    GROUP BY
        p.product_id,
        p.product_name
),

total_profit AS (
    SELECT
        SUM(gross_profit) AS total_gross_profit
    FROM product_profit
)

SELECT
    pp.product_id,
    pp.product_name,
    pp.gross_profit,
    ROUND(100.0 * pp.gross_profit / NULLIF(tp.total_gross_profit, 0), 2) AS profit_share_percentage,
    RANK() OVER (ORDER BY pp.gross_profit DESC) AS profit_rank
FROM product_profit pp
CROSS JOIN total_profit tp
ORDER BY profit_rank
LIMIT 50;

-- =============================================================================
-- 9. Revenue rank vs profit rank
-- =============================================================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
        ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
      AND oi.quantity > 0
      AND oi.unit_price > 0
    GROUP BY
        p.product_id,
        p.product_name
),

ranked_metrics AS (
    SELECT
        product_id,
        product_name,
        revenue,
        gross_profit,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY gross_profit DESC) AS profit_rank
    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    revenue,
    gross_profit,
    revenue_rank,
    profit_rank,
    revenue_rank - profit_rank AS rank_difference
FROM ranked_metrics
ORDER BY ABS(revenue_rank - profit_rank) DESC
LIMIT 50;

-- =============================================================================
-- 10. Profitability summary by margin bucket
-- =============================================================================

WITH product_profitability AS (
    SELECT
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
        ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
        ROUND(
            100.0 * (
                SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost)
            ) / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
            2
        ) AS gross_margin_percentage
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
      AND oi.quantity > 0
      AND oi.unit_price > 0
    GROUP BY
        p.product_id,
        p.product_name
)

SELECT
    CASE
        WHEN gross_margin_percentage < 10 THEN '< 10%'
        WHEN gross_margin_percentage BETWEEN 10 AND 19.99 THEN '10-20%'
        WHEN gross_margin_percentage BETWEEN 20 AND 29.99 THEN '20-30%'
        WHEN gross_margin_percentage BETWEEN 30 AND 39.99 THEN '30-40%'
        WHEN gross_margin_percentage BETWEEN 40 AND 49.99 THEN '40-50%'
        ELSE '50%+'
    END AS margin_bucket,
    COUNT(*) AS number_of_products,
    ROUND(SUM(revenue), 2) AS bucket_revenue,
    ROUND(SUM(gross_profit), 2) AS bucket_gross_profit
FROM product_profitability
GROUP BY margin_bucket
ORDER BY
    CASE
        WHEN margin_bucket = '< 10%' THEN 1
        WHEN margin_bucket = '10-20%' THEN 2
        WHEN margin_bucket = '20-30%' THEN 3
        WHEN margin_bucket = '30-40%' THEN 4
        WHEN margin_bucket = '40-50%' THEN 5
        ELSE 6
    END;

-- =============================================================================
-- 11. Profitability summary for reporting
-- =============================================================================

WITH profitability_summary AS (
    SELECT
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
        ROUND(SUM(oi.quantity * p.product_cost), 2) AS total_product_cost,
        ROUND(SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost), 2) AS gross_profit,
        COUNT(DISTINCT p.product_id) AS products_sold,
        COUNT(DISTINCT o.order_id) AS completed_orders
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
      AND oi.quantity > 0
      AND oi.unit_price > 0
)

SELECT
    total_revenue,
    total_product_cost,
    gross_profit,
    ROUND(100.0 * gross_profit / NULLIF(total_revenue, 0), 2) AS gross_margin_percentage,
    products_sold,
    completed_orders,
    ROUND(gross_profit / NULLIF(completed_orders, 0), 2) AS gross_profit_per_order
FROM profitability_summary;

/*
===============================================================================
End of file: 05_product_profitability_analysis.sql
===============================================================================
*/
