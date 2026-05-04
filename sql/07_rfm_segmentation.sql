/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 07_rfm_segmentation.sql
Purpose: Segment customers using RFM analysis
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

RFM analysis is a customer segmentation technique based on three dimensions:

- Recency: how recently a customer purchased
- Frequency: how often a customer purchased
- Monetary: how much money a customer spent

This script creates RFM scores and business-friendly customer segments.

Main topics covered:

- customer-level RFM metrics;
- RFM scoring using NTILE;
- customer segment assignment;
- segment-level revenue;
- segment-level customer count;
- segment-level behavior;
- high-value and at-risk customers.

===============================================================================
*/

-- =============================================================================
-- 1. Customer-level RFM base table
-- =============================================================================

WITH analysis_date AS (
    SELECT
        MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
    FROM vw_clean_transactions
),

customer_rfm AS (
    SELECT
        t.customer_id,
        MAX(t.invoice_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.line_total), 2) AS monetary_value
    FROM vw_clean_transactions t
    GROUP BY t.customer_id
)

SELECT
    cr.customer_id,
    cr.last_purchase_date,
    DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
    cr.frequency,
    cr.monetary_value
FROM customer_rfm cr
CROSS JOIN analysis_date ad
ORDER BY monetary_value DESC;

-- =============================================================================
-- 2. RFM scores
-- =============================================================================
-- Scoring logic:
-- - Recency: lower recency_days is better, so recent customers receive higher scores.
-- - Frequency: higher frequency is better.
-- - Monetary: higher monetary value is better.

WITH analysis_date AS (
    SELECT
        MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
    FROM vw_clean_transactions
),

customer_rfm AS (
    SELECT
        t.customer_id,
        MAX(t.invoice_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.line_total), 2) AS monetary_value
    FROM vw_clean_transactions t
    GROUP BY t.customer_id
),

rfm_scores AS (
    SELECT
        cr.customer_id,
        DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
        cr.frequency,
        cr.monetary_value,

        NTILE(5) OVER (
            ORDER BY DATE_PART('day', ad.reference_date - cr.last_purchase_date) DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY cr.frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY cr.monetary_value ASC
        ) AS monetary_score

    FROM customer_rfm cr
    CROSS JOIN analysis_date ad
)

SELECT
    customer_id,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score
FROM rfm_scores
ORDER BY monetary_value DESC;

-- =============================================================================
-- 3. RFM customer segmentation
-- =============================================================================

WITH analysis_date AS (
    SELECT
        MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
    FROM vw_clean_transactions
),

customer_rfm AS (
    SELECT
        t.customer_id,
        MAX(t.invoice_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.line_total), 2) AS monetary_value
    FROM vw_clean_transactions t
    GROUP BY t.customer_id
),

rfm_scores AS (
    SELECT
        cr.customer_id,
        DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
        cr.frequency,
        cr.monetary_value,

        NTILE(5) OVER (
            ORDER BY DATE_PART('day', ad.reference_date - cr.last_purchase_date) DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY cr.frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY cr.monetary_value ASC
        ) AS monetary_score

    FROM customer_rfm cr
    CROSS JOIN analysis_date ad
),

rfm_segments AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        recency_score,
        frequency_score,
        monetary_score,
        CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score,

        CASE
            WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
                THEN 'Champions'

            WHEN recency_score >= 3
             AND frequency_score >= 4
                THEN 'Loyal Customers'

            WHEN recency_score >= 4
             AND frequency_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'

            WHEN recency_score = 5
             AND frequency_score = 1
                THEN 'New Customers'

            WHEN recency_score BETWEEN 2 AND 3
             AND frequency_score >= 3
             AND monetary_score >= 3
                THEN 'Need Attention'

            WHEN recency_score <= 2
             AND frequency_score >= 3
                THEN 'At Risk'

            WHEN recency_score = 1
             AND frequency_score <= 2
                THEN 'Lost Customers'

            WHEN monetary_score >= 4
                THEN 'Big Spenders'

            ELSE 'Others'
        END AS customer_segment
    FROM rfm_scores
)

SELECT
    *
