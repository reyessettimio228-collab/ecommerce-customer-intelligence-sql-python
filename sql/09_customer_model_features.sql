/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 09_customer_model_features.sql
Purpose: Create customer-level features for repurchase prediction modeling
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script creates a machine learning feature table at customer level.

The goal is to prepare a dataset that can later be exported to Python and used
to train a classification model.

Prediction task:

    Predict whether a customer is likely to purchase again within 90 days.

Target variable:

    repurchased_90_days

Definition:

    1 = customer made another purchase within 90 days after the feature snapshot date
    0 = customer did not make another purchase within 90 days after the feature snapshot date

Important note:

This project uses a simplified feature engineering approach suitable for a
portfolio project. The feature snapshot date is defined as the customer's
second-to-last purchase date when possible. The next purchase date is then used
to build the target variable.

For customers with only one order, the first order date is used as the snapshot
date and the target is set to 0 if no future order exists.

===============================================================================
*/

-- =============================================================================
-- 1. Customer order history
-- =============================================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        invoice_no AS order_id,
        MIN(invoice_date) AS order_date,
        ROUND(SUM(line_total), 2) AS order_revenue,
        SUM(quantity) AS order_items
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        invoice_no
)

SELECT
    *
FROM customer_orders
ORDER BY
    customer_id,
    order_date;

-- =============================================================================
-- 2. Ordered customer purchases with next order date
-- =============================================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        invoice_no AS order_id,
        MIN(invoice_date) AS order_date,
        ROUND(SUM(line_total), 2) AS order_revenue,
        SUM(quantity) AS order_items
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        invoice_no
),

ordered_customer_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        order_revenue,
        order_items,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS order_sequence,
        COUNT(*) OVER (
            PARTITION BY customer_id
        ) AS total_customer_orders,
        LEAD(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS next_order_date
    FROM customer_orders
)

SELECT
    *
FROM ordered_customer_orders
ORDER BY
    customer_id,
    order_sequence;

-- =============================================================================
-- 3. Snapshot table for modeling
-- =============================================================================
-- For customers with multiple purchases, the snapshot is the second-to-last
-- purchase.
--
-- For customers with only one purchase, the snapshot is their only purchase.

WITH customer_orders AS (
    SELECT
        customer_id,
        invoice_no AS order_id,
        MIN(invoice_date) AS order_date,
        ROUND(SUM(line_total), 2) AS order_revenue,
        SUM(quantity) AS order_items
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        invoice_no
),

ordered_customer_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        order_revenue,
        order_items,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS order_sequence,
        COUNT(*) OVER (
            PARTITION BY customer_id
        ) AS total_customer_orders,
        LEAD(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS next_order_date
    FROM customer_orders
),

customer_snapshots AS (
    SELECT
        *
    FROM ordered_customer_orders
    WHERE
        (
            total_customer_orders = 1
            AND order_sequence = 1
        )
        OR
        (
            total_customer_orders > 1
            AND order_sequence = total_customer_orders - 1
        )
)

SELECT
    *
FROM customer_snapshots
ORDER BY customer_id;

-- =============================================================================
-- 4. Create reusable model feature view
-- =============================================================================

DROP VIEW IF EXISTS vw_customer_model_features;

CREATE VIEW vw_customer_model_features AS
WITH customer_orders AS (
    SELECT
        customer_id,
        invoice_no AS order_id,
        MIN(invoice_date) AS order_date,
        ROUND(SUM(line_total), 2) AS order_revenue,
        SUM(quantity) AS order_items
    FROM vw_clean_transactions
    GROUP BY
        customer_id,
        invoice_no
),

ordered_customer_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        order_revenue,
        order_items,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS order_sequence,
        COUNT(*) OVER (
            PARTITION BY customer_id
        ) AS total_customer_orders,
        LEAD(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS next_order_date
    FROM customer_orders
),

customer_snapshots AS (
    SELECT
        *
    FROM ordered_customer_orders
    WHERE
        (
            total_customer_orders = 1
            AND order_sequence = 1
        )
        OR
        (
            total_customer_orders > 1
            AND order_sequence = total_customer_orders - 1
        )
),

features_before_snapshot AS (
    SELECT
        cs.customer_id,
        cs.order_date AS snapshot_date,
        cs.next_order_date,

        COUNT(DISTINCT co.order_id) AS total_orders_before_snapshot,
        ROUND(SUM(co.order_revenue), 2) AS total_spent_before_snapshot,
        ROUND(AVG(co.order_revenue), 2) AS avg_order_value_before_snapshot,
        SUM(co.order_items) AS total_items_before_snapshot,

        MIN(co.order_date) AS first_order_date,
        MAX(co.order_date) AS last_order_date_before_snapshot,

        DATE_PART('day', cs.order_date - MIN(co.order_date)) AS customer_age_days,
        DATE_PART('day', cs.order_date - MAX(co.order_date)) AS recency_days,

        CASE
            WHEN COUNT(DISTINCT co.order_id) > 1
                THEN ROUND(
                    DATE_PART('day', MAX(co.order_date) - MIN(co.order_date))
                    / NULLIF(COUNT(DISTINCT co.order_id) - 1, 0),
                    2
                )
            ELSE NULL
        END AS avg_days_between_orders

    FROM customer_snapshots cs
    JOIN customer_orders co
        ON cs.customer_id = co.customer_id
       AND co.order_date <= cs.order_date
    GROUP BY
        cs.customer_id,
        cs.order_date,
        cs.next_order_date
),

