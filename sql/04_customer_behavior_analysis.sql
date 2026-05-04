/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 04_customer_behavior_analysis.sql
Purpose: Analyze customer behavior and purchasing patterns
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script analyzes customer behavior using clean transaction and order views.

Main topics covered:

- total customers;
- new customers by month;
- returning customers;
- repeat purchase rate;
- customer purchase frequency;
- customer spending distribution;
- top customers by revenue;
- customer activity lifecycle;
- days between purchases;
- customer country distribution.

===============================================================================
*/

-- =============================================================================
-- 1. Customer overview
-- =============================================================================

SELECT
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT invoice_no) AS total_orders,
    ROUND(COUNT(DISTINCT invoice_no)::NUMERIC / COUNT(DISTINCT customer_id), 2) AS avg_orders_per_customer,
    ROUND(SUM(line_total) / COUNT(DISTINCT customer_id), 2) AS avg_revenue_per_customer,
    ROUND(SUM(quantity)::NUMERIC / COUNT(DISTINCT customer_id), 2) AS avg_units_per_customer
FROM vw_clean_transactions;

-- =============================================================================
-- 2. Customer purchase frequency
-- =============================================================================

SELECT
    total_orders,
    COUNT(*) AS number_of_customers
FROM vw_clean_customers
GROUP BY total_orders
ORDER BY total_orders;

-- =============================================================================
-- 3. Customer purchase frequency buckets
-- =============================================================================

WITH customer_frequency AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders
    FROM vw_clean_transactions
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_orders = 1 THEN '1 order'
        WHEN total_orders BETWEEN 2 AND 3 THEN '2-3 orders'
        WHEN total_orders BETWEEN 4 AND 5 THEN '4-5 orders'
        WHEN total_orders BETWEEN 6 AND 10 THEN '6-10 orders'
        ELSE '10+ orders'
    END AS purchase_frequency_bucket,
    COUNT(*) AS number_of_customers
FROM customer_frequency
GROUP BY purchase_frequency_bucket
ORDER BY
    CASE
        WHEN purchase_frequency_bucket = '1 order' THEN 1
        WHEN purchase_frequency_bucket = '2-3 orders' THEN 2
        WHEN purchase_frequency_bucket = '4-5 orders' THEN 3
        WHEN purchase_frequency_bucket = '6-10 orders' THEN 4
        ELSE 5
    END;

-- =============================================================================
-- 4. Repeat purchase rate
-- =============================================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders
    FROM vw_clean_transactions
    GROUP BY customer_id
)

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
    COUNT(*) FILTER (WHERE total_orders = 1) AS one_time_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / COUNT(*),
        2
    ) AS repeat_purchase_rate_percentage
FROM customer_orders;

-- =============================================================================
-- 5. New customers by month
-- =============================================================================

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase_date
    FROM vw_clean_transactions
    GROUP BY customer_id
)

SELECT
    DATE_TRUNC('month', first_purchase_date)::DATE AS first_purchase_month,
    COUNT(*) AS new_customers
FROM first_purchase
GROUP BY DATE_TRUNC('month', first_purchase_date)::DATE
ORDER BY first_purchase_month;

-- =============================================================================
-- 6. New vs returning customers by month
-- =============================================================================

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
GROUP BY mca.activity_month
ORDER BY mca.activity_month;

-- =============================================================================
-- 7. Monthly revenue from new vs returning customers
-- =============================================================================

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase_date
    FROM vw_clean_transactions
    GROUP BY customer_id
),

classified_transactions AS (
    SELECT
        t.customer_id,
        DATE_TRUNC('month', t.invoice_date)::DATE AS transaction_month,
        t.line_total,
        CASE
            WHEN DATE_TRUNC('month', fp.first_purchase_date)::DATE =
                 DATE_TRUNC('month', t.invoice_date)::DATE
                THEN 'New Customer'
            ELSE 'Returning Customer'
        END AS customer_type
    FROM vw_clean_transactions t
    JOIN first_purchase fp
        ON t.customer_id = fp.customer_id
)

SELECT
    transaction_month,
    customer_type,
    ROUND(SUM(line_total), 2) AS revenue,
    COUNT(DISTINCT customer_id) AS customers
FROM classified_transactions
GROUP BY
    transaction_month,
    customer_type
ORDER BY
    transaction_month,
    customer_type;

-- =============================================================================
-- 8. Top customers by revenue
-- =============================================================================

SELECT
    customer_id,
    country,
    total_orders,
    first_order_date,
    last_order_date,
    total_items_purchased,
    total_spent,
    ROUND(total_spent / total_orders, 2) AS avg_order_value
FROM vw_clean_customers
ORDER BY total_spent DESC
LIMIT 25;

-- =============================================================================
-- 9. Customer spending buckets
-- =============================================================================

WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(line_total) AS total_spent
    FROM vw_clean_transactions
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_spent < 100 THEN '< 100'
        WHEN total_spent BETWEEN 100 AND 499.99 THEN '100-499'
        WHEN total_spent BETWEEN 500 AND 999.99 THEN '500-999'
        WHEN total_spent BETWEEN 1000 AND 4999.99 THEN '1,000-4,999'
        WHEN total_spent BETWEEN 5000 AND 9999.99 THEN '5,000-9,999'
        ELSE '10,000+'
    END AS spending_bucket,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(total_spent), 2) AS bucket_revenue
