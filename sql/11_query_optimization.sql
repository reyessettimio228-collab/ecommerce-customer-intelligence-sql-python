/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 11_query_optimization.sql
Purpose: Document query optimization techniques for analytical SQL workloads
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script documents basic query optimization techniques used in this project.

The goal is not to perform advanced database administration, but to demonstrate
awareness of performance considerations in analytical SQL workflows.

Optimization topics covered:

- indexes for join keys;
- indexes for date filters;
- indexes for customer and product analysis;
- EXPLAIN and EXPLAIN ANALYZE;
- materialized views for dashboard workloads;
- query design best practices.

===============================================================================
*/

-- =============================================================================
-- 1. Indexes for raw source table
-- =============================================================================
-- These indexes help speed up data quality checks and transformations from the
-- raw table into the relational model.

CREATE INDEX IF NOT EXISTS idx_raw_online_retail_invoice_no
    ON raw_online_retail(invoice_no);

CREATE INDEX IF NOT EXISTS idx_raw_online_retail_customer_id
    ON raw_online_retail(customer_id);

CREATE INDEX IF NOT EXISTS idx_raw_online_retail_stock_code
    ON raw_online_retail(stock_code);

CREATE INDEX IF NOT EXISTS idx_raw_online_retail_invoice_date
    ON raw_online_retail(invoice_date);

CREATE INDEX IF NOT EXISTS idx_raw_online_retail_country
    ON raw_online_retail(country);

-- =============================================================================
-- 2. Indexes for relational tables
-- =============================================================================
-- These indexes support joins and analytical queries.

CREATE INDEX IF NOT EXISTS idx_orders_customer_id_optimization
    ON orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_date_optimization
    ON orders(order_date);

CREATE INDEX IF NOT EXISTS idx_orders_status_optimization
    ON orders(order_status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id_optimization
    ON order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id_optimization
    ON order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_payments_order_id_optimization
    ON payments(order_id);

CREATE INDEX IF NOT EXISTS idx_payments_status_optimization
    ON payments(payment_status);

CREATE INDEX IF NOT EXISTS idx_shipments_order_id_optimization
    ON shipments(order_id);

CREATE INDEX IF NOT EXISTS idx_shipments_status_optimization
    ON shipments(delivery_status);

-- =============================================================================
-- 3. Composite indexes for common analytical patterns
-- =============================================================================

-- Useful for customer purchase history queries
CREATE INDEX IF NOT EXISTS idx_orders_customer_date
    ON orders(customer_id, order_date);

-- Useful for product-level revenue and profitability queries
CREATE INDEX IF NOT EXISTS idx_order_items_product_order
    ON order_items(product_id, order_id);

-- Useful for filtering completed orders over time
CREATE INDEX IF NOT EXISTS idx_orders_status_date
    ON orders(order_status, order_date);

-- =============================================================================
-- 4. Example: EXPLAIN for revenue query
-- =============================================================================
-- EXPLAIN shows the query execution plan.
-- It helps understand whether PostgreSQL is using indexes, sequential scans,
-- joins, aggregations, and sorting operations.

EXPLAIN
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS revenue_month,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date)::DATE
ORDER BY revenue_month;

-- =============================================================================
-- 5. Example: EXPLAIN ANALYZE for customer query
-- =============================================================================
-- EXPLAIN ANALYZE actually runs the query and returns execution time.
-- Use it carefully on very large datasets.

EXPLAIN ANALYZE
SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_spent
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.customer_id
ORDER BY total_spent DESC
LIMIT 50;

-- =============================================================================
-- 6. Materialized view for monthly revenue
-- =============================================================================
-- Materialized views physically store query results.
-- They are useful for dashboard queries that do not need real-time updates.

DROP MATERIALIZED VIEW IF EXISTS mv_monthly_revenue;