FROM rfm_segments
ORDER BY
    CASE
        WHEN customer_segment = 'Champions' THEN 1
        WHEN customer_segment = 'Loyal Customers' THEN 2
        WHEN customer_segment = 'Potential Loyalists' THEN 3
        WHEN customer_segment = 'New Customers' THEN 4
        WHEN customer_segment = 'Need Attention' THEN 5
        WHEN customer_segment = 'At Risk' THEN 6
        WHEN customer_segment = 'Lost Customers' THEN 7
        WHEN customer_segment = 'Big Spenders' THEN 8
        ELSE 9
    END,
    monetary_value DESC;

-- =============================================================================
-- 4. Segment summary
-- =============================================================================

WITH analysis_date AS (
    SELECT
        MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
    FROM vw_clean_transactions
),

customer_rfm AS (
    SELECT
        t.customer_id,
        MAX(t.invoice_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.line_total), 2) AS monetary_value
    FROM vw_clean_transactions t
    GROUP BY t.customer_id
),

rfm_scores AS (
    SELECT
        cr.customer_id,
        DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
        cr.frequency,
        cr.monetary_value,

        NTILE(5) OVER (
            ORDER BY DATE_PART('day', ad.reference_date - cr.last_purchase_date) DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY cr.frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY cr.monetary_value ASC
        ) AS monetary_score

    FROM customer_rfm cr
    CROSS JOIN analysis_date ad
),

rfm_segments AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        recency_score,
        frequency_score,
        monetary_score,
        CASE
            WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
                THEN 'Champions'
            WHEN recency_score >= 3
             AND frequency_score >= 4
                THEN 'Loyal Customers'
            WHEN recency_score >= 4
             AND frequency_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'
            WHEN recency_score = 5
             AND frequency_score = 1
                THEN 'New Customers'
            WHEN recency_score BETWEEN 2 AND 3
             AND frequency_score >= 3
             AND monetary_score >= 3
                THEN 'Need Attention'
            WHEN recency_score <= 2
             AND frequency_score >= 3
                THEN 'At Risk'
            WHEN recency_score = 1
             AND frequency_score <= 2
                THEN 'Lost Customers'
            WHEN monetary_score >= 4
                THEN 'Big Spenders'
            ELSE 'Others'
        END AS customer_segment
    FROM rfm_scores
),

total_customers AS (
    SELECT
        COUNT(*) AS total_customer_count,
        SUM(monetary_value) AS total_revenue
    FROM rfm_segments
)

SELECT
    rs.customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(100.0 * COUNT(*) / tc.total_customer_count, 2) AS customer_share_percentage,
    ROUND(SUM(rs.monetary_value), 2) AS segment_revenue,
    ROUND(100.0 * SUM(rs.monetary_value) / tc.total_revenue, 2) AS revenue_share_percentage,
    ROUND(AVG(rs.recency_days), 2) AS avg_recency_days,
    ROUND(AVG(rs.frequency), 2) AS avg_frequency,
    ROUND(AVG(rs.monetary_value), 2) AS avg_monetary_value
FROM rfm_segments rs
CROSS JOIN total_customers tc
GROUP BY
    rs.customer_segment,
    tc.total_customer_count,
    tc.total_revenue
ORDER BY segment_revenue DESC;

-- =============================================================================
-- 5. Top customers in each RFM segment
-- =============================================================================

WITH analysis_date AS (
    SELECT
        MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
    FROM vw_clean_transactions
),

customer_rfm AS (
    SELECT
        t.customer_id,
        MAX(t.invoice_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.line_total), 2) AS monetary_value
    FROM vw_clean_transactions t
    GROUP BY t.customer_id
),

rfm_scores AS (
    SELECT
        cr.customer_id,
        DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
        cr.frequency,
        cr.monetary_value,

        NTILE(5) OVER (
            ORDER BY DATE_PART('day', ad.reference_date - cr.last_purchase_date) DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY cr.frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY cr.monetary_value ASC
        ) AS monetary_score

    FROM customer_rfm cr
    CROSS JOIN analysis_date ad
),

