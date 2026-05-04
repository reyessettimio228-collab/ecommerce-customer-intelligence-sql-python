/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 03_revenue_analysis.sql
Purpose: Analyze revenue performance using clean transaction data
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script analyzes revenue performance using the clean analytical views created
in 02_data_cleaning.sql.

Main topics covered:

- total revenue;
- total orders;
- average order value;
- monthly revenue trend;
- month-over-month revenue growth;
- revenue by country;
- revenue by product;
- revenue concentration;
- best and worst performing months.

===============================================================================
*/

-- =============================================================================
-- 1. Executive revenue overview
-- =============================================================================

SELECT
    ROUND(SUM(line_total), 2) AS total_revenue,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS average_order_value,
    ROUND(SUM(line_total) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM vw_clean_transactions;

-- =============================================================================
-- 2. Revenue by year and month
-- =============================================================================

SELECT
    DATE_TRUNC('month', invoice_date)::DATE AS revenue_month,
    ROUND(SUM(line_total), 2) AS monthly_revenue,
    COUNT(DISTINCT invoice_no) AS monthly_orders,
    COUNT(DISTINCT customer_id) AS monthly_customers,
    SUM(quantity) AS monthly_units_sold,
    ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS monthly_average_order_value
FROM vw_clean_transactions
GROUP BY DATE_TRUNC('month', invoice_date)::DATE
ORDER BY revenue_month;

-- =============================================================================
-- 3. Month-over-month revenue growth
-- =============================================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::DATE AS revenue_month,
        ROUND(SUM(line_total), 2) AS revenue
    FROM vw_clean_transactions
    GROUP BY DATE_TRUNC('month', invoice_date)::DATE
)

SELECT
    revenue_month,
    revenue,
    LAG(revenue) OVER (ORDER BY revenue_month) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY revenue_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY revenue_month), 0),
        2
    ) AS month_over_month_growth_percentage
FROM monthly_revenue
ORDER BY revenue_month;

-- =============================================================================
-- 4. Rolling 3-month revenue average
-- =============================================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::DATE AS revenue_month,
        ROUND(SUM(line_total), 2) AS revenue
    FROM vw_clean_transactions
    GROUP BY DATE_TRUNC('month', invoice_date)::DATE
)

SELECT
    revenue_month,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY revenue_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_avg_revenue
FROM monthly_revenue
ORDER BY revenue_month;

-- =============================================================================
-- 5. Best and worst revenue months
-- =============================================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::DATE AS revenue_month,
        ROUND(SUM(line_total), 2) AS revenue,
        COUNT(DISTINCT invoice_no) AS orders,
        COUNT(DISTINCT customer_id) AS customers
    FROM vw_clean_transactions
    GROUP BY DATE_TRUNC('month', invoice_date)::DATE
),

ranked_months AS (
    SELECT
        revenue_month,
        revenue,
        orders,
        customers,
        RANK() OVER (ORDER BY revenue DESC) AS best_month_rank,
        RANK() OVER (ORDER BY revenue ASC) AS worst_month_rank
    FROM monthly_revenue
)

SELECT
    revenue_month,
    revenue,
    orders,
    customers,
    best_month_rank,
    worst_month_rank
FROM ranked_months
WHERE best_month_rank <= 3
   OR worst_month_rank <= 3
ORDER BY revenue DESC;

-- =============================================================================
-- 6. Revenue by country
-- =============================================================================

SELECT
    country,
    ROUND(SUM(line_total), 2) AS total_revenue,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS average_order_value
FROM vw_clean_transactions
GROUP BY country
ORDER BY total_revenue DESC;

-- =============================================================================
-- 7. Revenue contribution by country
-- =============================================================================

WITH country_revenue AS (
    SELECT
        country,
        ROUND(SUM(line_total), 2) AS revenue
    FROM vw_clean_transactions
    GROUP BY country
),

total_revenue AS (
    SELECT
        SUM(revenue) AS total_revenue
    FROM country_revenue
)

SELECT
    cr.country,
    cr.revenue,
    ROUND(100.0 * cr.revenue / tr.total_revenue, 2) AS revenue_share_percentage
FROM country_revenue cr
CROSS JOIN total_revenue tr
ORDER BY cr.revenue DESC;

-- =============================================================================
-- 8. Revenue by product
-- =============================================================================

SELECT
    stock_code AS product_id,
    description AS product_name,
    ROUND(SUM(line_total), 2) AS total_revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(AVG(unit_price), 2) AS average_unit_price
FROM vw_clean_transactions
GROUP BY
    stock_code,
    description
ORDER BY total_revenue DESC
LIMIT 50;

-- =============================================================================
-- 9. Top products by revenue contribution
-- =============================================================================

WITH product_revenue AS (
    SELECT
        stock_code AS product_id,
        description AS product_name,
        ROUND(SUM(line_total), 2) AS revenue
    FROM vw_clean_transactions
    GROUP BY
        stock_code,
        description
),

