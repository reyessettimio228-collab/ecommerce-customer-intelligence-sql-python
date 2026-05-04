/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 10_dashboard_views.sql
Purpose: Create dashboard-ready SQL views for reporting and visualization
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script creates reusable dashboard views for business reporting.

The views are designed for tools such as:

- Power BI
- Tableau
- Streamlit
- Looker Studio

Dashboard sections supported:

- Executive overview
- Revenue trends
- Customer analytics
- Product profitability
- RFM segmentation
- Retention analysis
- Predictive modeling summary

===============================================================================
*/

-- =============================================================================
-- 1. Executive KPI overview
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_executive_kpis;

CREATE VIEW vw_dashboard_executive_kpis AS
SELECT
    ROUND(SUM(t.line_total), 2) AS total_revenue,
    COUNT(DISTINCT t.invoice_no) AS total_orders,
    COUNT(DISTINCT t.customer_id) AS total_customers,
    COUNT(DISTINCT t.stock_code) AS total_products_sold,
    SUM(t.quantity) AS total_units_sold,
    ROUND(SUM(t.line_total) / COUNT(DISTINCT t.invoice_no), 2) AS average_order_value,
    ROUND(SUM(t.line_total) / COUNT(DISTINCT t.customer_id), 2) AS revenue_per_customer,
    MIN(t.invoice_date)::DATE AS first_transaction_date,
    MAX(t.invoice_date)::DATE AS last_transaction_date
FROM vw_clean_transactions t;

-- =============================================================================
-- 2. Monthly revenue dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_monthly_revenue;

CREATE VIEW vw_dashboard_monthly_revenue AS
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::DATE AS revenue_month,
        ROUND(SUM(line_total), 2) AS revenue,
        COUNT(DISTINCT invoice_no) AS orders,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(quantity) AS units_sold,
        ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS average_order_value
    FROM vw_clean_transactions
    GROUP BY DATE_TRUNC('month', invoice_date)::DATE
)

SELECT
    revenue_month,
    revenue,
    orders,
    customers,
    units_sold,
    average_order_value,
    LAG(revenue) OVER (ORDER BY revenue_month) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY revenue_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY revenue_month), 0),
        2
    ) AS month_over_month_growth_percentage,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY revenue_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_avg_revenue
FROM monthly_revenue;

-- =============================================================================
-- 3. Country performance dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_country_performance;

CREATE VIEW vw_dashboard_country_performance AS
SELECT
    country,
    ROUND(SUM(line_total), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(quantity) AS units_sold,
    ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS average_order_value,
    ROUND(SUM(line_total) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM vw_clean_transactions
GROUP BY country;

-- =============================================================================
-- 4. Product performance dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_product_performance;

CREATE VIEW vw_dashboard_product_performance AS
SELECT
    t.stock_code AS product_id,
    t.description AS product_name,
    ROUND(SUM(t.line_total), 2) AS revenue,
    SUM(t.quantity) AS units_sold,
    COUNT(DISTINCT t.invoice_no) AS orders,
    COUNT(DISTINCT t.customer_id) AS customers,
    ROUND(AVG(t.unit_price), 2) AS average_unit_price
FROM vw_clean_transactions t
GROUP BY
    t.stock_code,
    t.description;

-- =============================================================================
-- 5. Product profitability dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_product_profitability;

CREATE VIEW vw_dashboard_product_profitability AS
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(SUM(oi.quantity * p.product_cost), 2) AS product_cost,
    ROUND(
        SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.product_cost),
        2
    ) AS gross_profit,
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
    p.product_name;

-- =============================================================================
-- 6. Customer overview dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_customer_overview;

CREATE VIEW vw_dashboard_customer_overview AS
SELECT
    c.customer_id,
    c.country,
    c.total_orders,
    c.first_order_date,
    c.last_order_date,
    DATE_PART('day', c.last_order_date - c.first_order_date) AS customer_lifetime_days,
    c.total_items_purchased,
    c.total_spent,
    ROUND(c.total_spent / NULLIF(c.total_orders, 0), 2) AS average_order_value
FROM vw_clean_customers c;

-- =============================================================================
-- 7. Customer segment dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_rfm_segments;

CREATE VIEW vw_dashboard_rfm_segments AS
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary_value), 2) AS segment_revenue,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value
FROM vw_rfm_segments
GROUP BY customer_segment;

-- =============================================================================
-- 8. CLV dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_clv_summary;

CREATE VIEW vw_dashboard_clv_summary AS
SELECT
    customer_value_tier,
    COUNT(*) AS customers,
    ROUND(SUM(historical_clv), 2) AS total_historical_clv,
    ROUND(AVG(historical_clv), 2) AS avg_historical_clv,
    ROUND(AVG(estimated_annualized_clv), 2) AS avg_estimated_annualized_clv,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer,
    ROUND(AVG(average_order_value), 2) AS avg_order_value
FROM vw_customer_lifetime_value
GROUP BY customer_value_tier;