product_features AS (
    SELECT
        cs.customer_id,
        COUNT(DISTINCT t.stock_code) AS unique_products_purchased,
        COUNT(DISTINCT t.description) AS unique_product_descriptions,
        COUNT(DISTINCT t.country) AS countries_observed
    FROM customer_snapshots cs
    JOIN vw_clean_transactions t
        ON cs.customer_id = t.customer_id
       AND t.invoice_date <= cs.order_date
    GROUP BY cs.customer_id
),

country_features AS (
    SELECT
        cs.customer_id,
        MAX(t.country) AS customer_country
    FROM customer_snapshots cs
    JOIN vw_clean_transactions t
        ON cs.customer_id = t.customer_id
       AND t.invoice_date <= cs.order_date
    GROUP BY cs.customer_id
),

rfm_features AS (
    SELECT
        customer_id,
        recency_score,
        frequency_score,
        monetary_score,
        customer_segment
    FROM vw_rfm_segments
),

clv_features AS (
    SELECT
        customer_id,
        historical_clv,
        estimated_annualized_clv,
        customer_value_tier
    FROM vw_customer_lifetime_value
)

SELECT
    f.customer_id,
    cf.customer_country,

    f.snapshot_date,
    f.next_order_date,

    f.total_orders_before_snapshot,
    f.total_spent_before_snapshot,
    f.avg_order_value_before_snapshot,
    f.total_items_before_snapshot,
    f.customer_age_days,
    f.recency_days,
    f.avg_days_between_orders,

    pf.unique_products_purchased,
    pf.unique_product_descriptions,
    pf.countries_observed,

    r.recency_score,
    r.frequency_score,
    r.monetary_score,
    r.customer_segment,

    c.historical_clv,
    c.estimated_annualized_clv,
    c.customer_value_tier,

    CASE
        WHEN f.next_order_date IS NOT NULL
         AND DATE_PART('day', f.next_order_date - f.snapshot_date) <= 90
            THEN 1
        ELSE 0
    END AS repurchased_90_days,

    CASE
        WHEN f.next_order_date IS NOT NULL
            THEN DATE_PART('day', f.next_order_date - f.snapshot_date)
        ELSE NULL
    END AS days_until_next_purchase

FROM features_before_snapshot f
LEFT JOIN product_features pf
    ON f.customer_id = pf.customer_id
LEFT JOIN country_features cf
    ON f.customer_id = cf.customer_id
LEFT JOIN rfm_features r
    ON f.customer_id = r.customer_id
LEFT JOIN clv_features c
    ON f.customer_id = c.customer_id;

-- =============================================================================
-- 5. Preview model feature dataset
-- =============================================================================

SELECT
    *
FROM vw_customer_model_features
LIMIT 100;

-- =============================================================================
-- 6. Target distribution
-- =============================================================================

SELECT
    repurchased_90_days,
    COUNT(*) AS number_of_customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM vw_customer_model_features
GROUP BY repurchased_90_days
ORDER BY repurchased_90_days DESC;

-- =============================================================================
-- 7. Feature summary by target
-- =============================================================================

SELECT
    repurchased_90_days,
    COUNT(*) AS customers,
    ROUND(AVG(total_orders_before_snapshot), 2) AS avg_orders,
    ROUND(AVG(total_spent_before_snapshot), 2) AS avg_total_spent,
    ROUND(AVG(avg_order_value_before_snapshot), 2) AS avg_order_value,
    ROUND(AVG(total_items_before_snapshot), 2) AS avg_items,
    ROUND(AVG(customer_age_days), 2) AS avg_customer_age_days,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(unique_products_purchased), 2) AS avg_unique_products,
    ROUND(AVG(historical_clv), 2) AS avg_historical_clv
FROM vw_customer_model_features
GROUP BY repurchased_90_days
ORDER BY repurchased_90_days DESC;

-- =============================================================================
-- 8. Segment distribution by target
-- =============================================================================

SELECT
    customer_segment,
    repurchased_90_days,
    COUNT(*) AS customers
FROM vw_customer_model_features
GROUP BY
    customer_segment,
    repurchased_90_days
ORDER BY
    customer_segment,
    repurchased_90_days DESC;

-- =============================================================================
-- 9. Export query for Python modeling
-- =============================================================================
-- This SELECT statement can be used to export the modeling dataset to CSV and
-- load it into Python.

SELECT
    customer_id,
    customer_country,
    total_orders_before_snapshot,
    total_spent_before_snapshot,
    avg_order_value_before_snapshot,
    total_items_before_snapshot,
    customer_age_days,
    recency_days,
    avg_days_between_orders,
    unique_products_purchased,
    unique_product_descriptions,
    countries_observed,
    recency_score,
    frequency_score,
    monetary_score,
    customer_segment,
    historical_clv,
    estimated_annualized_clv,
    customer_value_tier,
    repurchased_90_days
FROM vw_customer_model_features;

/*
===============================================================================
End of file: 09_customer_model_features.sql
===============================================================================
*/