CREATE MATERIALIZED VIEW mv_monthly_revenue AS
SELECT
    DATE_TRUNC('month', invoice_date)::DATE AS revenue_month,
    ROUND(SUM(line_total), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(quantity) AS units_sold,
    ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS average_order_value
FROM vw_clean_transactions
GROUP BY DATE_TRUNC('month', invoice_date)::DATE
ORDER BY revenue_month;

CREATE INDEX IF NOT EXISTS idx_mv_monthly_revenue_month
    ON mv_monthly_revenue(revenue_month);

-- Refresh command:
-- REFRESH MATERIALIZED VIEW mv_monthly_revenue;

-- =============================================================================
-- 7. Materialized view for customer metrics
-- =============================================================================

DROP MATERIALIZED VIEW IF EXISTS mv_customer_metrics;

CREATE MATERIALIZED VIEW mv_customer_metrics AS
SELECT
    customer_id,
    country,
    total_orders,
    first_order_date,
    last_order_date,
    DATE_PART('day', last_order_date - first_order_date) AS customer_lifetime_days,
    total_items_purchased,
    total_spent,
    ROUND(total_spent / NULLIF(total_orders, 0), 2) AS average_order_value
FROM vw_clean_customers;

CREATE INDEX IF NOT EXISTS idx_mv_customer_metrics_customer_id
    ON mv_customer_metrics(customer_id);

CREATE INDEX IF NOT EXISTS idx_mv_customer_metrics_total_spent
    ON mv_customer_metrics(total_spent);

-- Refresh command:
-- REFRESH MATERIALIZED VIEW mv_customer_metrics;

-- =============================================================================
-- 8. Materialized view for RFM segments
-- =============================================================================

DROP MATERIALIZED VIEW IF EXISTS mv_rfm_segments;

CREATE MATERIALIZED VIEW mv_rfm_segments AS
SELECT
    *
FROM vw_rfm_segments;

CREATE INDEX IF NOT EXISTS idx_mv_rfm_segments_customer_id
    ON mv_rfm_segments(customer_id);

CREATE INDEX IF NOT EXISTS idx_mv_rfm_segments_segment
    ON mv_rfm_segments(customer_segment);

CREATE INDEX IF NOT EXISTS idx_mv_rfm_segments_monetary
    ON mv_rfm_segments(monetary_value);

-- Refresh command:
-- REFRESH MATERIALIZED VIEW mv_rfm_segments;

-- =============================================================================
-- 9. Materialized view for dashboard product profitability
-- =============================================================================

DROP MATERIALIZED VIEW IF EXISTS mv_product_profitability;

CREATE MATERIALIZED VIEW mv_product_profitability AS
SELECT
    *
FROM vw_dashboard_product_profitability;

CREATE INDEX IF NOT EXISTS idx_mv_product_profitability_product_id
    ON mv_product_profitability(product_id);

CREATE INDEX IF NOT EXISTS idx_mv_product_profitability_revenue
    ON mv_product_profitability(revenue);

CREATE INDEX IF NOT EXISTS idx_mv_product_profitability_gross_profit
    ON mv_product_profitability(gross_profit);

-- Refresh command:
-- REFRESH MATERIALIZED VIEW mv_product_profitability;

-- =============================================================================
-- 10. Query optimization best practices used in this project
-- =============================================================================

/*
Best practices:

1. Filter early
   Apply WHERE conditions before aggregation whenever possible.

2. Use clean views
   Reuse vw_clean_transactions instead of repeating cleaning conditions in every
   query.

3. Index join keys
   Foreign keys and frequently joined columns should be indexed.

4. Index date columns
   Date columns are frequently used for monthly trends, cohort analysis, and
   time-based filtering.

5. Avoid SELECT * in production queries
   Select only the columns needed for dashboards or reports.

6. Use materialized views for dashboard workloads
   Expensive aggregations can be precomputed and refreshed when needed.

7. Check query plans
   Use EXPLAIN and EXPLAIN ANALYZE to understand performance bottlenecks.

8. Use NULLIF in division
   Prevent division-by-zero errors in KPI calculations.

9. Use CTEs for readability
   CTEs make complex analytical logic easier to understand and maintain.

10. Validate outputs
    Every transformation should be followed by validation checks.
*/

-- =============================================================================
-- 11. Example optimized dashboard query using materialized view
-- =============================================================================

SELECT
    revenue_month,
    revenue,
    orders,
    customers,
    units_sold,
    average_order_value
FROM mv_monthly_revenue
ORDER BY revenue_month;

-- =============================================================================
-- 12. Example optimized RFM dashboard query
-- =============================================================================

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary_value), 2) AS segment_revenue,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value
FROM mv_rfm_segments
GROUP BY customer_segment
ORDER BY segment_revenue DESC;

-- =============================================================================
-- 13. Refresh all materialized views
-- =============================================================================
-- Run these commands after updating the underlying data.

-- REFRESH MATERIALIZED VIEW mv_monthly_revenue;
-- REFRESH MATERIALIZED VIEW mv_customer_metrics;
-- REFRESH MATERIALIZED VIEW mv_rfm_segments;
-- REFRESH MATERIALIZED VIEW mv_product_profitability;

/*
===============================================================================
End of file: 11_query_optimization.sql
===============================================================================
*/