-- =============================================================================
-- 9. Monthly new vs returning customers
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_new_vs_returning_customers;

CREATE VIEW vw_dashboard_new_vs_returning_customers AS
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase_date
    FROM vw_clean_transactions
    GROUP BY customer_id
),

monthly_customer_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoice_date)::DATE AS activity_month
    FROM vw_clean_transactions
)

SELECT
    mca.activity_month,
    COUNT(DISTINCT mca.customer_id) AS active_customers,
    COUNT(DISTINCT mca.customer_id) FILTER (
        WHERE DATE_TRUNC('month', fp.first_purchase_date)::DATE = mca.activity_month
    ) AS new_customers,
    COUNT(DISTINCT mca.customer_id) FILTER (
        WHERE DATE_TRUNC('month', fp.first_purchase_date)::DATE < mca.activity_month
    ) AS returning_customers
FROM monthly_customer_activity mca
JOIN first_purchase fp
    ON mca.customer_id = fp.customer_id
GROUP BY mca.activity_month;

-- =============================================================================
-- 10. Retention matrix dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_retention_matrix;

CREATE VIEW vw_dashboard_retention_matrix AS
WITH customer_first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date))::DATE AS cohort_month
    FROM vw_clean_transactions
    GROUP BY customer_id
),

monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoice_date)::DATE AS activity_month
    FROM vw_clean_transactions
),

cohort_activity AS (
    SELECT
        cfp.customer_id,
        cfp.cohort_month,
        ma.activity_month,
        (
            EXTRACT(YEAR FROM ma.activity_month) * 12 + EXTRACT(MONTH FROM ma.activity_month)
        ) -
        (
            EXTRACT(YEAR FROM cfp.cohort_month) * 12 + EXTRACT(MONTH FROM cfp.cohort_month)
        ) AS cohort_index
    FROM customer_first_purchase cfp
    JOIN monthly_activity ma
        ON cfp.customer_id = ma.customer_id
),

cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_id) AS retained_customers
    FROM cohort_activity
    GROUP BY
        cohort_month,
        cohort_index
),

cohort_sizes AS (
    SELECT
        cohort_month,
        retained_customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
),

retention_rates AS (
    SELECT
        cc.cohort_month,
        cc.cohort_index,
        ROUND(
            100.0 * cc.retained_customers / NULLIF(cs.cohort_size, 0),
            2
        ) AS retention_rate_percentage
    FROM cohort_counts cc
    JOIN cohort_sizes cs
        ON cc.cohort_month = cs.cohort_month
)

SELECT
    cohort_month,
    MAX(CASE WHEN cohort_index = 0 THEN retention_rate_percentage END) AS month_0,
    MAX(CASE WHEN cohort_index = 1 THEN retention_rate_percentage END) AS month_1,
    MAX(CASE WHEN cohort_index = 2 THEN retention_rate_percentage END) AS month_2,
    MAX(CASE WHEN cohort_index = 3 THEN retention_rate_percentage END) AS month_3,
    MAX(CASE WHEN cohort_index = 4 THEN retention_rate_percentage END) AS month_4,
    MAX(CASE WHEN cohort_index = 5 THEN retention_rate_percentage END) AS month_5,
    MAX(CASE WHEN cohort_index = 6 THEN retention_rate_percentage END) AS month_6
FROM retention_rates
GROUP BY cohort_month;

-- =============================================================================
-- 11. Prediction model dashboard summary
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_prediction_summary;

CREATE VIEW vw_dashboard_prediction_summary AS
SELECT
    repurchased_90_days,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,
    ROUND(AVG(total_orders_before_snapshot), 2) AS avg_orders_before_snapshot,
    ROUND(AVG(total_spent_before_snapshot), 2) AS avg_spent_before_snapshot,
    ROUND(AVG(avg_order_value_before_snapshot), 2) AS avg_order_value_before_snapshot,
    ROUND(AVG(customer_age_days), 2) AS avg_customer_age_days,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(unique_products_purchased), 2) AS avg_unique_products_purchased
FROM vw_customer_model_features
GROUP BY repurchased_90_days;

-- =============================================================================
-- 12. Prediction segment dashboard view
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_prediction_by_segment;

CREATE VIEW vw_dashboard_prediction_by_segment AS
SELECT
    customer_segment,
    repurchased_90_days,
    COUNT(*) AS customers,
    ROUND(AVG(total_spent_before_snapshot), 2) AS avg_spent_before_snapshot,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(total_orders_before_snapshot), 2) AS avg_orders_before_snapshot
FROM vw_customer_model_features
GROUP BY
    customer_segment,
    repurchased_90_days;

-- =============================================================================
-- 13. Dashboard data quality summary
-- =============================================================================

DROP VIEW IF EXISTS vw_dashboard_data_quality;

CREATE VIEW vw_dashboard_data_quality AS
SELECT
    *
FROM vw_data_quality_summary;

/*
===============================================================================
End of file: 10_dashboard_views.sql
===============================================================================
*/