rfm_segments AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        recency_score,
        frequency_score,
        monetary_score,
        CASE
            WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
                THEN 'Champions'
            WHEN recency_score >= 3
             AND frequency_score >= 4
                THEN 'Loyal Customers'
            WHEN recency_score >= 4
             AND frequency_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'
            WHEN recency_score = 5
             AND frequency_score = 1
                THEN 'New Customers'
            WHEN recency_score BETWEEN 2 AND 3
             AND frequency_score >= 3
             AND monetary_score >= 3
                THEN 'Need Attention'
            WHEN recency_score <= 2
             AND frequency_score >= 3
                THEN 'At Risk'
            WHEN recency_score = 1
             AND frequency_score <= 2
                THEN 'Lost Customers'
            WHEN monetary_score >= 4
                THEN 'Big Spenders'
            ELSE 'Others'
        END AS customer_segment
    FROM rfm_scores
),

ranked_segment_customers AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY customer_segment
            ORDER BY monetary_value DESC
        ) AS segment_customer_rank
    FROM rfm_segments
)

SELECT
    customer_segment,
    segment_customer_rank,
    customer_id,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score
FROM ranked_segment_customers
WHERE segment_customer_rank <= 10
ORDER BY
    customer_segment,
    segment_customer_rank;

-- =============================================================================
-- 6. At-risk high-value customers
-- =============================================================================

WITH analysis_date AS (
    SELECT
        MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
    FROM vw_clean_transactions
),

customer_rfm AS (
    SELECT
        t.customer_id,
        MAX(t.invoice_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.line_total), 2) AS monetary_value
    FROM vw_clean_transactions t
    GROUP BY t.customer_id
),

rfm_scores AS (
    SELECT
        cr.customer_id,
        DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
        cr.frequency,
        cr.monetary_value,

        NTILE(5) OVER (
            ORDER BY DATE_PART('day', ad.reference_date - cr.last_purchase_date) DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY cr.frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY cr.monetary_value ASC
        ) AS monetary_score

    FROM customer_rfm cr
    CROSS JOIN analysis_date ad
),

rfm_segments AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        recency_score,
        frequency_score,
        monetary_score,
        CASE
            WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
                THEN 'Champions'
            WHEN recency_score >= 3
             AND frequency_score >= 4
                THEN 'Loyal Customers'
            WHEN recency_score >= 4
             AND frequency_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'
            WHEN recency_score = 5
             AND frequency_score = 1
                THEN 'New Customers'
            WHEN recency_score BETWEEN 2 AND 3
             AND frequency_score >= 3
             AND monetary_score >= 3
                THEN 'Need Attention'
            WHEN recency_score <= 2
             AND frequency_score >= 3
                THEN 'At Risk'
            WHEN recency_score = 1
             AND frequency_score <= 2
                THEN 'Lost Customers'
            WHEN monetary_score >= 4
                THEN 'Big Spenders'
            ELSE 'Others'
        END AS customer_segment
    FROM rfm_scores
)

SELECT
    customer_id,
    customer_segment,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score
FROM rfm_segments
WHERE customer_segment IN ('At Risk', 'Need Attention')
  AND monetary_score >= 4
ORDER BY monetary_value DESC;

-- =============================================================================
-- 7. Recommended business actions by segment
-- =============================================================================

WITH segment_actions AS (
    SELECT
        'Champions' AS customer_segment,
        'Reward with VIP offers, early access, and loyalty benefits.' AS recommended_action
    UNION ALL
    SELECT
        'Loyal Customers',
        'Encourage referrals, cross-selling, and premium bundles.'
    UNION ALL
    SELECT
        'Potential Loyalists',
        'Offer personalized recommendations and limited-time incentives.'
    UNION ALL
    SELECT
        'New Customers',
        'Create onboarding campaigns and second-purchase discounts.'
    UNION ALL
    SELECT
        'Need Attention',
        'Re-engage with personalized emails and relevant product offers.'
    UNION ALL
    SELECT
        'At Risk',
        'Use win-back campaigns, targeted discounts, and customer feedback surveys.'
    UNION ALL
    SELECT
        'Lost Customers',
        'Use low-cost reactivation campaigns or exclude from expensive campaigns.'
    UNION ALL
    SELECT
        'Big Spenders',
        'Protect value with premium service, bundles, and account-level targeting.'
    UNION ALL
    SELECT
        'Others',
        'Monitor behavior and test broad marketing campaigns.'
),

