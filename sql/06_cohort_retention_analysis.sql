/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 06_cohort_retention_analysis.sql
Purpose: Analyze customer retention using cohort analysis
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script performs cohort retention analysis.

A cohort is defined as a group of customers who made their first purchase in the
same month.

The analysis tracks how many customers from each cohort return and make purchases
in the following months.

Main topics covered:

- first purchase month;
- monthly customer activity;
- cohort index;
- retained customers;
- retention rate;
- cohort revenue;
- cohort average order value;
- customer retention by lifecycle month.

===============================================================================
*/

-- =============================================================================
-- 1. Identify each customer's first purchase month
-- =============================================================================

WITH customer_first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase_date,
        DATE_TRUNC('month', MIN(invoice_date))::DATE AS cohort_month
    FROM vw_clean_transactions
    GROUP BY customer_id
)

SELECT
    customer_id,
    first_purchase_date,
    cohort_month
FROM customer_first_purchase
ORDER BY cohort_month, customer_id;

-- =============================================================================
-- 2. Monthly customer activity
-- =============================================================================

WITH monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoice_date)::DATE AS activity_month
    FROM vw_clean_transactions
)

SELECT
    customer_id,
    activity_month
FROM monthly_activity
ORDER BY customer_id, activity_month;

-- =============================================================================
-- 3. Cohort activity with month index
-- =============================================================================
-- cohort_index = number of months after the first purchase month.
-- Example:
-- cohort_index = 0 means first purchase month
-- cohort_index = 1 means one month after first purchase
-- cohort_index = 2 means two months after first purchase

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
)

SELECT
    customer_id,
    cohort_month,
    activity_month,
    cohort_index
FROM cohort_activity
ORDER BY cohort_month, customer_id, activity_month;

-- =============================================================================
-- 4. Cohort retention table: retained customers
-- =============================================================================

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
)

SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_id) AS retained_customers
FROM cohort_activity
GROUP BY
    cohort_month,
    cohort_index
ORDER BY
    cohort_month,
    cohort_index;

-- =============================================================================
-- 5. Cohort retention rate
-- =============================================================================

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
)

SELECT
    cc.cohort_month,
    cc.cohort_index,
    cs.cohort_size,
    cc.retained_customers,
    ROUND(
        100.0 * cc.retained_customers / NULLIF(cs.cohort_size, 0),
        2
    ) AS retention_rate_percentage
FROM cohort_counts cc
JOIN cohort_sizes cs
    ON cc.cohort_month = cs.cohort_month
ORDER BY
    cc.cohort_month,
    cc.cohort_index;

-- =============================================================================
-- 6. Retention matrix for first 6 months
-- =============================================================================

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
GROUP BY cohort_month
ORDER BY cohort_month;

-- =============================================================================
-- 7. Retention count matrix for first 6 months
-- =============================================================================

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
)

SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN cohort_index = 0 THEN customer_id END) AS month_0_customers,
    COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN customer_id END) AS month_1_customers,
    COUNT(DISTINCT CASE WHEN cohort_index = 2 THEN customer_id END) AS month_2_customers,
    COUNT(DISTINCT CASE WHEN cohort_index = 3 THEN customer_id END) AS month_3_customers,
    COUNT(DISTINCT CASE WHEN cohort_index = 4 THEN customer_id END) AS month_4_customers,
    COUNT(DISTINCT CASE WHEN cohort_index = 5 THEN customer_id END) AS month_5_customers,
    COUNT(DISTINCT CASE WHEN cohort_index = 6 THEN customer_id END) AS month_6_customers
FROM cohort_activity
GROUP BY cohort_month
ORDER BY cohort_month;

-- =============================================================================
-- 8. Average retention by cohort month index
-- =============================================================================

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
    cohort_index,
    ROUND(AVG(retention_rate_percentage), 2) AS average_retention_rate_percentage,
    COUNT(*) AS number_of_cohorts
FROM retention_rates
GROUP BY cohort_index
ORDER BY cohort_index;

-- =============================================================================
-- 9. Cohort revenue by month index
-- =============================================================================

WITH customer_first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date))::DATE AS cohort_month
    FROM vw_clean_transactions
    GROUP BY customer_id
),

customer_monthly_revenue AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', invoice_date)::DATE AS activity_month,
        ROUND(SUM(line_total), 2) AS monthly_revenue
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        DATE_TRUNC('month', invoice_date)::DATE
),

cohort_revenue AS (
    SELECT
        cfp.cohort_month,
        cmr.activity_month,
        (
            EXTRACT(YEAR FROM cmr.activity_month) * 12 + EXTRACT(MONTH FROM cmr.activity_month)
        ) -
        (
            EXTRACT(YEAR FROM cfp.cohort_month) * 12 + EXTRACT(MONTH FROM cfp.cohort_month)
        ) AS cohort_index,
        cmr.customer_id,
        cmr.monthly_revenue
    FROM customer_first_purchase cfp
    JOIN customer_monthly_revenue cmr
        ON cfp.customer_id = cmr.customer_id
)

SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(monthly_revenue), 2) AS cohort_revenue,
    ROUND(SUM(monthly_revenue) / COUNT(DISTINCT customer_id), 2) AS revenue_per_active_customer
FROM cohort_revenue
GROUP BY
    cohort_month,
    cohort_index
ORDER BY
    cohort_month,
    cohort_index;

-- =============================================================================
-- 10. Cohort revenue matrix for first 6 months
-- =============================================================================

WITH customer_first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date))::DATE AS cohort_month
    FROM vw_clean_transactions
    GROUP BY customer_id
),

customer_monthly_revenue AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', invoice_date)::DATE AS activity_month,
        ROUND(SUM(line_total), 2) AS monthly_revenue
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        DATE_TRUNC('month', invoice_date)::DATE
),

cohort_revenue AS (
    SELECT
        cfp.cohort_month,
        (
            EXTRACT(YEAR FROM cmr.activity_month) * 12 + EXTRACT(MONTH FROM cmr.activity_month)
        ) -
        (
            EXTRACT(YEAR FROM cfp.cohort_month) * 12 + EXTRACT(MONTH FROM cfp.cohort_month)
        ) AS cohort_index,
        cmr.monthly_revenue
    FROM customer_first_purchase cfp
    JOIN customer_monthly_revenue cmr
        ON cfp.customer_id = cmr.customer_id
)

SELECT
    cohort_month,
    ROUND(SUM(CASE WHEN cohort_index = 0 THEN monthly_revenue ELSE 0 END), 2) AS month_0_revenue,
    ROUND(SUM(CASE WHEN cohort_index = 1 THEN monthly_revenue ELSE 0 END), 2) AS month_1_revenue,
    ROUND(SUM(CASE WHEN cohort_index = 2 THEN monthly_revenue ELSE 0 END), 2) AS month_2_revenue,
    ROUND(SUM(CASE WHEN cohort_index = 3 THEN monthly_revenue ELSE 0 END), 2) AS month_3_revenue,
    ROUND(SUM(CASE WHEN cohort_index = 4 THEN monthly_revenue ELSE 0 END), 2) AS month_4_revenue,
    ROUND(SUM(CASE WHEN cohort_index = 5 THEN monthly_revenue ELSE 0 END), 2) AS month_5_revenue,
    ROUND(SUM(CASE WHEN cohort_index = 6 THEN monthly_revenue ELSE 0 END), 2) AS month_6_revenue
FROM cohort_revenue
GROUP BY cohort_month
ORDER BY cohort_month;

-- =============================================================================
-- 11. Cohort size and first-month revenue
-- =============================================================================

WITH customer_first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date))::DATE AS cohort_month
    FROM vw_clean_transactions
    GROUP BY customer_id
),

first_month_revenue AS (
    SELECT
        cfp.cohort_month,
        t.customer_id,
        SUM(t.line_total) AS revenue_in_first_month
    FROM customer_first_purchase cfp
    JOIN vw_clean_transactions t
        ON cfp.customer_id = t.customer_id
       AND DATE_TRUNC('month', t.invoice_date)::DATE = cfp.cohort_month
    GROUP BY
        cfp.cohort_month,
        t.customer_id
)

SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    ROUND(SUM(revenue_in_first_month), 2) AS first_month_revenue,
    ROUND(AVG(revenue_in_first_month), 2) AS avg_first_month_revenue_per_customer
FROM first_month_revenue
GROUP BY cohort_month
ORDER BY cohort_month;

-- =============================================================================
-- 12. Cohort retention summary for reporting
-- =============================================================================

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
        cs.cohort_size,
        cc.retained_customers,
        ROUND(
            100.0 * cc.retained_customers / NULLIF(cs.cohort_size, 0),
            2
        ) AS retention_rate_percentage
    FROM cohort_counts cc
    JOIN cohort_sizes cs
        ON cc.cohort_month = cs.cohort_month
)

SELECT
    cohort_index,
    ROUND(AVG(retention_rate_percentage), 2) AS avg_retention_rate_percentage,
    ROUND(MIN(retention_rate_percentage), 2) AS min_retention_rate_percentage,
    ROUND(MAX(retention_rate_percentage), 2) AS max_retention_rate_percentage,
    SUM(retained_customers) AS total_retained_customer_instances
FROM retention_rates
WHERE cohort_index BETWEEN 0 AND 6
GROUP BY cohort_index
ORDER BY cohort_index;

/*
===============================================================================
End of file: 06_cohort_retention_analysis.sql
===============================================================================
*/