total_revenue AS (
    SELECT
        SUM(revenue) AS total_revenue
    FROM product_revenue
),

ranked_products AS (
    SELECT
        pr.product_id,
        pr.product_name,
        pr.revenue,
        ROUND(100.0 * pr.revenue / tr.total_revenue, 2) AS revenue_share_percentage,
        RANK() OVER (ORDER BY pr.revenue DESC) AS revenue_rank
    FROM product_revenue pr
    CROSS JOIN total_revenue tr
)

SELECT
    product_id,
    product_name,
    revenue,
    revenue_share_percentage,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 20
ORDER BY revenue_rank;

-- =============================================================================
-- 10. Revenue concentration: top customers
-- =============================================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        country,
        ROUND(SUM(line_total), 2) AS revenue
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        country
),

total_revenue AS (
    SELECT
        SUM(revenue) AS total_revenue
    FROM customer_revenue
),

ranked_customers AS (
    SELECT
        cr.customer_id,
        cr.country,
        cr.revenue,
        ROUND(100.0 * cr.revenue / tr.total_revenue, 2) AS revenue_share_percentage,
        RANK() OVER (ORDER BY cr.revenue DESC) AS customer_revenue_rank
    FROM customer_revenue cr
    CROSS JOIN total_revenue tr
)

SELECT
    customer_id,
    country,
    revenue,
    revenue_share_percentage,
    customer_revenue_rank
FROM ranked_customers
WHERE customer_revenue_rank <= 20
ORDER BY customer_revenue_rank;

-- =============================================================================
-- 11. Revenue concentration: top 10% customers
-- =============================================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        ROUND(SUM(line_total), 2) AS revenue
    FROM vw_clean_transactions
    GROUP BY customer_id
),

customer_percentiles AS (
    SELECT
        customer_id,
        revenue,
        NTILE(10) OVER (ORDER BY revenue DESC) AS revenue_decile
    FROM customer_revenue
),

total_revenue AS (
    SELECT
        SUM(revenue) AS total_revenue
    FROM customer_revenue
)

SELECT
    revenue_decile,
    COUNT(*) AS customers_in_decile,
    ROUND(SUM(revenue), 2) AS decile_revenue,
    ROUND(100.0 * SUM(revenue) / MAX(total_revenue), 2) AS revenue_share_percentage
FROM customer_percentiles
CROSS JOIN total_revenue
GROUP BY revenue_decile
ORDER BY revenue_decile;

-- =============================================================================
-- 12. Average order value by month
-- =============================================================================

SELECT
    DATE_TRUNC('month', order_date)::DATE AS order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_revenue), 2) AS monthly_revenue,
    ROUND(AVG(order_revenue), 2) AS average_order_value,
    MIN(order_revenue) AS min_order_value,
    MAX(order_revenue) AS max_order_value
FROM vw_clean_orders
GROUP BY DATE_TRUNC('month', order_date)::DATE
ORDER BY order_month;

-- =============================================================================
-- 13. Revenue by weekday
-- =============================================================================

SELECT
    TO_CHAR(invoice_date, 'Day') AS weekday_name,
    EXTRACT(DOW FROM invoice_date) AS weekday_number,
    ROUND(SUM(line_total), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS average_order_value
FROM vw_clean_transactions
GROUP BY
    TO_CHAR(invoice_date, 'Day'),
    EXTRACT(DOW FROM invoice_date)
ORDER BY weekday_number;

-- =============================================================================
-- 14. Revenue by hour of day
-- =============================================================================

SELECT
    EXTRACT(HOUR FROM invoice_date) AS hour_of_day,
    ROUND(SUM(line_total), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers
FROM vw_clean_transactions
GROUP BY EXTRACT(HOUR FROM invoice_date)
ORDER BY hour_of_day;

-- =============================================================================
-- 15. Revenue summary for reporting
-- =============================================================================

WITH revenue_summary AS (
    SELECT
        ROUND(SUM(line_total), 2) AS total_revenue,
        COUNT(DISTINCT invoice_no) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customers,
        SUM(quantity) AS total_units_sold,
        ROUND(SUM(line_total) / COUNT(DISTINCT invoice_no), 2) AS average_order_value,
        ROUND(SUM(line_total) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
    FROM vw_clean_transactions
),

date_summary AS (
    SELECT
        MIN(invoice_date)::DATE AS first_transaction_date,
        MAX(invoice_date)::DATE AS last_transaction_date
    FROM vw_clean_transactions
)

SELECT
    rs.total_revenue,
    rs.total_orders,
    rs.total_customers,
    rs.total_units_sold,
    rs.average_order_value,
    rs.revenue_per_customer,
    ds.first_transaction_date,
    ds.last_transaction_date
FROM revenue_summary rs
CROSS JOIN date_summary ds;

/*
===============================================================================
End of file: 03_revenue_analysis.sql
===============================================================================
*/