rfm_segments AS (
    WITH analysis_date AS (
        SELECT
            MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
        FROM vw_clean_transactions
    ),

    customer_rfm AS (
        SELECT
            t.customer_id,
            MAX(t.invoice_date)::DATE AS last_purchase_date,
            COUNT(DISTINCT t.invoice_no) AS frequency,
            ROUND(SUM(t.line_total), 2) AS monetary_value
        FROM vw_clean_transactions t
        GROUP BY t.customer_id
    ),

    rfm_scores AS (
        SELECT
            cr.customer_id,
            DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
            cr.frequency,
            cr.monetary_value,

            NTILE(5) OVER (
                ORDER BY DATE_PART('day', ad.reference_date - cr.last_purchase_date) DESC
            ) AS recency_score,

            NTILE(5) OVER (
                ORDER BY cr.frequency ASC
            ) AS frequency_score,

            NTILE(5) OVER (
                ORDER BY cr.monetary_value ASC
            ) AS monetary_score

        FROM customer_rfm cr
        CROSS JOIN analysis_date ad
    )

    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        CASE
            WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
                THEN 'Champions'
            WHEN recency_score >= 3
             AND frequency_score >= 4
                THEN 'Loyal Customers'
            WHEN recency_score >= 4
             AND frequency_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'
            WHEN recency_score = 5
             AND frequency_score = 1
                THEN 'New Customers'
            WHEN recency_score BETWEEN 2 AND 3
             AND frequency_score >= 3
             AND monetary_score >= 3
                THEN 'Need Attention'
            WHEN recency_score <= 2
             AND frequency_score >= 3
                THEN 'At Risk'
            WHEN recency_score = 1
             AND frequency_score <= 2
                THEN 'Lost Customers'
            WHEN monetary_score >= 4
                THEN 'Big Spenders'
            ELSE 'Others'
        END AS customer_segment
    FROM rfm_scores
)

SELECT
    rs.customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(rs.monetary_value), 2) AS segment_revenue,
    sa.recommended_action
FROM rfm_segments rs
JOIN segment_actions sa
    ON rs.customer_segment = sa.customer_segment
GROUP BY
    rs.customer_segment,
    sa.recommended_action
ORDER BY segment_revenue DESC;

-- =============================================================================
-- 8. Create reusable RFM view
-- =============================================================================
-- This view can be used later for dashboarding, reporting, and machine learning
-- feature engineering.

DROP VIEW IF EXISTS vw_rfm_segments;

CREATE VIEW vw_rfm_segments AS
WITH analysis_date AS (
    SELECT
        MAX(invoice_date)::DATE + INTERVAL '1 day' AS reference_date
    FROM vw_clean_transactions
),

customer_rfm AS (
    SELECT
        t.customer_id,
        MAX(t.invoice_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.line_total), 2) AS monetary_value
    FROM vw_clean_transactions t
    GROUP BY t.customer_id
),

rfm_scores AS (
    SELECT
        cr.customer_id,
        cr.last_purchase_date,
        DATE_PART('day', ad.reference_date - cr.last_purchase_date) AS recency_days,
        cr.frequency,
        cr.monetary_value,

        NTILE(5) OVER (
            ORDER BY DATE_PART('day', ad.reference_date - cr.last_purchase_date) DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY cr.frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY cr.monetary_value ASC
        ) AS monetary_score

    FROM customer_rfm cr
    CROSS JOIN analysis_date ad
)

SELECT
    customer_id,
    last_purchase_date,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score,
    CASE
        WHEN recency_score >= 4
         AND frequency_score >= 4
         AND monetary_score >= 4
            THEN 'Champions'
        WHEN recency_score >= 3
         AND frequency_score >= 4
            THEN 'Loyal Customers'
        WHEN recency_score >= 4
         AND frequency_score BETWEEN 2 AND 3
            THEN 'Potential Loyalists'
        WHEN recency_score = 5
         AND frequency_score = 1
            THEN 'New Customers'
        WHEN recency_score BETWEEN 2 AND 3
         AND frequency_score >= 3
         AND monetary_score >= 3
            THEN 'Need Attention'
        WHEN recency_score <= 2
         AND frequency_score >= 3
            THEN 'At Risk'
        WHEN recency_score = 1
         AND frequency_score <= 2
            THEN 'Lost Customers'
        WHEN monetary_score >= 4
            THEN 'Big Spenders'
        ELSE 'Others'
    END AS customer_segment
FROM rfm_scores;

/*
===============================================================================
End of file: 07_rfm_segmentation.sql
===============================================================================
*/