FROM customer_spending
GROUP BY spending_bucket
ORDER BY
    CASE
        WHEN spending_bucket = '< 100' THEN 1
        WHEN spending_bucket = '100-499' THEN 2
        WHEN spending_bucket = '500-999' THEN 3
        WHEN spending_bucket = '1,000-4,999' THEN 4
        WHEN spending_bucket = '5,000-9,999' THEN 5
        ELSE 6
    END;

-- =============================================================================
-- 10. Customer lifetime duration
-- =============================================================================

SELECT
    customer_id,
    country,
    first_order_date,
    last_order_date,
    DATE_PART('day', last_order_date - first_order_date) AS customer_lifetime_days,
    total_orders,
    total_spent
FROM vw_clean_customers
ORDER BY customer_lifetime_days DESC
LIMIT 50;

-- =============================================================================
-- 11. Customer lifecycle buckets
-- =============================================================================

WITH customer_lifecycle AS (
    SELECT
        customer_id,
        DATE_PART('day', last_order_date - first_order_date) AS lifetime_days
    FROM vw_clean_customers
)

SELECT
    CASE
        WHEN lifetime_days = 0 THEN 'Same-day only'
        WHEN lifetime_days BETWEEN 1 AND 30 THEN '1-30 days'
        WHEN lifetime_days BETWEEN 31 AND 90 THEN '31-90 days'
        WHEN lifetime_days BETWEEN 91 AND 180 THEN '91-180 days'
        WHEN lifetime_days BETWEEN 181 AND 365 THEN '181-365 days'
        ELSE '365+ days'
    END AS customer_lifetime_bucket,
    COUNT(*) AS number_of_customers
FROM customer_lifecycle
GROUP BY customer_lifetime_bucket
ORDER BY
    CASE
        WHEN customer_lifetime_bucket = 'Same-day only' THEN 1
        WHEN customer_lifetime_bucket = '1-30 days' THEN 2
        WHEN customer_lifetime_bucket = '31-90 days' THEN 3
        WHEN customer_lifetime_bucket = '91-180 days' THEN 4
        WHEN customer_lifetime_bucket = '181-365 days' THEN 5
        ELSE 6
    END;

-- =============================================================================
-- 12. Days between customer purchases
-- =============================================================================

WITH customer_orders AS (
    SELECT DISTINCT
        customer_id,
        invoice_no,
        MIN(invoice_date) AS order_date
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        invoice_no
),

ordered_purchases AS (
    SELECT
        customer_id,
        invoice_no,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM customer_orders
)

SELECT
    customer_id,
    invoice_no,
    order_date,
    previous_order_date,
    DATE_PART('day', order_date - previous_order_date) AS days_since_previous_order
FROM ordered_purchases
WHERE previous_order_date IS NOT NULL
ORDER BY
    customer_id,
    order_date;

-- =============================================================================
-- 13. Average days between purchases by customer
-- =============================================================================

WITH customer_orders AS (
    SELECT DISTINCT
        customer_id,
        invoice_no,
        MIN(invoice_date) AS order_date
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        invoice_no
),

ordered_purchases AS (
    SELECT
        customer_id,
        invoice_no,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM customer_orders
),

purchase_intervals AS (
    SELECT
        customer_id,
        DATE_PART('day', order_date - previous_order_date) AS days_since_previous_order
    FROM ordered_purchases
    WHERE previous_order_date IS NOT NULL
)

SELECT
    customer_id,
    COUNT(*) AS repeat_purchase_intervals,
    ROUND(AVG(days_since_previous_order), 2) AS avg_days_between_purchases,
    MIN(days_since_previous_order) AS min_days_between_purchases,
    MAX(days_since_previous_order) AS max_days_between_purchases
FROM purchase_intervals
GROUP BY customer_id
ORDER BY avg_days_between_purchases;

-- =============================================================================
-- 14. Customer distribution by country
-- =============================================================================

SELECT
    country,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT invoice_no) AS total_orders,
    ROUND(SUM(line_total), 2) AS total_revenue,
    ROUND(SUM(line_total) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM vw_clean_transactions
GROUP BY country
ORDER BY unique_customers DESC;

-- =============================================================================
-- 15. Customer ranking within each country
-- =============================================================================

WITH customer_country_revenue AS (
    SELECT
        customer_id,
        country,
        ROUND(SUM(line_total), 2) AS customer_revenue,
        COUNT(DISTINCT invoice_no) AS total_orders
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        country
),

ranked_customers AS (
    SELECT
        customer_id,
        country,
        customer_revenue,
        total_orders,
        RANK() OVER (
            PARTITION BY country
            ORDER BY customer_revenue DESC
        ) AS country_revenue_rank
    FROM customer_country_revenue
)

SELECT
    customer_id,
    country,
    customer_revenue,
    total_orders,
    country_revenue_rank
FROM ranked_customers
WHERE country_revenue_rank <= 5
ORDER BY
    country,
    country_revenue_rank;

-- =============================================================================
-- 16. Customer behavior summary for reporting
-- =============================================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders,
        SUM(line_total) AS total_spent
    FROM vw_clean_transactions
    GROUP BY customer_id
)

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE total_orders = 1) AS one_time_customers,
    COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / COUNT(*),
        2
    ) AS repeat_purchase_rate_percentage,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer,
    ROUND(AVG(total_spent), 2) AS avg_customer_spend,
    ROUND(MAX(total_spent), 2) AS max_customer_spend
FROM customer_orders;

/*
===============================================================================
End of file: 04_customer_behavior_analysis.sql
===============================================================================
*/
